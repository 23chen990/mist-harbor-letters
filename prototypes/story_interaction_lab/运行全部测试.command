#!/bin/zsh
set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
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

overall_status=0

echo "《雾港来信》交互试验场测试"
echo "项目：$PROJECT_DIR"
echo

echo "[1/3] tests/test_story_flow.gd"
"$GODOT_APP" --headless --path "$PROJECT_DIR" --script res://tests/test_story_flow.gd
flow_status=$?
if [[ "$flow_status" -eq 0 ]]; then
  echo "结果：PASS"
else
  echo "结果：FAIL（退出码 $flow_status）"
  overall_status=1
fi

echo
echo "[2/3] tests/test_interaction_state.gd"
"$GODOT_APP" --headless --path "$PROJECT_DIR" --script res://tests/test_interaction_state.gd
state_status=$?
if [[ "$state_status" -eq 0 ]]; then
  echo "结果：PASS"
else
  echo "结果：FAIL（退出码 $state_status）"
  overall_status=1
fi

echo
echo "[3/3] tests/test_interaction_lab.gd"
"$GODOT_APP" --headless --path "$PROJECT_DIR" --script res://tests/test_interaction_lab.gd
lab_status=$?
if [[ "$lab_status" -eq 0 ]]; then
  echo "结果：PASS"
else
  echo "结果：FAIL（退出码 $lab_status）"
  overall_status=1
fi

echo
if [[ "$overall_status" -eq 0 ]]; then
  echo "全部测试通过。"
else
  echo "测试未全部通过，请查看上方输出。"
fi

if [[ -t 0 && -t 1 ]]; then
  read -k 1 "?按任意键关闭…"
fi

exit "$overall_status"
