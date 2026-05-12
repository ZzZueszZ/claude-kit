#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-$(pwd)}"

mkdir -p "$TARGET_DIR/.claude"

copy_dir() {
  local name="$1"
  local src="$SRC_DIR/.claude/$name"
  local dest="$TARGET_DIR/.claude/$name"

  if [ -d "$src" ]; then
    rm -rf "$dest"
    cp -R "$src" "$dest"
    echo "Installed .claude/$name"
  fi
}

copy_dir commands
copy_dir skills
copy_dir agents

if [ ! -f "$TARGET_DIR/CLAUDE.md" ]; then
  cp "$SRC_DIR/templates/CLAUDE.md" "$TARGET_DIR/CLAUDE.md"
  echo "Created CLAUDE.md template. Please customize it."
else
  echo "CLAUDE.md exists, skipped."
fi

echo "Claude toolkit installed into $TARGET_DIR."
