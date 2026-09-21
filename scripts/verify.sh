#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

pass() {
  printf '\033[1;32m✓\033[0m %-12s %s\n' "$1" "$2"
}

fail() {
  printf '\033[1;31m✗\033[0m %-12s %s\n' "$1" "$2" >&2
  failures=$((failures + 1))
}

check_command() {
  local label=$1
  local command_name=$2
  shift 2

  if command -v "$command_name" >/dev/null 2>&1; then
    pass "$label" "$("$@" 2>/dev/null | head -n 1)"
  else
    fail "$label" "未找到 $command_name"
  fi
}

failures=0

if [[ "$(uname -s)" != "Darwin" ]]; then
  fail "macOS" "当前系统不是 macOS"
else
  pass "macOS" "$(sw_vers -productVersion) ($(uname -m))"
fi

if xcode-select -p >/dev/null 2>&1; then
  pass "Xcode CLT" "$(xcode-select -p)"
else
  fail "Xcode CLT" "未安装"
fi

if ! command -v brew >/dev/null 2>&1; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

check_command "Homebrew" brew brew --version
check_command "Git" git git --version
check_command "GitHub CLI" gh gh --version
check_command "mise" mise mise --version

if command -v mise >/dev/null 2>&1; then
  while IFS=: read -r tool executable version_arg; do
    if version="$(mise exec --cd "$SCRIPT_DIR" -- "$executable" "$version_arg" 2>/dev/null | head -n 1)"; then
      pass "$tool" "$version"
    else
      fail "$tool" "mise 未能运行 $tool"
    fi
  done <<'TOOLS'
node:node:--version
bun:bun:--version
go:go:version
rust:rustc:--version
python:python:--version
TOOLS
fi

if (( failures > 0 )); then
  printf '\n验证失败：%d 项未通过。\n' "$failures" >&2
  exit 1
fi

printf '\n全部验证通过。\n'
