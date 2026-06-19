#!/bin/bash
# 安装 MoonBit 工具链
# 用法: ./scripts/install.sh

set -e

install_moonbit() {
  echo "Installing MoonBit toolchain..."

  if command -v moon >/dev/null 2>&1; then
    echo "MoonBit is already installed:"
    moon version
    return 0
  fi

  local install_script_url="https://cli.moonbitlang.com/install/main.sh"
  local tmp_script
  tmp_script="$(mktemp)"

  curl -fsSL "$install_script_url" -o "$tmp_script"
  bash "$tmp_script"
  rm -f "$tmp_script"

  echo "MoonBit installed successfully."
  moon version
}

install_moonbit
