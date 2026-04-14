#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
template="$repo_root/doc/flake-update-release-notes-template.md"
notes_dir="$repo_root/doc/release-notes"
date_prefix="$(date +%F)"
slug="${1:-flake-update}"
target="$notes_dir/${date_prefix}-${slug}.md"

mkdir -p "$notes_dir"

if [[ -e "$target" ]]; then
  echo "Release note already exists: $target"
  exit 1
fi

cp "$template" "$target"
echo "Created: $target"
