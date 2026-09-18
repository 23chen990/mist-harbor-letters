#!/bin/zsh
set -eu

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKBOOK_PATH="$PROJECT_DIR/outputs/01a037d8-c4f0-70d3-bc69-8c3819094801/雾港来信_剧情作者工作簿.xlsx"

if [[ ! -f "$WORKBOOK_PATH" ]]; then
  echo "没有找到剧情作者工作簿："
  echo "$WORKBOOK_PATH"
  read -k 1 "?按任意键关闭…"
  exit 1
fi

open "$WORKBOOK_PATH"
