#!/bin/bash
set -e

# Install pi-agent dependencies
echo "Installing skill dependencies" 
SKILLS_DIR="$HOME/.pi/agent/skills"
for skill in "$SKILLS_DIR"/*/; do
  if [ -f "$skill/package.json" ]; then
    cd "$skill" || continue
    pnpm install
  fi
done
