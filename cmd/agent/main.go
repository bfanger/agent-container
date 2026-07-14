package main

import (
	"flag"
	"fmt"
	"io"
	"io/fs"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"runtime"
	"strings"
	"sync"
	"time"
)

func main() {
	dry := flag.Bool("dry", false, "print docker command without running")
	dockerDesktop := new(false)
	if runtime.GOOS == "windows" {
		dockerDesktop = flag.Bool("docker-desktop", false, "Autostart Docker Desktop")
	}
	orbstack := new(false)
	if runtime.GOOS == "darwin" {
		orbstack = flag.Bool("orbstack", false, "Autostart OrbStack")
	}
	config := flag.String("llama-swap", "", "Autostart llama-swap using this config")
	proxy := flag.String("proxy", "", "Autostart proxy on 8080 to [host]:[port]")
	flag.Parse()

	wg := sync.WaitGroup{}
	defer wg.Wait()

	if *proxy != "" && !isOpenApiV1Available() {
		fmt.Printf("Starting HTTP proxy :8080 to %s\n", *proxy)
		go proxyServer(*proxy)
	}

	if *config != "" && !isOpenApiV1Available() {
		fmt.Println("Starting llama-swap...")
		wg.Go(func() { startLlamaSwap(*config) })
	}

	if *dockerDesktop && !isDockerRunning() {
		fmt.Println("Starting Docker Desktop...")
		startDockerDesktop()
	}

	if *orbstack && !isDockerRunning() {
		fmt.Println("Starting OrbStack...")
		startOrbStack()
	}

	projectPath, err := os.Getwd()
	if err != nil {
		panic(err)
	}

	homeDir, err := os.UserHomeDir()
	if err == nil && projectPath == homeDir {
		fmt.Fprintln(os.Stderr, "Error: not inside a project")
		os.Exit(1)
	}

	projectSlug := filepath.Base(projectPath)

	mountPaths, usesPnpm := getMountPaths(projectPath)
	if usesPnpm {
		mountPaths = append(mountPaths, ".pnpm-store")
	}

	volume := regexp.MustCompile(`[-.]`).ReplaceAllString(projectSlug, "_")
	subdomain := regexp.MustCompile(`[.]`).ReplaceAllString(projectSlug, "-")

	if len(mountPaths) != 0 && !*dry {
		joinedPaths := strings.Join(mountPaths, " ")
		prepareArgs := []string{
			"run", "--rm",
			"--mount", fmt.Sprintf("src=%s,destination=/mnt", volume),
			"--workdir", "/mnt",
			"alpine", "sh", "-c",
			fmt.Sprintf("mkdir -p %s && chown 1000:1000 %s", joinedPaths, joinedPaths),
		}
		runDocker(prepareArgs...)
	}

	runArgs := []string{
		"run",
		"--rm",
		"-it",
		"-P",
		"--user", "1000:1000",
		fmt.Sprintf("--volume=%s:/app/%s", projectPath, projectSlug),
		"--workdir", fmt.Sprintf("/app/%s", projectSlug),
		"--env", "ANTHROPIC_API_KEY=sk-not-a-real-key",

		fmt.Sprintf("--label=traefik.http.routers.%s.rule=Host(`%s.localhost`)", subdomain, subdomain),
		fmt.Sprintf("--label=traefik.http.routers.%s.service=%s", subdomain, subdomain),
		fmt.Sprintf("--label=traefik.http.services.%s.loadbalancer.server.port=5173", subdomain),

		fmt.Sprintf("--label=traefik.http.routers.%s-next.rule=Host(`%s.localhost`)", subdomain, subdomain),
		fmt.Sprintf("--label=traefik.http.routers.%s-next.entrypoints=next", subdomain),
		fmt.Sprintf("--label=traefik.http.routers.%s-next.service=%s-next", subdomain, subdomain),
		fmt.Sprintf("--label=traefik.http.services.%s-next.loadbalancer.server.port=3000", subdomain),

		fmt.Sprintf("--label=traefik.http.routers.%s-laravel.rule=Host(`%s.localhost`)", subdomain, subdomain),
		fmt.Sprintf("--label=traefik.http.routers.%s-laravel.entrypoints=laravel", subdomain),
		fmt.Sprintf("--label=traefik.http.routers.%s-laravel.service=%s-laravel", subdomain, subdomain),
		fmt.Sprintf("--label=traefik.http.services.%s-laravel.loadbalancer.server.port=8000", subdomain),
	}

	for _, path := range mountPaths {
		runArgs = append(runArgs,
			"--mount",
			fmt.Sprintf("type=volume,src=%s,volume-subpath=%s,destination=/app/%s/%s", volume, path, projectSlug, path),
		)
	}

	runArgs = append(runArgs, "agent", "tmux")

	if *dry {
		fmt.Println("docker " + strings.Join(runArgs, "\n  "))
	} else {
		runDocker(runArgs...)
	}
}

