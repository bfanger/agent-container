#!/usr/bin/env pwsh

param(
    [Parameter(Mandatory=$false, Position=0)]
    [string]$project
)

$llamaServerPath = "C:\Users\bfang\Projects\llama\llama-server.exe"
$agentContainerPath = "C:\Users\bfang\Projects\opencode"

$process = Get-Process -Name "llama-server" -ErrorAction SilentlyContinue

if (!$process) {
    $args = @(
        "-m", "D:\ai-models\unsloth\Qwen3.5-27B-GGUF\Qwen3.5-27B-UD-IQ3_XXS.gguf",
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
        "-c", "64000"
    )
    Start-Process $llamaServerPath -ArgumentList $args -NoNewWindow -RedirectStandardError "NUL"
}

Set-Location $agentContainerPath
docker compose up -d
if ($project) {
    
    $volumeName = $project + "_modules"
    $volumeName = $volumeName -replace "-", "_"
    $filename = "docker-compose.override.yml"
    if (-not (Test-Path -Path $filename)) {
        @"
volumes:
  $($volumeName):
services:
  dev:
    volumes:
     - $($volumeName):/user/projects/$($project)/node_modules
"@ | Set-Content -Path $filename
    } else {
    $content = Get-Content -Path $filename
    $exists = $content -match "^  $($volumeName):"
    
    if (-not $exists) {
        $content = $content -replace "^services:", @"
  $($volumeName):
services:
"@
        $content += "     - $($volumeName):/user/projects/$($project)/node_modules`n"
    }
    $content | Set-Content -Path $filename
    }
    docker compose up -d
    docker compose exec --user root dev "/user/docker-scripts/setup.sh" 
    docker compose exec --workdir "/user/projects/$project" dev tmux
} else {
    docker compose exec dev tmux
}

