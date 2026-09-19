#!/usr/bin/env python3
"""Validate the generated R16.2 runtime JSON without editing it."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

import r16_2_compile


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = ROOT / "content/程序生成_请勿手改/r16_2_runtime.json"
DEFAULT_MANIFEST = ROOT / "docs/r16_2/handoff/07_PACKAGE_MANIFEST.json"


def validate_source_manifest(path: Path = DEFAULT_MANIFEST) -> list[str]:
    errors: list[str] = []
    if not path.is_file():
        return [f"package manifest not found: {path}"]
    try:
        manifest = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return [f"cannot read package manifest: {exc}"]
    for entry in manifest.get("source_files", []):
        relative = str(entry.get("path", ""))
        source = ROOT / "docs/r16_2" / relative
        if not source.is_file():
            errors.append(f"manifest source missing: {relative}")
            continue
        digest = hashlib.sha256(source.read_bytes()).hexdigest()
        if digest != str(entry.get("sha256", "")):
            errors.append(f"manifest hash mismatch: {relative}")
        expected_size = entry.get("size")
        if expected_size is not None and source.stat().st_size != int(expected_size):
            errors.append(f"manifest size mismatch: {relative}")
    return errors


def validate_json(path: Path) -> list[str]:
    errors: list[str] = []
    if not path.is_file():
        return [f"generated runtime JSON not found: {path}"]
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return [f"cannot read generated runtime JSON: {exc}"]

    required = {
        "schema_version",
        "compiler",
        "meta",
        "nodes",
        "choices",
        "states",
        "snapshots",
        "micro_puzzles",
        "puzzle_variants",
        "article_rules",
        "article_versions",
        "newspaper_spec",
        "condition_dsl",
        "endings",
        "ui_interactions",
    }
    errors.extend(f"missing top-level key: {key}" for key in sorted(required - set(data)))
    if data.get("schema_version") != "r16.2":
        errors.append("schema_version must be r16.2")
    meta = data.get("meta", {})
    if meta.get("start_node") != "D00":
        errors.append("meta.start_node must be D00")
    if meta.get("ending_router") != "ENDING_ROUTER":
        errors.append("meta.ending_router must be ENDING_ROUTER")

    nodes = data.get("nodes", {})
    choices = data.get("choices", {})
    snapshots = data.get("snapshots", {})
    states = data.get("states", {})
    if len(nodes) != 36:
        errors.append(f"expected 36 nodes, got {len(nodes)}")
    if len(choices) != 66:
        errors.append(f"expected 66 choices, got {len(choices)}")
    if not isinstance(data.get("puzzle_variants"), list) or not data.get("puzzle_variants"):
        errors.append("puzzle_variants must be a non-empty array")
    if not isinstance(data.get("newspaper_spec"), list) or not data.get("newspaper_spec"):
        errors.append("newspaper_spec must be a non-empty array")
    for node_id, node in nodes.items():
        nxt = str(node.get("next_node", ""))
        if nxt and nxt not in nodes and nxt != "ENDING_ROUTER":
            errors.append(f"{node_id}: dangling next_node {nxt}")
    for choice_id, choice in choices.items():
        if choice.get("node_id") not in nodes:
            errors.append(f"{choice_id}: choice node missing")
        nxt = str(choice.get("next_node", ""))
        if nxt and nxt not in nodes and nxt != "ENDING_ROUTER":
            errors.append(f"{choice_id}: dangling next_node {nxt}")
        snapshot = str(choice.get("snapshot_id", ""))
        if snapshot and snapshot not in snapshots:
            errors.append(f"{choice_id}: dangling snapshot {snapshot}")
    if "SS_U15_CHAIN" not in snapshots or "SS_U28_PREVIEW" not in snapshots or "SS_U32_FINAL" not in snapshots:
        errors.append("required puzzle/preview/final snapshots are incomplete")

    for key, state in states.items():
        if state.get("rollback_scope") not in {"story", "global"}:
            errors.append(f"state {key}: invalid rollback_scope")
        if state.get("type") not in {"bool", "enum", "set", "int", "float", "string"}:
            errors.append(f"state {key}: invalid type")

    interactions = data.get("ui_interactions", {})
    expected_steps = {
        "I_U08_HEADLINE": 2,
        "I_U15_CHAIN": 1,
        "I_U27_PROOF": 1,
        "I_U28_FINAL": 3,
    }
    for interaction_id, steps in expected_steps.items():
        row = interactions.get(interaction_id)
        if not row:
            errors.append(f"missing UI interaction {interaction_id}")
        elif int(row.get("max_steps", -1)) != steps:
            errors.append(f"{interaction_id}: expected MaxSteps {steps}")

    endings = data.get("endings", {})
    priorities = {str(row.get("priority")): ending_id for ending_id, row in endings.items()}
    if len(priorities) != len(endings):
        errors.append("ending priorities must be unique")
    if [ending_id for _, ending_id in sorted((int(row.get("priority", 999)), ending_id) for ending_id, row in endings.items())] != ["E03", "E04", "E02", "E01"]:
        errors.append("ending priority must be E03 -> E04 -> E02 -> E01")

    return errors


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args(argv or sys.argv[1:])
    output = args.output if args.output.is_absolute() else ROOT / args.output
    errors = validate_source_manifest()
    errors.extend(validate_json(output))
    # Also re-run source validation and deterministic comparison.  This catches
    # a hand-edited generated file even when its JSON shape still looks valid.
    try:
        expected = r16_2_compile.compile_workbook(r16_2_compile.DEFAULT_SOURCE)
        actual = json.loads(output.read_text(encoding="utf-8"))
        if actual != expected:
            errors.append("generated JSON does not match deterministic workbook compilation")
    except Exception as exc:  # keep a concise actionable validator failure
        errors.append(f"source compilation failed: {exc}")
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("PASS: R16.2 source manifest, runtime JSON structure, route references, UI limits, ending order, and source determinism")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
