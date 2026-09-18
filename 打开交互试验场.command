#!/bin/zsh
set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/prototypes/story_interaction_lab"
GODOT_APP="/Applications/Godot.app/Contents/MacOS/Godot"

if [[ ! -x "$GODOT_APP" ]]; then
  GODOT_APP="/private/tmp/fog_harbor_godot/Godot.app/Contents/MacOS/Godot"
fi

if [[ ! -x "$GODOT_APP" ]]; then
  echo "没有找到 Godot。请先安装 Godot，再重新双击本文件。"
  if [[ -t 0 && -t 1 ]]; then
    read -k 1 "?按任意键关闭…"
  fi
  exit 1
fi

if [[ ! -f "$PROJECT_DIR/project.godot" ]]; then
  echo "没有找到交互试验场项目："
  echo "$PROJECT_DIR"
  if [[ -t 0 && -t 1 ]]; then
    read -k 1 "?按任意键关闭…"
  fi
  exit 1
fi

echo "正在启动《雾港来信》交互试验场…"
echo "项目：$PROJECT_DIR"
echo

# 只启动 prototypes/story_interaction_lab，绝不切换或修改仓库主项目。
exec "$GODOT_APP" --path "$PROJECT_DIR"
