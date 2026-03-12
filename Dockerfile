FROM mcr.microsoft.com/vscode/devcontainers/javascript-node:latest

RUN apt update && apt upgrade -y && apt install -y \
  zsh \
  neovim \
  xdg-utils \
  firefox-esr \
  chromium \
  ffmpeg \
  fd-find \
  ripgrep \
  tmux \
  && npm -gf install npm \
  && npx playwright install --with-deps \
  && pnpm self-update \
  && apt clean && rm -rf /var/cache/apt/archives /var/lib/apt/lists  /root/.cache/ms-playwright/

RUN useradd --create-home --shell /usr/bin/zsh user

USER user
WORKDIR /home/user
RUN curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh
RUN npx -y playwright install

RUN curl https://mise.run | sh
ENV PATH="/home/user/.local/bin:$PATH"
RUN echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
RUN mise use opencode && mise use npm:@mariozechner/pi-coding-agent
RUN ln -s `which fdfind` /home/user/.local/bin/fd
RUN pnpm self-update

COPY ./user /home/user

USER root
RUN chown -R user:user /home/user/.config /home/user/.pi /home/user/.gitconfig
RUN chmod a+x /home/user/docker-scripts/start.sh /home/user/docker-scripts/setup.sh
USER user

CMD ["/home/user/docker-scripts/start.sh"]
