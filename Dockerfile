FROM fedora:44

ENV ANTHROPIC_BASE_URL=http://host.docker.internal:8080
ENV TZ=Europe/Amsterdam
ENV PATH="/home/assistant/.local/bin:$PATH:/home/assistant/go/bin:/home/assistant/.vite-plus/env:/home/assistant/.local/share/pnpm/bin"
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV MOZ_HEADLESS=1

RUN useradd --home /home/assistant --create-home --shell /usr/bin/zsh assistant

RUN dnf update -y && dnf install -y \
  zsh \
  git \
  fd-find \
  ripgrep \
  langpacks-en \
  tmux \
  ImageMagick \
  ffmpeg \
  nodejs24 \
  neovim \
  golang \
  chromium firefox libavif libmanette libsecret harfbuzz-icu libwayland-server hyphen enchant2 \
  jq \
  nmap \
  bind-utils \
  procps-ng \
  zip

USER assistant
WORKDIR /home/assistant

# Oh My Zsh
RUN curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh
RUN echo "source ~/.config/.zshrc" >>  ~/.zshrc
# Vite Plus
RUN curl -fsSL https://vite.plus | VP_NODE_MANAGER=no bash
# Tmux
RUN mkdir -p ~/.config/tmux/plugins/catppuccin && git clone https://github.com/catppuccin/tmux.git ~/.config/tmux/plugins/catppuccin/tmux && go install github.com/arl/gitmux@latest
# Claude Code
RUN curl -fsSL https://claude.ai/install.sh | bash
# Preinstall Playwright browsers
RUN npx -y playwright install

USER root
COPY ./home/assistant /home/assistant
RUN dnf update -y && dnf autoremove
RUN chown -R assistant:assistant \
  /home/assistant/.config \
  /home/assistant/.pi \
  /home/assistant/.gitconfig \
  /home/assistant/.*.conf \
  /home/assistant/.claude.json
USER assistant

RUN npm install -g pnpm yarn
# LazyVim
RUN /home/assistant/.config/nvim/neovim-docker-postinstall.sh
# Pi Agent
RUN npm install -g @earendil-works/pi-coding-agent && pnpm --dir /home/assistant/.pi/agent/skills/get-console-messages install
# Agent Browser
RUN npm install -g agent-browser && agent-browser install && pi install npm:pi-agent-browser
# OpenCode
RUN npm install -g opencode-ai

CMD ["/usr/sbin/tmux"]