#!/usr/bin/env bash
set -euo pipefail

# Headless tmux setup

CONFIG_URL="https://github.com/pocketOfShells/configs/raw/refs/heads/main/.tmux.conf"
CONFIG_DIR="$HOME/.tmux.conf"
TPM_DIR="$HOME/.tmux/plugins/tpm"
PKGS="tmux git xclip"

log() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }

# Prepend sudo or not
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then SUDO="sudo"; fi
fi


install_deps() {
  log "Installing dependencies: $PKGS"
  if   command -v apt    >/dev/null 2>&1; then $SUDO apt update -qq && $SUDO apt install -y $PKGS
  else echo "Package manager not found. Install manually: $PKGS" >&2; exit 1; fi
}


fetch_conf() {
  log "Fetching .tmux.conf -> $CONFIG_DIR"
  curl -fsSL "$CONFIG_URL" -o "$CONFIG_DIR"
}


install_tpm() {
  log "Setting up TPM at $TPM_DIR"
  if [ -d "$TPM_DIR/.git" ]; then
    git -C "$TPM_DIR" pull --ff-only --quiet
  else
    git clone --depth 1 --quiet https://github.com/tmux-plugins/tpm "$TPM_DIR"
  fi
}


install_plugins() {
  log "Installing plugins (headless)"
  : "${TERM:=xterm-256color}"; export TERM

  local started_server=0
  if ! tmux info >/dev/null 2>&1; then started_server=1; fi

  # Install plugins
  tmux new-session -d -s __tpm_setup >/dev/null 2>&1 || true
  "$TPM_DIR/scripts/install_plugins.sh"
  tmux kill-session -t __tpm_setup >/dev/null 2>&1 || true

  if [ "$started_server" -eq 1 ]; then
    tmux kill-server >/dev/null 2>&1 || true
  fi
}


main() {
  install_deps
  fetch_conf
  install_tpm
  install_plugins
  log "[+] Done. Run tmux or reload config and install plugins with 'Ctrl, b + I'."
}

main "$@"
