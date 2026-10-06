# Clean-room test image: current official CachyOS base + a normal non-root
# user with passwordless sudo (mirrors a fresh laptop user). The repo is
# bind-mounted at runtime, NOT baked in, so tests always run the working
# tree. Desktop compositors cannot run here; this validates packages,
# symlinks, shells, tmux, Neovim, OpenCode, mise, Speedy build/install,
# and bootstrap idempotency.
FROM cachyos/cachyos:latest

RUN pacman -Sy --noconfirm sudo git \
 && useradd -m -s /bin/bash tester \
 && printf 'tester ALL=(ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/tester \
 && chmod 0440 /etc/sudoers.d/tester

USER tester
WORKDIR /home/tester
ENV HOME=/home/tester
