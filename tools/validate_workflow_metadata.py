#!/usr/bin/env python3
"""只读校验《雾港来信》AI 团队工作流与知识索引元数据。"""

import argparse
from datetime import date
import json
from pathlib import Path, PurePosixPath
import re
import sys
import unicodedata
from typing import Dict, List, Sequence, Tuple


REQUIRED_FILES = (
    "AGENTS.md",
    "docs/AI_TEAM_OPERATING_SYSTEM.md",
    "docs/DECISIONS.md",
    "docs/templates/AI_TASK_PACKET.md",
    "docs/templates/AI_RESEARCH_RECORD.md",
    "docs/templates/AI_ROLE_REPORT.md",
    ".agents/skills/mist-harbor-orchestrator/SKILL.md",
    "research/KNOWLEDGE_INDEX.md",
)

REQUIRED_MARKERS = {
    "AGENTS.md": (
        "## 1. 权威顺序",
        "## 4. 正式修改闭环",
        "## 8. 总调度与知识复用",
    ),
    "docs/AI_TEAM_OPERATING_SYSTEM.md": (
        "## 2. 三档执行强度",
        "## 7. 正式修改审批门",
        "## 9. 独立 QA",
    ),
    "docs/templates/AI_TASK_PACKET.md": (
        "## 2. 唯一目标",
        "## 4. 正式修改审批门",
        "### 变更影响检查",
        "| 剧情事实、因果、场次与顺序 |",
        "| 作者真相、角色私有知识、玩家知识与信息释放 |",
        "| 工作簿作者入口、同步链与程序生成物 |",
        "| 测试、过期基线与回归范围 |",
        "| Demo Hook、商店页、Trailer、定价与发行 |",
        "## 8. 验收计划",
    ),
    "docs/templates/AI_RESEARCH_RECORD.md": (
        "## 4. 来源",
        "## 7. 新鲜度与过期",
        "## 8. 采纳状态",
    ),
    "docs/templates/AI_ROLE_REPORT.md": (
        "## 4. 发现与证据",
        "## 8. 验证记录",
        "## 9. 冲突、阻塞与待确认",
    ),
    ".agents/skills/mist-harbor-orchestrator/SKILL.md": (
        "name: mist-harbor-orchestrator",
        "## Route work",
        "## Enforce gates",
        "## Integrate and verify",
    ),
}

REQUIRED_FIELDS = (
    "path",
    "asset_type",
    "authority",
    "lifecycle_status",
    "formal_use",
    "scope",
    "source_basis",
    "as_of",
    "last_reviewed",
    "valid_against",
    "decision_refs",
    "reuse_conditions",
    "refresh_trigger",
    "unresolved_conflicts",
    "tags",
)

ASSET_TYPES = {
    "research_index",
    "design_pattern",
    "commercial_hypothesis",
    "working_research",
    "working_lesson",
    "review_snapshot",
    "narrative_draft_series",
    "process_audit",
    "production_log",
}
AUTHORITIES = {
    "non_authoritative_research",
    "working_only",
    "process_record",
}
LIFECYCLE_STATUSES = {
    "active",
    "needs_revalidation",
    "superseded",
    "rejected",
    "historical",
    "pending_confirmation",
}
FORMAL_USES = {
    "advisory_only",
    "working_context_only",
    "process_only",
    "historical_only",
    "never_formal",
}
DISALLOWED_PREFIXES = (
    "content/程序生成_请勿手改/",
    "outputs/",
    ".codex_spreadsheet_work/",
    ".godot/",
)

ENTRY_RE = re.compile(r"^## ([A-Z][A-Z0-9]*-\d{8}-\d{2})\s*$")
FIELD_RE = re.compile(r"^- ([a-z_]+):\s*(.*?)\s*$")
DECISION_RE = re.compile(r"\bDEC-\d{8}-\d{2}\b")


def parse_index(index_path: Path) -> List[Tuple[str, Dict[str, str]]]:
    entries: List[Tuple[str, Dict[str, str]]] = []
    current_id = ""
    current_fields: Dict[str, str] = {}

    for line in index_path.read_text(encoding="utf-8").splitlines():
        header = ENTRY_RE.match(line)
        if header:
            if current_id:
                entries.append((current_id, current_fields))
            current_id = header.group(1)
            current_fields = {}
            continue
        if not current_id:
            continue
        field = FIELD_RE.match(line)
        if field:
            current_fields[field.group(1)] = field.group(2).strip()

    if current_id:
        entries.append((current_id, current_fields))
    return entries


