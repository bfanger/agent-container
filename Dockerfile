FROM fedora:44

ENV ANTHROPIC_BASE_URL=http://host.docker.internal:9931
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
  neovim \
  chromium firefox libavif libmanette libsecret harfbuzz-icu libwayland-server hyphen enchant2 gstreamer1-plugin-libav libicu libjpeg-turbo \
  jq \
  nmap openssl socat \
  bind-utils \
  procps-ng psmisc tree \
  zip \
  atop btop \
  poppler-utils \
  plocate \
  valkey valkey-compat-redis \
  perl-JSON-PP \
  python3 python3-pip \
  sdl2-compat-devel SDL2_image-devel SDL2_ttf-devel \
  php php-cli php-fpm php-mysqlnd php-pdo php-gd php-xml php-mbstring php-xdebug php-intl php-redis php-json composer

RUN npm install -g pnpm yarn
RUN mkdir /app && chown assistant:assistant /app

USER assistant
WORKDIR /home/assistant
COPY --chown=assistant:assistant ./home/assistant/.npmrc /home/assistant/.npmrc

# uv (to allow agents to setup python envs)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
# Mise (also allow agents to install runtimes not part of the container)
RUN curl -Ls https://mise.run | sh
# Install up to date versions of programming runtimes  
RUN \
  mise use -g golang && \
  mise use -g node && \
  mise use -g bun 
# Tooling for Go
RUN mise use -g golangci-lint && mise exec golang -- go install github.com/bokwoon95/wgo@latest 
# Oh My Zsh 
RUN curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
RUN git clone https://github.com/jessarcher/zsh-artisan.git ~/.oh-my-zsh/custom/plugins/artisan
RUN sed -i "s/plugins=(git)/plugins=(git yarn zsh-autosuggestions composer artisan)/g" ~/.zshrc
RUN pnpm completion zsh >> ~/.zshrc
RUN echo "source ~/.config/.zshrc" >> ~/.zshrc
# Vite Plus
RUN curl -fsSL https://vite.plus | VP_NODE_MANAGER=no bash
# Claude Code
RUN curl -fsSL https://claude.ai/install.sh | bash
# Preinstall Playwright browsers
RUN npx -y playwright install
# LazyVim
COPY --chown=assistant:assistant ./home/assistant/.config/nvim /home/assistant/.config/nvim
RUN /home/assistant/.config/nvim/neovim-docker-postinstall.sh
# Pi Agent
COPY --chown=assistant:assistant ./home/assistant/.pi /home/assistant/.pi
RUN npm install -g @earendil-works/pi-coding-agent && pi install npm:pi-mcp-adapter && pi install npm:pi-image-subagent && pi install npm:@heyhuynhgiabuu/pi-task && pnpm --dir /home/assistant/.pi/agent/skills/get-console-messages install
# Agent Browser
RUN npm install -g agent-browser && pi install npm:pi-agent-browser && if [ "$(uname -m)" != "aarch64" ]; then agent-browser install; fi
# OpenCode
RUN npm install -g opencode-ai
# little-coder
ENV LITTLE_CODER_PERMISSION_MODE="accept-all"
RUN npm install -g little-coder && mkdir -p ~/.config/little-coder/extensions && ln -s ~/.pi/agent/npm/node_modules/pi-image-subagent/analyze-image ~/.config/little-coder/extensions/analyze-image
# Herdr
RUN curl -fsSL https://herdr.dev/install.sh | sh
RUN herdr integration install pi \
  && herdr integration install opencode \
  && herdr integration install claude \
  && herdr plugin install lucasleon2107/herdr-tab-title-sync --yes \
  && herdr plugin install rohankewal/herdr-nerd-font-tab-name --yes

# Skills
RUN npx -y skills add herdrdev/herdr --skill herdr -g -y

COPY --chown=assistant:assistant ./home/assistant /home/assistant
EXPOSE 80
EXPOSE 3000
EXPOSE 5173
EXPOSE 8000

CMD ["/home/assistant/.local/bin/herdr"]