func getMountPaths(subpath string) ([]string, bool) {
	var mountPaths []string
	usesPnpm := false

	if _, err := os.Stat(filepath.Join(subpath, "package.json")); err == nil {
		mountPaths = append(mountPaths, "node_modules")
		if _, err := os.Stat(filepath.Join(subpath, "pnpm-lock.yaml")); err == nil {
			usesPnpm = true
		}
	}

	if _, err := os.Stat(filepath.Join(subpath, "composer.json")); err == nil {
		mountPaths = append(mountPaths, "vendor")
	}

	if _, err := os.Stat(filepath.Join(subpath, "svelte.config.js")); err == nil {
		svelteConfig, err := os.ReadFile(filepath.Join(subpath, "svelte.config.js"))
		if err == nil && strings.Contains(string(svelteConfig), "kit:") {
			mountPaths = append(mountPaths, ".svelte-kit")
		}
	}

	blacklist := map[string]bool{
		"node_modules": true,
		"vendor":       true,
		"out":          true,
		"dist":         true,
		"build":        true,
	}

	filepath.WalkDir(subpath, func(path string, info fs.DirEntry, err error) error {
		if err != nil || !info.IsDir() {
			return nil
		}

		rel, err := filepath.Rel(subpath, path)
		if err != nil || rel == "." {
			return nil
		}

		name := info.Name()
		if blacklist[name] || strings.HasPrefix(name, ".") || strings.HasPrefix(name, "_") {
			return filepath.SkipDir
		}

		if _, err := os.Stat(filepath.Join(path, "package.json")); err == nil {
			if _, err := os.Stat(filepath.Join(path, "pnpm-lock.yaml")); err == nil {
				usesPnpm = true
			}
			relPath := strings.ReplaceAll(rel, string(filepath.Separator), "/")
			mountPaths = append(mountPaths, relPath+"/node_modules")
		}

		return nil
	})

	return mountPaths, usesPnpm
}

func runDocker(args ...string) {
	cmd := exec.Command("docker", args...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Start(); err != nil {
		fmt.Fprintf(os.Stderr, "Docker command failed: %v\n", err)
		os.Exit(cmd.ProcessState.ExitCode())
	}

	if err := cmd.Wait(); err != nil {
		fmt.Fprintf(os.Stderr, "Docker command failed: %v\n", err)
		os.Exit(cmd.ProcessState.ExitCode())
	}
}

// proxy server, but no error handling, as that would pollute the tty docker session.
func proxyServer(target string) {
	proxy, err := net.Listen("tcp", ":8080")
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to start proxy: %v\n", err)
		os.Exit(1)
	}
	for {
		conn, err := proxy.Accept()
		if err != nil {
			panic(err)
		}
		go func(client net.Conn) {
			defer client.Close()
			dialer := net.Dialer{Timeout: 10 * time.Second}
			server, err := dialer.Dial("tcp", target)
			if err != nil {
				return
			}
			defer server.Close()
			go func() {
				_, _ = io.Copy(server, client)
			}()
			_, _ = io.Copy(client, server)
		}(conn)
	}
}

func startLlamaSwap(config string) {
	cmd := exec.Command("llama-swap", "-watch-config", "-config", config)
	if err := cmd.Start(); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to start llama-swap: %v\n", err)
		os.Exit(1)
	}
}

func isOpenApiV1Available() bool {
	resp, err := http.Get("http://localhost:8080/v1/models")
	if err != nil {
		return false
	}
	resp.Body.Close()
	return resp.StatusCode == 200
}

func isDockerRunning() bool {
	cmd := exec.Command("docker", "info")
	return cmd.Run() == nil
}

func startDockerDesktop() {
	cmd := exec.Command("powershell", "-Command", "Start-Process 'C:\\Program Files\\Docker\\Docker\\Docker Desktop.exe'")
	if err := cmd.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to start Docker Desktop: %v\n", err)
		os.Exit(1)
	}

	for !isDockerRunning() {
		time.Sleep(1 * time.Second)
	}
}

func startOrbStack() {
	cmd := exec.Command("open", "/Applications/OrbStack.app")
	if err := cmd.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to start OrbStack: %v\n", err)
		os.Exit(1)
	}

	for !isDockerRunning() {
		time.Sleep(1 * time.Second)
	}
}
