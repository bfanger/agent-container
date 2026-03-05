# Agentic Coding Docker Setup

## Installation

Install [LM Studio](https://lmstudio.ai/) & enable the dev server or run [llama.cpp]()

```sh
docker compose up --build -d
docker compose exec --user root dev /home/user/docker-scripts/setup.sh
```

### OpenCode

Open http://localhost:4096/ for OpenCode.

## Pi.dev

```sh
docker compose exec dev zsh
```

```sh
cd projects/your-project
pi
```

### Running Qwen3.5 model with llama.cpp

```sh
 .\llama-server.exe --host 0.0.0.0 --port 4321 -m D:\ai-models\unsloth\Qwen3.5-27B-GGUF\Qwen3.5-27B-UD-IQ3_XXS.gguf --temp 0.6 --top-p 0.95 --top-k 20 --min-p 0.0 --presence-penalty 0.0 --repeat-penalty 1.0 --fit off -c 45000 --metrics
```

## Learnings

- For better performance load everything into vram and check if there no shared vram usage
- Large context is important for agentic sessions.
- Speculative decoding performance increase is small and not worth the vram cost.
- [pi](https://pi.dev) with its smaller base prompt is a good fit for smaller models
- Agents want to start the dev server and then wait and do nothing.

### Models

- Gemma 12b: had trouble with using the tools and edits
- GPT-OSS: fast, but likes to rewrite a lot, which can work.
- Qwen: By default the smaller models gets stuck into thinking or are unable to solve an error it created.
- Mistral: Good, until we get Jinja Exceptions.
