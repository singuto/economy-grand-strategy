#!/usr/bin/env bash
# Surfaces the same shader/resource errors Godot prints in the editor Output panel.
# Usage: GODOT=/path/to/Godot_v4.6*_linux.x86_64 ./tools/godot_headless_check.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:?Set GODOT to your Godot 4.x editor binary (same minor as project.godot features)}"
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT
"$GODOT" --path "$ROOT" --headless -v --quit-after 10 2>&1 | tee "$LOG"
if grep -qE 'SHADER ERROR|^[[:space:]]*ERROR:.*(Shader|shader|Parse Error)' "$LOG"; then
	echo >&2 "godot_headless_check: failed (see errors above)"
	exit 1
fi
