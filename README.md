# Agentic Coding Docker Setup

An environment for running agent harnesses without permission restrictions.

This is the first layer of security, not the last. Apply trait modeling techniques when using agents, they can't leak info they don't have.

## Installation

Building the container and the agent cli utility

```sh
docker build --tag agent --no-cache .
go install ./cmd/agent
```

To run a local model:
Install [LM Studio](https://lmstudio.ai/) and enable the dev server on port 9931 or run [llama.cpp](https://github.com/ggml-org/llama.cpp)

## Running using Docker directly

```sh
docker run --rm -it agent
# Inside the container start your agent: pi, opencode or claude
pi
```

## Running using the agent cli

It creates the docker container and relevant volumes for pnpm for improved speed and isolation.

```sh
agent
```

Create an alias in your powershell $PROFILE, example:

```sh
function pi {
    & 'C:\Users\bfang\go\bin\agent.exe' --docker-desktop --llama-swap 'C:\Users\bfang\Projects\agent-container\llama-swap.yml' @args
}
```

This also starts docker & llama-server if they are not yet running.

# Models (on 16GB VRAM)

Winners so far:

Model: [Qwen](https://huggingface.co/Qwen) 27b with IQ3_XXS from [unsloth](https://huggingface.co/unsloth) for nice mix of intelligence, speed and context.
Agent: pi

## Running models with llama.cpp

See [llama-swap.yaml](./llama-swap.yml) for my llama.cpp settings & models.
[LLaMa swap](https://github.com/mostlygeek/llama-swap) setup allows switching models inside the harness, allowing to use speedy mtp configuration and switching to slower larger context based on the task.

## Learnings

- For better performance load everything into vram (Check if there is no shared vram usage)
- Large context is important for agentic sessions.
- MTP multi token prediction can almost double the performance, at the cost of vram.
- [pi](https://pi.dev) with its smaller base prompt is a good fit for smaller models
- Agents want to start the dev server and then wait and do nothing.
- Testing a model on day of the release can be unfair because of missing support from tooling like llama.cpp
