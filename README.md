# Agentic Coding Docker Setup

## Installation

Install [LM Studio](https://lmstudio.ai/) & enable the dev server on 8080 or run [llama.cpp](https://github.com/ggml-org/llama.cpp)

```sh
docker build --tag agent --no-cache .
go install ./cmd/agent
```

## Running using Docker

```sh
docker run --rm -it agent tmux
# Inside the container start your agent: pi, claude or opencode
pi
```

## Running using the agent cli

It creates the docker container and relevant volumes for pnpm.

```sh
agent
```

Create an pi alias in your powershell $PROFILE, example:

```sh
function pi {
    & 'C:\Users\bfang\go\bin\agent.exe' --docker-desktop --model 'D:\ai-models\unsloth\Qwen3.6-27B-GGUF\Qwen3.6-27B-UD-IQ3_XXS.gguf' --llama 'C:\Users\bfang\Projects\llama\llama-server.exe' @args
}
```

This also starts docker & llama-server if they are not yet running.

## Running models with llama.cpp (on 16GB VRAM)

### Qwen3.6 27b

```pwsh
.\llama-server.exe -m D:\ai-models\unsloth\Qwen3.6-27B-GGUF\Qwen3.6-27B-UD-IQ3_XXS.gguf --temp 0.6 --top-p 0.95 --top-k 20 --min-p 0.0 --presence-penalty 0.0 --repeat-penalty 1.0 --fit off --no-mmap --n-gpu-layers -1 --parallel 1 --flash-attn on --cache-type-v q8_0 --cache-type-k q8_0 --cache-ram 4096 -c 50000
```

To enable vision add: `--mmproj D:\ai-models\unsloth\Qwen3.6-27B-GGUF\mmproj-F32.gguf` but also decrease the context to `-c 10000`

And update ~/.pi/agent/models.json to `"input": ["text", "image"],`

### Qwen3.6 32b A3B (fast)

```pwsh
 .\llama-server.exe -m D:\ai-models\unsloth\Qwen3.6-35B-A3B-GGUF\Qwen3.6-35B-A3B-UD-IQ3_XXS.gguf --temp 0.6 --top-p 0.95 --top-k 20 --min-p 0.0 --presence-penalty 0.0 --repeat-penalty 1.0 --fit off --no-mmap --n-gpu-layers -1 --parallel 1 --flash-attn on --cache-type-v q8_0 --cache-type-k q8_0 -c 50000
```

### GLM 4.7 Flash 30b A3B (fast)

```pwsh
.\llama-server.exe -m D:\ai-models\unsloth\GLM-4.7-Flash-GGUF\GLM-4.7-Flash-UD-IQ3_XXS.gguf --temp 0.6 --top-p 1.0 --min-p 0.01 --repeat-penalty 1.0 --no-mmap --n-gpu-layers -1 --parallel 1 --flash-attn on --cache-type-v q8_0 --cache-type-k q8_0 -c 50000
```

## For autocomplete in VSCode

Install the [Continue](https://marketplace.visualstudio.com/items?itemName=Continue.continue) VSCode extension.

And update ~/.continue/config.yaml

```yaml
name: Local Config
version: 1.0.0
schema: v1
models:
  - name: Qwen 2.5 Coder 1.5b
    provider: llama.cpp
    apiBase: http://localhost:8012
    model: qwen2.5-coder:1.5b-base
    roles:
      - autocomplete

  - name: Qwen 3.6 27b
    provider: llama.cpp
    model: qwen3.6:27b
    roles:
      - chat
      - edit
```

Start llama.cpp with:

```sh
.\llama-server --fim-qwen-1.5b-default --no-mmap --n-gpu-layers -1 --parallel 1 -c 1024
```

This takes up VRAM so decrease the context of the chat/agent model to `-c 10000`

## Learnings

- For better performance load everything into vram and check if there is no shared vram usage
- Large context is important for agentic sessions.
- Speculative decoding performance increase is small and not worth the vram cost.
- [pi](https://pi.dev) with its smaller base prompt is a good fit for smaller models
- Agents want to start the dev server and then wait and do nothing.

### Models

- Gemma 12b: had trouble with using the tools and edits
- GPT-OSS: fast, but likes to rewrite a lot, which can work, get errors when context grows
- Qwen: The smaller models get stuck in thinking or are unable to solve errors they created.
- Mistral: Good, until we get Jinja Exceptions.

Winners so far:

Model: Qwen 27b (with IQ3_XXS for larger context)
Agent: pi