def clean_path_value(value: str) -> str:
    if len(value) >= 2 and value.startswith("`") and value.endswith("`"):
        return value[1:-1]
    return value


def safe_repository_file(root: Path, raw_path: str) -> Tuple[bool, str]:
    if not raw_path or "\\" in raw_path:
        return False, ""
    pure = PurePosixPath(raw_path)
    if pure.is_absolute() or ".." in pure.parts:
        return False, ""
    candidate = root.joinpath(*pure.parts)
    try:
        candidate.resolve().relative_to(root.resolve())
    except ValueError:
        return False, ""
    return True, pure.as_posix()


def normalized_path(path: str) -> str:
    return unicodedata.normalize("NFC", path).casefold()


def parse_date(value: str) -> bool:
    try:
        date.fromisoformat(value)
    except ValueError:
        return False
    return True


def validate(root: Path) -> Tuple[List[str], List[str], int]:
    errors: List[str] = []
    warnings: List[str] = []

    for relative_path in REQUIRED_FILES:
        path = root / relative_path
        if not path.is_file():
            errors.append(f"缺少工作流文件：{relative_path}")
            continue
        markers = REQUIRED_MARKERS.get(relative_path, ())
        if markers:
            try:
                content = path.read_text(encoding="utf-8")
            except (OSError, UnicodeError) as exc:
                errors.append(f"无法读取工作流文件 {relative_path}：{exc}")
                continue
            missing_markers = [marker for marker in markers if marker not in content]
            if missing_markers:
                errors.append(
                    f"{relative_path} 缺少必要标记：{', '.join(missing_markers)}"
                )

    index_path = root / "research/KNOWLEDGE_INDEX.md"
    if not index_path.is_file():
        return errors, warnings, 0

    try:
        entries = parse_index(index_path)
    except (OSError, UnicodeError) as exc:
        errors.append(f"无法读取知识索引：{exc}")
        return errors, warnings, 0

    if not entries:
        errors.append("知识索引没有可校验的资产条目")
        return errors, warnings, 0

    decision_ids = set()
    decisions_path = root / "docs/DECISIONS.md"
    if decisions_path.is_file():
        try:
            decision_ids = set(
                DECISION_RE.findall(decisions_path.read_text(encoding="utf-8"))
            )
        except (OSError, UnicodeError) as exc:
            errors.append(f"无法读取决策日志：{exc}")

    seen_ids = set()
    seen_paths = set()
    all_ids = {asset_id for asset_id, _fields in entries}
    folded_disallowed_prefixes = tuple(
        normalized_path(prefix) for prefix in DISALLOWED_PREFIXES
    )

    for asset_id, fields in entries:
        if asset_id in seen_ids:
            errors.append(f"重复 asset_id：{asset_id}")
        seen_ids.add(asset_id)

        missing = [key for key in REQUIRED_FIELDS if not fields.get(key)]
        if missing:
            errors.append(f"{asset_id} 缺少字段：{', '.join(missing)}")
            continue

        raw_path = clean_path_value(fields["path"])
        safe, relative_path = safe_repository_file(root, raw_path)
        if not safe:
            errors.append(f"{asset_id} 使用不安全路径：{raw_path}")
        else:
            folded = normalized_path(relative_path)
            if folded in seen_paths:
                errors.append(f"{asset_id} 的路径重复：{relative_path}")
            seen_paths.add(folded)
            if normalized_path(relative_path).startswith(folded_disallowed_prefixes):
                errors.append(f"{asset_id} 不得索引生成物或临时目录：{relative_path}")
            elif not (root / relative_path).is_file():
                errors.append(f"{asset_id} 登记的文件不存在：{relative_path}")

        if fields["asset_type"] not in ASSET_TYPES:
            errors.append(f"{asset_id} asset_type 无效：{fields['asset_type']}")
        if fields["authority"] not in AUTHORITIES:
            errors.append(f"{asset_id} authority 无效：{fields['authority']}")
        if fields["lifecycle_status"] not in LIFECYCLE_STATUSES:
            errors.append(
                f"{asset_id} lifecycle_status 无效：{fields['lifecycle_status']}"
            )
        if fields["formal_use"] not in FORMAL_USES:
            errors.append(f"{asset_id} formal_use 无效：{fields['formal_use']}")

        for date_field in ("as_of", "last_reviewed"):
            if not parse_date(fields[date_field]):
                errors.append(f"{asset_id} {date_field} 不是 ISO 日期：{fields[date_field]}")

        id_date = asset_id.rsplit("-", 1)[0].rsplit("-", 1)[-1]
        if parse_date(fields["as_of"]) and fields["as_of"].replace("-", "") != id_date:
            warnings.append(f"{asset_id} 的 ID 日期与 as_of 不同")

        if fields["lifecycle_status"] == "superseded" and not fields.get("superseded_by"):
            errors.append(f"{asset_id} 已 superseded，但缺少 superseded_by")
        elif fields["lifecycle_status"] == "superseded":
            successor = fields["superseded_by"]
            if successor == asset_id:
                errors.append(f"{asset_id} superseded_by 不得自引用")
            elif successor not in all_ids:
                errors.append(f"{asset_id} 的后继资产不存在：{successor}")
        if fields["lifecycle_status"] == "active" and fields.get("superseded_by"):
            errors.append(f"{asset_id} 仍为 active，不得填写 superseded_by")

        folded_relative_path = normalized_path(relative_path)
        if folded_relative_path.startswith("research/") and (
            fields["authority"] != "non_authoritative_research"
            or fields["formal_use"] != "advisory_only"
        ):
            errors.append(
                f"{asset_id} 研究资料不得声称正式权威或直接落地：{relative_path}"
            )
        if folded_relative_path.startswith("drafts/") and fields["authority"] != "working_only":
            errors.append(f"{asset_id} 草案只能标记为 working_only：{relative_path}")
        if "v5" in relative_path.casefold() and (
            fields["lifecycle_status"] not in {"historical", "superseded"}
            or fields["formal_use"] != "never_formal"
        ):
            errors.append(f"{asset_id} v5 资料必须是历史状态且永不用作正式依据")

        refs = fields["decision_refs"]
        if refs not in {"—", "无"}:
            for decision_id in DECISION_RE.findall(refs):
                if decision_id not in decision_ids:
                    errors.append(f"{asset_id} 引用不存在的决策：{decision_id}")
            residue = DECISION_RE.sub("", refs).replace(",", "").replace("，", "").strip()
            if residue:
                errors.append(f"{asset_id} decision_refs 格式无效：{refs}")

        if (
            fields["lifecycle_status"] == "active"
            and fields["unresolved_conflicts"] not in {"无", "—"}
        ):
            warnings.append(f"{asset_id} 仍为 active，但存在未解决冲突")

        if parse_date(fields["as_of"]) and parse_date(fields["last_reviewed"]):
            if date.fromisoformat(fields["last_reviewed"]) < date.fromisoformat(fields["as_of"]):
                warnings.append(f"{asset_id} last_reviewed 早于 as_of")

    return errors, warnings, len(entries)


def render_text(errors: Sequence[str], warnings: Sequence[str], count: int) -> str:
    lines = [f"AI 团队工作流校验：{count} 个知识资产"]
    lines.extend(f"ERROR: {message}" for message in errors)
    lines.extend(f"WARNING: {message}" for message in warnings)
    if not errors:
        lines.append("PASS: 工作流文件、路径与知识边界通过校验")
    return "\n".join(lines)


def main(argv: Sequence[str] = ()) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".", help="项目根目录")
    parser.add_argument("--format", choices=("text", "json"), default="text")
    args = parser.parse_args(argv or None)

    root = Path(args.root)
    if not root.exists() or not root.is_dir():
        print(f"调用错误：项目根目录不存在：{root}", file=sys.stderr)
        return 2

    errors, warnings, count = validate(root)
    if args.format == "json":
        print(
            json.dumps(
                {"count": count, "errors": errors, "warnings": warnings},
                ensure_ascii=False,
                indent=2,
            )
        )
    else:
        print(render_text(errors, warnings, count))
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
