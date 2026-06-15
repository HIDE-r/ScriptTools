#!/usr/bin/env bash
set -euo pipefail

export SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-$XDG_RUNTIME_DIR/ssh-agent.socket}"

[[ -S "$SSH_AUTH_SOCK" ]] || {
  echo "ssh-agent socket not found: $SSH_AUTH_SOCK"
  exit 1
}

find "$HOME/.ssh" -maxdepth 1 -type f \
  ! -name '*.pub' \
  ! -name 'known_hosts*' \
  ! -name 'config' \
  ! -name 'authorized_keys' \
  -print0 |
while IFS= read -r -d '' key; do

  # 必须是合法私钥
  ssh-keygen -y -f "$key" >/dev/null 2>&1 || continue

  # 直接尝试 add（ssh-agent 会自动去重）
  echo "adding: $key"
  ssh-add "$key" 2>/dev/null || true

done
