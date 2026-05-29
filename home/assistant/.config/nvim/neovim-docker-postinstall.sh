#!/bin/bash
DEBUG=false
for arg in "$@"; do
    if [ "$arg" = "--debug" ]; then
        DEBUG=true
    fi
done
nvim --headless "+Lazy! sync" "+sleep 10" +q!
echo ""

TIMEOUT_MS=5000

cat > /tmp/vim-post-install.md << 'EOF'
# LazyVim

Waiting for plugins and language servers to install.
EOF

tmux new-session -d -s lazyvim "nvim /tmp/vim-post-install.md"

last_messages_seen=$(date +%s%3N)

for i in $(seq 1 3000); do
    sleep 0.1

    current_time=$(date +%s%3N)
    pane_content=$(tmux capture-pane -p -t lazyvim 2>/dev/null)

    if [ "$DEBUG" = true ]; then
        echo "$pane_content"
    fi
    if echo "$pane_content" | grep -qi "Press ENTER or type command to continue"; then
        tmux send-keys -t lazyvim Enter
        last_messages_seen=$current_time
    fi

    pattern="Messages|mason-lspconfig|installed"
    if echo "$pane_content" | grep -qiE "$pattern"; then
        last_messages_seen=$current_time
    fi

    since_last_ms=$((current_time - last_messages_seen))
    remaining_seconds=$(( (TIMEOUT_MS - since_last_ms) / 1000 ))
    if [ "$remaining_seconds" -lt 0 ]; then
        remaining_seconds=0
    fi
    if [ "$since_last_ms" -eq 0 ]; then
      printf "\rInstalling LSPs... "
    else
      printf "\rIdle %d seconds..." "$remaining_seconds"
    fi

    if [ "$since_last_ms" -ge "$TIMEOUT_MS" ]; then
        echo ""
        echo "Done"
        break
    fi
done

tmux kill-session -t lazyvim 2>/dev/null
