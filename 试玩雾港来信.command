#!/bin/zsh
set -eu

PROJECT_DIR="${0:A:h}"
GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
if [[ ! -x "$GODOT_BIN" ]]; then
  GODOT_BIN="/private/tmp/fog_harbor_godot/Godot.app/Contents/MacOS/Godot"
fi
if [[ ! -x "$GODOT_BIN" ]]; then
  print "未找到 Godot。请安装 Godot 后重新双击本文件。"
  exit 1
fi

print "启动《雾港来信》v6 垂直切片：$PROJECT_DIR"
exec "$GODOT_BIN" --path "$PROJECT_DIR"
