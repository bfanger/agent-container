#!/usr/bin/env pwsh

param(
    [Parameter(Mandatory=$false, Position=0)]
    [string]$project,
    [Parameter(Mandatory=$false)]
    [switch]$dry
)

$projectsPath = "C:\Users\bfang\Projects"
$llamaServerPath = $projectsPath + "\llama\llama-server.exe"
$pnpm = $false

$process = Get-Process -Name "llama-server" -ErrorAction SilentlyContinue

if (!$process) {
    $args = @(
        "-m", "D:\ai-models\unsloth\Qwen3.6-27B-GGUF\Qwen3.6-27B-UD-IQ3_XXS.gguf",
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
        "-c", "50000"
    )
    Start-Process $llamaServerPath -ArgumentList $args -NoNewWindow -RedirectStandardError "NUL"
}


function WaitForDocker {
    docker info *> $null
    if ($LASTEXITCODE -ne 0) {
        return $true
    }
    return $false
}

if (WaitForDocker -eq $true) {
    Write-Host "Starting Docker..."
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    while (WaitForDocker -eq $true) {
        Start-Sleep -Seconds 1
    }
}

function Get-MountPaths {
    param([string]$subpath)
    $mountPaths = @()
    if (Test-Path "$subpath\package.json") {
        $mountPaths += "node_modules"
        if (Test-Path "$subpath\pnpm-lock.yaml") {
            $script:pnpm = $true
        }
    }
    $blacklist = @('node_modules', 'out', 'dist', 'build')
    $subDirs = Get-ChildItem -Path $subpath -Directory -Recurse -Force -ErrorAction SilentlyContinue
    foreach ($dir in $subDirs) {
        $parts = $dir.FullName.Replace($subpath, '').Split('\')
        $skip = $false
        foreach ($part in $parts) {
            if ($part -in $blacklist -or $part.StartsWith('.') -or $part.StartsWith('_')) {
                $skip = $true
                break
            }
        }
        if ($skip) { continue }
        if (Test-Path "$($dir.FullName)\package.json") {
            if (Test-Path "$($dir.FullName)\pnpm-lock.yaml") {
                $script:pnpm = $true
            }
            $relativePath = $dir.FullName.Replace($subpath, '').TrimStart('\').Replace('\', '/')
            $mountPaths += "$relativePath/node_modules"
        }
    }
    return $mountPaths
}

if ($project) {
    $projectPath = $projectsPath + "\" + $project 
} else {
    $project = Split-Path -Leaf $PWD
    $projectPath = $PWD
}

$volume = $project -replace "[-.]", "_"
$mountPaths = Get-MountPaths -subpath $projectPath
if ($pnpm) {
    $mountPaths += ".pnpm-store"
}

$prepareArgs = @(
    "run",
    "--rm",
    "--mount",
    "src=${volume},destination=/mnt",
    "--workdir", "/mnt"
    "alpine",
    "sh", "-c", "mkdir -p $($mountPaths -join ' ') && chown 1000:1000 $($mountPaths -join ' ')"
)

$runArgs = @(
    "run",
    "--rm", 
    "-it",
    "--volume", "$projectPath\:/app/$project",
    "--workdir", "/app/$project",
    "--env", "ANTHROPIC_API_KEY=sk-not-a-real-key"
)
foreach ($path in $mountPaths) {
    $runArgs += "--mount"
    $runArgs += "type=volume,src=$volume,volume-subpath=$path,destination=/app/$project/$path"
}
$runArgs += "agent"
$runArgs += "tmux"

if ($dry) {
    $runArgs | Write-Host
} else {
    if ($mountPaths.Count -gt 0) {
        docker @prepareArgs
    }
    docker @runArgs
}