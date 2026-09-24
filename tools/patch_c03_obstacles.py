#!/usr/bin/env python3
"""C03: A-Cheng only speaks when the player hits an obstacle. No tour, no FAQ."""

from __future__ import annotations

from copy import copy
from pathlib import Path

import openpyxl

ROOT = Path(__file__).resolve().parents[1]
WORKBOOK = ROOT / "outputs/01a037d8-c4f0-70d3-bc69-8c3819094801/雾港来信_剧情作者工作簿.xlsx"
SHEET = "剧情剧本"
SCENE = "春和戏院·后台通道"
SCENE_ID = "C03_PASSAGE"


def headers(ws) -> dict[str, int]:
    return {cell.value: i for i, cell in enumerate(ws[1]) if cell.value}


def find(ws, col: dict[str, int], row_id: str) -> int:
    for row in range(2, ws.max_row + 1):
        if ws.cell(row, col["自动ID"] + 1).value == row_id:
            return row
    raise KeyError(row_id)


def fill(ws, row: int, col: dict[str, int], data: dict) -> None:
    for field in col:
        ws.cell(row, col[field] + 1).value = data.get(field, None)


def insert_after(ws, after_row: int) -> int:
    ws.insert_rows(after_row + 1)
    for col_idx in range(1, ws.max_column + 1):
        ws.cell(after_row + 1, col_idx)._style = copy(ws.cell(after_row, col_idx)._style)
    return after_row + 1


def base(**kwargs) -> dict:
    row = {
        "场景ID": SCENE_ID,
        "场景": SCENE,
        "出现条件": "始终",
        "是否说出口": "是",
        "演出/交互方式": "连续剧情逐句点击；主控发言按钮",
    }
    row.update(kwargs)
    return row


