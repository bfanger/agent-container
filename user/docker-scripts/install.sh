#!/bin/bash
set -e

# Install pi-agent skill dependencies 
SKILLS_DIR="$HOME/.pi/agent/skills"
for skill in "$SKILLS_DIR"/*/; do
    if [ -f "$skill/package.json" ]; then
        cd "$skill" || continue
        npm install
    fi
done
