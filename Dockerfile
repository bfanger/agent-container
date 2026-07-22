FROM fedora:44

ENV ANTHROPIC_BASE_URL=http://host.docker.internal:8080
ENV TZ=Europe/Amsterdam
ENV PATH="/home/assistant/.local/bin:$PATH:/home/assistant/go/bin:/home/assistant/.vite-plus/env:/home/assistant/.local/share/pnpm/bin"
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV MOZ_HEADLESS=1
ENV NEXT_TELEMETRY_DISABLED=1

RUN useradd --home /home/assistant --create-home --shell /usr/bin/zsh assistant

RUN dnf update -y && dnf install -y \
  zsh \
  git \
  fd-find \
  ripgrep \
  langpacks-en \
  tmux \
  ImageMagick \
  pngquant \
  ffmpeg \
  nodejs24 \
  neovim \
  golang \
  chromium firefox libavif libmanette libsecret harfbuzz-icu libwayland-server hyphen enchant2 \
  jq \
  nmap openssl socat \
  bind-utils \
  procps-ng psmisc tree \
  zip \
  atop btop \
  poppler-utils \
  plocate \
  php php-cli php-fpm php-mysqlnd php-pdo php-gd php-xml php-mbstring php-xdebug php-intl php-redis php-json composer \
  valkey valkey-compat-redis \
  perl-JSON-PP \
  python3 python3-pip

RUN npm install -g pnpm yarn

USER assistant
WORKDIR /home/assistant

# uv (to allow agents to setup python envs)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Mise (to allow agents to install runtimes not part of this container)
RUN curl -Ls https://mise.run | sh

# Oh My Zsh
RUN curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
RUN git clone https://github.com/jessarcher/zsh-artisan.git ~/.oh-my-zsh/custom/plugins/artisan
RUN sed -i "s/plugins=(git)/plugins=(git yarn zsh-autosuggestions composer artisan)/g" ~/.zshrc
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
RUN chown -R assistant:assistant \
  /home/assistant/.config \
  /home/assistant/.pi \
  /home/assistant/.gitconfig \
  /home/assistant/.zsh_history \
  /home/assistant/.*.conf \
  /home/assistant/.claude*
USER assistant

# LazyVim
RUN /home/assistant/.config/nvim/neovim-docker-postinstall.sh
# Pi Agent
RUN npm install -g @earendil-works/pi-coding-agent && pi install npm:pi-mcp-adapter && pi install npm:@heyhuynhgiabuu/pi-task && pnpm --dir /home/assistant/.pi/agent/skills/get-console-messages install
# Agent Browser
RUN npm install -g agent-browser && pi install npm:pi-agent-browser && if [ "$(uname -m)" != "aarch64" ]; then agent-browser install; fi
# OpenCode
RUN npm install -g opencode-ai

EXPOSE 80
EXPOSE 3000
EXPOSE 5173
EXPOSE 8000

CMD ["/usr/sbin/tmux"]