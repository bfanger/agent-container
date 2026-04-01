#!/bin/bash
set -e

go install golang.org/x/tools/gopls@latest

npm install -g -f npm@latest
npm install -g \
  pnpm@latest \
  @mariozechner/pi-coding-agent@latest \
  agent-browser@latest \
  typescript-language-server@latest \
  typescript@latest \
  svelte-language-server \
  @vue/language-server

agent-browser install

curl -fsSL https://claude.ai/install.sh | bash

# Install pi-agent dependencies
pi install npm:pi-agent-browser
pi install npm:lsp-pi
echo "Installing skill dependencies" 
SKILLS_DIR="$HOME/.pi/agent/skills"
for skill in "$SKILLS_DIR"/*/; do
  if [ -f "$skill/package.json" ]; then
    cd "$skill" || continue
    npm install
  fi
done

mise upgrade
mise exec neovim -- nvim --headless "+Lazy! sync" "+sleep 10" +q! 
echo "" 
