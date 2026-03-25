#!/bin/bash
set -e

mise upgrade
mise exec neovim -- nvim --headless "+Lazy! sync" "+sleep 10" +q! 

# Install pi-agent skill dependencies
echo "" 
echo "Installing skill dependencies" 
SKILLS_DIR="$HOME/.pi/agent/skills"
for skill in "$SKILLS_DIR"/*/; do
    if [ -f "$skill/package.json" ]; then
        cd "$skill" || continue
        npm install
    fi
done
