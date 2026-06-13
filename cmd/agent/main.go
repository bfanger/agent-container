package main

import (
	"flag"
	"fmt"
	"io/fs"
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
	model := flag.String("model", "", "Autostart llama-server using this model")
	llama := flag.String("llama", "llama-server", "path to llama-server.exe")
	flag.Parse()

	wg := sync.WaitGroup{}
	defer wg.Wait()

	if *model != "" && !isLlamaRunning() {
		fmt.Println("Starting llama-server...")
		wg.Go(func() { startLlamaServer(*llama, *model) })
	}

	if *dockerDesktop && !isDockerRunning() {
		fmt.Println("Starting Docker Desktop...")
		startDockerDesktop()
	}

	projectPath, err := os.Getwd()
	if err != nil {
		panic(err)
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
		fmt.Sprintf("--volume=%s:/app/%s", projectPath, projectSlug),
		"--workdir", fmt.Sprintf("/app/%s", projectSlug),
		"--env", "ANTHROPIC_API_KEY=sk-not-a-real-key",
		fmt.Sprintf("--label=traefik.http.routers.%s.rule=Host(`%s.localhost`)", subdomain, subdomain),
		fmt.Sprintf("--label=traefik.http.routers.%s.service=%s", subdomain, subdomain),
		fmt.Sprintf("--label=traefik.http.services.%s.loadbalancer.server.port=5173", subdomain),
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

	blacklist := map[string]bool{
		"node_modules": true,
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

func startLlamaServer(llama, model string) {
	args := []string{
		"-m", model,
		"--temp", "0.6",
		"--top-p", "0.95",
		"--top-k", "20",
		"--min-p", "0.0",
		"--presence-penalty", "0.0",
		"--repeat-penalty", "1.0",
		"--fit", "off",
		"--no-mmap",
		"--n-gpu-layers", "-1",
		"--parallel", "1",
		"--flash-attn", "on",
		"--cache-type-v", "q8_0",
		"--cache-type-k", "q8_0",
		"--cache-ram", "4096",
		"-c", "50000",
	}
	var cmd *exec.Cmd
	cmd = exec.Command(llama, args...)
	if err := cmd.Start(); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to start llama-server: %v\n", err)
		os.Exit(1)
	}
}

func isLlamaRunning() bool {
	if runtime.GOOS == "windows" {
		cmd := exec.Command("powershell", "-Command", "Get-Process -Name llama-server -ErrorAction Stop")
		return cmd.Run() == nil
	}
	cmd := exec.Command("pgrep", "-f", "llama-server")
	return cmd.Run() == nil
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
