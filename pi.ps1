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
if ($project) {
    docker compose exec --workdir "/home/user/projects/$project" dev tmux -2
} else {
    docker compose exec dev tmux -2
}

