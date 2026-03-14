FROM mcr.microsoft.com/vscode/devcontainers/javascript-node:latest

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV TZ=Europe/Amsterdam

RUN useradd --home /user --create-home --shell /usr/bin/zsh user
RUN apt update && apt upgrade -y && apt install -y --no-install-recommends \
  zsh \
  btop \
  xdg-utils \
  fd-find \
  ripgrep \
  tmux \
  && npm -gf install npm \
  && npx playwright install --with-deps && mv /root/.cache /user/.cache && chown -R user:user /user/.cache \
  && pnpm self-update \
  && apt clean -y && rm -rf /var/cache/apt/archives /var/lib/apt/lists

USER user
WORKDIR /user
RUN pnpm self-update

# zsh
RUN curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh
RUN echo "source ~/.config/.zshrc" >>  ~/.zshrc
# tmux
RUN mkdir -p ~/.config/tmux/plugins/catppuccin && git clone https://github.com/catppuccin/tmux.git ~/.config/tmux/plugins/catppuccin/tmux
# mise
RUN curl https://mise.run | sh
ENV PATH="/user/.local/bin:$PATH"
RUN mise use opencode bun neovim npm:@mariozechner/pi-coding-agent
RUN ln -s `which fdfind` /user/.local/bin/fd

# copy config files & update permissions
COPY ./user /user
USER root
RUN chown -R user:user /user/.config /user/.pi /user/.gitconfig /user/.tmux.conf
RUN chmod a+x /user/docker-scripts/start.sh /user/docker-scripts/setup.sh
USER user

CMD ["/user/docker-scripts/start.sh"]
