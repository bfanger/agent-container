FROM mcr.microsoft.com/vscode/devcontainers/javascript-node:latest

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV TZ=Europe/Amsterdam
ENV COLORTERM=truecolor
ENV PNPM_STORE_DIR=/user/.pnpm-store
ENV ANTHROPIC_BASE_URL=http://host.docker.internal:8080
ENV ANTHROPIC_API_KEY=sk-not-a-real-key 

RUN useradd --home /user --create-home --shell /usr/bin/zsh user
RUN apt update && TERM=xterm apt upgrade -y && TERM=xterm apt install -y --no-install-recommends \
  zsh \
  btop \
  xdg-utils \
  fd-find \
  ripgrep \
  tmux \
  ffmpeg \
  nmap dnsutils \
  tree-sitter-cli \
  golang \
  composer php8.4-curl php8.4-dom php8.4-mysql php8.4-gd php8.4-opcache php8.4-sqlite3 php8.4-xdebug php8.4-apcu \
  && TERM=xterm npx playwright install --with-deps && mv /root/.cache /user/.cache && chown -R user:user /user/.cache \
  && apt clean -y && rm -rf /var/cache/apt/archives /var/lib/apt/lists

USER user
WORKDIR /user

# zsh
RUN curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh
RUN echo "source ~/.config/.zshrc" >>  ~/.zshrc
# Vite Plus
RUN curl -fsSL https://vite.plus | VP_NODE_MANAGER=no bash
# tmux
RUN mkdir -p ~/.config/tmux/plugins/catppuccin && git clone https://github.com/catppuccin/tmux.git ~/.config/tmux/plugins/catppuccin/tmux && go install github.com/arl/gitmux@latest
# mise
RUN curl https://mise.run | sh
ENV PATH="/user/.local/bin:$PATH:/user/go/bin:/user/.vite-plus/env"

RUN mise use opencode bun neovim
RUN ln -s `which fdfind` /user/.local/bin/fd

# copy config files & update permissions
COPY ./user /user
USER root
RUN chown -R user:user /user/.config /user/.pi /user/.gitconfig /user/.*.conf /user/.claude.json /usr/local/share/npm-global
RUN chmod a+x /user/docker-scripts/start.sh /user/docker-scripts/permissions.sh /user/docker-scripts/install.sh
USER user
RUN /user/docker-scripts/install.sh

CMD ["/user/docker-scripts/start.sh"]
