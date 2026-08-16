> ⚠️ The VRAM cost of running another model was not worth it for me, so I stopped using local autocomplete in favor of having a larger context for agents harnesses.

# Autocomplete in VSCode using a local model

## Installation and setup

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
.\llama-server --port 8012 --fim-qwen-1.5b-default --no-mmap --n-gpu-layers -1 --parallel 1 -c 1024
```

This takes up VRAM so decrease the context of the chat/agent model to `-c 10000`
