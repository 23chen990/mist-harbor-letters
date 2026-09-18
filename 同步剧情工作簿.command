#!/bin/zsh
set -u

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
GODOT_APP="/Applications/Godot.app/Contents/MacOS/Godot"

if [[ ! -x "$GODOT_APP" ]]; then
  GODOT_APP="/private/tmp/fog_harbor_godot/Godot.app/Contents/MacOS/Godot"
fi

if [[ ! -x "$GODOT_APP" ]]; then
  echo "没有找到 Godot。请先安装 Godot，再重新双击本文件。"
  read -k 1 "?按任意键关闭…"
  exit 1
fi

"$GODOT_APP" --headless --path "$PROJECT_DIR" --script res://tools/同步剧情工作簿.gd
SYNC_STATUS=$?
echo
if [[ "$SYNC_STATUS" -eq 0 ]]; then
  read -k 1 "?同步成功，按任意键关闭…"
else
  read -k 1 "?同步失败，按任意键关闭…"
fi
exit "$SYNC_STATUS"