def main() -> int:
    wb = openpyxl.load_workbook(WORKBOOK)
    ws = wb[SHEET]
    col = headers(ws)

    fill(
        ws,
        find(ws, col, "C03_001"),
        col,
        base(
            自动ID="C03_001",
            对话阶段="第一章·阿成带路",
            阶段顺序=1,
            人物="阿成",
            内容类型="NPC台词",
            话题="挡路",
            NPC台词="阿成：「贴右走。」",
            下一话题="",
            画面表现="一名伙计抱着景片从左侧冲出来。阿成把沈砚舟拉到右边。",
            设计备注="DEC-20260922-DIALOGUE-IRON-RULE：只拦，不解释景路。",
            **{"演出/交互方式": "连续剧情逐句点击；主控发言按钮；末句显示两个回答"},
        ),
    )
    fill(
        ws,
        find(ws, col, "C03_010"),
        col,
        base(
            自动ID="C03_010",
            对话阶段="第一章·阿成带路",
            阶段顺序=2,
            人物="沈砚舟",
            内容类型="玩家选项",
            话题="左边",
            玩家可选台词="左边怎么了？",
            选择结果="c03_left=asked",
            下一话题="第一章·阿成带路·景路",
            **{"状态写入（不显示）": "c03_left=asked"},
        ),
    )
    fill(
        ws,
        find(ws, col, "C03_011"),
        col,
        base(
            自动ID="C03_011",
            对话阶段="第一章·阿成带路",
            阶段顺序=2,
            人物="沈砚舟",
            内容类型="玩家选项",
            话题="左边",
            玩家可选台词="走。",
            选择结果="c03_left=ignored",
            下一话题="第一章·阿成带路·帘口",
            是否说出口="否",
            **{"演出/交互方式": "玩家点击", "状态写入（不显示）": "c03_left=ignored"},
        ),
    )
    fill(
        ws,
        find(ws, col, "C03_020"),
        col,
        base(
            自动ID="C03_020",
            对话阶段="第一章·阿成带路·景路",
            阶段顺序=1,
            人物="阿成",
            内容类型="NPC台词",
            话题="左边",
            NPC台词="阿成：「景路。别站。」",
            下一话题="第一章·阿成带路·帘口",
            玩家因此知道什么="左边是运景的路，不能站。",
        ),
    )

    # C03_012 and C03_021 are the old FAQ. Reuse them as the curtain beat.
    fill(
        ws,
        find(ws, col, "C03_012"),
        col,
        base(
            自动ID="C03_012",
            对话阶段="第一章·阿成带路·帘口",
            阶段顺序=1,
            人物="系统",
            内容类型="纯画面",
            话题="帘口",
            下一话题="",
            是否说出口="否",
            画面表现="侧台帘口不断有人进出。",
            **{"演出/交互方式": "背景UI无对话框；末帧显示两个回答"},
        ),
    )
    fill(
        ws,
        find(ws, col, "C03_021"),
        col,
        base(
            自动ID="C03_021",
            对话阶段="第一章·阿成带路·帘口",
            阶段顺序=2,
            人物="沈砚舟",
            内容类型="玩家选项",
            话题="帘口",
            玩家可选台词="掀开看看。",
            选择结果="c03_curtain=lift",
            下一话题="第一章·阿成带路·别掀",
            是否说出口="否",
            **{"演出/交互方式": "玩家点击", "状态写入（不显示）": "c03_curtain=lift"},
        ),
    )

    cursor = find(ws, col, "C03_021")
    extras = [
        base(
            自动ID="C03_022",
            对话阶段="第一章·阿成带路·帘口",
            阶段顺序=2,
            人物="沈砚舟",
            内容类型="玩家选项",
            话题="帘口",
            玩家可选台词="跟着走。",
            选择结果="c03_curtain=ignored",
            下一话题="第一章·阿成带路·铁梯",
            是否说出口="否",
            **{"演出/交互方式": "玩家点击", "状态写入（不显示）": "c03_curtain=ignored"},
        ),
        base(
            自动ID="C03_040",
            对话阶段="第一章·阿成带路·别掀",
            阶段顺序=1,
            人物="阿成",
            内容类型="NPC台词",
            话题="帘口",
            NPC台词="阿成：「别掀。」\n阿成：「里头的人顾不上看路。」",
            下一话题="第一章·阿成带路·铁梯",
            画面表现="沈砚舟伸手时，阿成按住帘角。",
            玩家因此知道什么="开锣前侧台帘口也不能掀，里头的人顾不上看路。",
        ),
        base(
            自动ID="C03_050",
            对话阶段="第一章·阿成带路·铁梯",
            阶段顺序=1,
            人物="系统",
            内容类型="纯画面",
            话题="铁梯",
            下一话题="",
            是否说出口="否",
            画面表现="贴墙窄铁梯。木架之间垂着吊绳。",
            **{"演出/交互方式": "背景UI无对话框；末帧显示三个回答"},
        ),
        base(
            自动ID="C03_051",
            对话阶段="第一章·阿成带路·铁梯",
            阶段顺序=2,
            人物="沈砚舟",
            内容类型="玩家选项",
            话题="铁梯",
            玩家可选台词="上去。",
            选择结果="c03_ladder=climb",
            下一话题="第一章·阿成带路·别上",
            是否说出口="否",
            **{"演出/交互方式": "玩家点击", "状态写入（不显示）": "c03_ladder=climb"},
        ),
        base(
            自动ID="C03_052",
            对话阶段="第一章·阿成带路·铁梯",
            阶段顺序=2,
            人物="沈砚舟",
            内容类型="玩家选项",
            话题="铁梯",
            玩家可选台词="这上面是什么？",
            选择结果="c03_ladder=asked",
            下一话题="第一章·阿成带路·问梯",
            **{"状态写入（不显示）": "c03_ladder=asked"},
        ),
        base(
            自动ID="C03_053",
            对话阶段="第一章·阿成带路·铁梯",
            阶段顺序=2,
            人物="沈砚舟",
            内容类型="玩家选项",
            话题="铁梯",
            玩家可选台词="走。",
            选择结果="c03_ladder=ignored",
            下一话题="第一章·阿成带路·催灯",
            是否说出口="否",
            **{"演出/交互方式": "玩家点击", "状态写入（不显示）": "c03_ladder=ignored"},
        ),
        base(
            自动ID="C03_060",
            对话阶段="第一章·阿成带路·别上",
            阶段顺序=1,
            人物="阿成",
            内容类型="NPC台词",
            话题="铁梯",
            NPC台词="阿成：「别上。」\n阿成：「戏没散，外人不能上。」",
            下一话题="第一章·阿成带路·催灯",
            画面表现="阿成横在梯口。",
            玩家因此知道什么="戏没散，外人不能上天桥。",
        ),
        base(
            自动ID="C03_061",
            对话阶段="第一章·阿成带路·问梯",
            阶段顺序=1,
            人物="阿成",
            内容类型="NPC台词",
            话题="铁梯",
            NPC台词="阿成：「天桥。今晚不走。」",
            下一话题="第一章·阿成带路·催灯",
            玩家因此知道什么="这座铁梯通天桥，今晚不走。",
        ),
        base(
            自动ID="C03_070",
            对话阶段="第一章·阿成带路·催灯",
            阶段顺序=1,
            人物="陈九生",
            内容类型="NPC台词",
            话题="催灯",
            NPC台词="陈九生：「前场催灯了，你还磨蹭。」\n阿成：「爹，方先生让我先带报馆的过去。」\n陈九生：「站线外。」",
            下一话题="第一章·纪念演出采访",
            画面表现="陈九生把提灯塞给阿成，看了沈砚舟一眼，又进了侧台。",
            玩家因此知道什么="阿成叫陈九生爹。",
            设计备注="命令，不解释景片。",
        ),
    ]
    for data in extras:
        cursor = insert_after(ws, cursor)
        fill(ws, cursor, col, data)

    wb.save(WORKBOOK)
    print(f"PATCHED C03, rows={ws.max_row - 1}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
