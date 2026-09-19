#!/usr/bin/env python3
"""Compile the R16.2 multi-sheet workbook into deterministic runtime JSON.

The repository intentionally keeps the author workbook as the source of truth and
does not make Godot parse XLSX at runtime.  This module uses only the Python
standard library so the same validation can run in CI without openpyxl.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
import zipfile
from pathlib import Path
from typing import Any, Iterable
from xml.etree import ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SOURCE = ROOT / "docs/r16_2/source/雾港来信_R16.2_程序接入表.xlsx"
DEFAULT_OUTPUT = ROOT / "content/程序生成_请勿手改/r16_2_runtime.json"
COMPILER_VERSION = "r16.2-compiler-1"

NS_MAIN = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
NS_REL = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
NS_PACKAGE_REL = "http://schemas.openxmlformats.org/package/2006/relationships"

SHEET_INDEX_KEYS = {
    "Nodes": "node_id",
    "Choices": "choice_id",
    "StateDictionary": "state_key",
    "Knowledge_Permissions": "key",
    "ArticleVersions": "version_id",
    "Snapshots": "snapshot_id",
    "Endings": "ending_id",
    "MicroPuzzles": "puzzle_id",
    "PuzzleVariants": None,
    "AutoArticleRules": "rule_id",
    "UI_Interactions": "interaction_id",
    "Chapters": "chapter_id",
    "ScrapbookRules": "issue_id",
    "Hint_IAA": None,
    "DesignReferences": None,
    "NewspaperRenderSpec": None,
    "InterviewNotebookSpec": None,
    "EndingMontageRules": "shot_id",
    "ChoiceEchoMatrix": "choice_unit",
    "RuntimeContract": None,
    "ConditionDSL": None,
    "ImportChecklist": None,
}

RESERVED_CONDITION_KEYS = {
    "ELSE",
    "else",
    "if",
    "then",
    "apply",
    "RULESET",
    "EndingID",
}

ALLOWED_NODE_TYPES = {
    "scene",
    "prologue",
    "auto_build",
    "draft_preview",
    "timeline_reconstruction",
}


class CompileFailure(Exception):
    """Raised for deterministic source/contract errors."""


def _local_name(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def _column_index(reference: str) -> int:
    letters = re.match(r"([A-Z]+)", reference.upper())
    if not letters:
        return 0
    result = 0
    for char in letters.group(1):
        result = result * 26 + ord(char) - ord("A") + 1
    return result


def _xml_text(element: ET.Element | None) -> str:
    if element is None:
        return ""
    return "".join(element.itertext())


class XlsxReader:
    """Small, deterministic XLSX reader for the tabular source workbook."""

    def __init__(self, path: Path) -> None:
        self.path = path
        self.shared_strings: list[str] = []
        self.sheets: dict[str, str] = {}

    def load(self) -> dict[str, list[list[Any]]]:
        if not self.path.is_file():
            raise CompileFailure(f"source workbook not found: {self.path}")
        with zipfile.ZipFile(self.path) as archive:
            self._load_shared_strings(archive)
            self._load_sheet_map(archive)
            result: dict[str, list[list[Any]]] = {}
            for name, target in self.sheets.items():
                result[name] = self._load_sheet(archive, target)
            return result

    def _load_shared_strings(self, archive: zipfile.ZipFile) -> None:
        try:
            raw = archive.read("xl/sharedStrings.xml")
        except KeyError:
            return
        root = ET.fromstring(raw)
        for item in root:
            if _local_name(item.tag) == "si":
                self.shared_strings.append(_xml_text(item))

    def _load_sheet_map(self, archive: zipfile.ZipFile) -> None:
        workbook = ET.fromstring(archive.read("xl/workbook.xml"))
        relationships = ET.fromstring(archive.read("xl/_rels/workbook.xml.rels"))
        rel_targets: dict[str, str] = {}
        for relationship in relationships:
            if _local_name(relationship.tag) != "Relationship":
                continue
            rel_id = relationship.attrib.get("Id", "")
            target = relationship.attrib.get("Target", "")
            if target.startswith("/"):
                target = target[1:]
            elif not target.startswith("xl/"):
                target = f"xl/{target}"
            rel_targets[rel_id] = target
        for sheet in workbook.iter():
            if _local_name(sheet.tag) != "sheet":
                continue
            name = sheet.attrib.get("name", "")
            rel_id = sheet.attrib.get(f"{{{NS_REL}}}id", "")
            target = rel_targets.get(rel_id)
            if name and target:
                self.sheets[name] = target

    def _load_sheet(self, archive: zipfile.ZipFile, target: str) -> list[list[Any]]:
        root = ET.fromstring(archive.read(target))
        rows: dict[int, dict[int, Any]] = {}
        max_row = 0
        max_col = 0
        for row in root.iter():
            if _local_name(row.tag) != "row":
                continue
            row_index = int(row.attrib.get("r", "0") or 0)
            if row_index <= 0:
                continue
            values: dict[int, Any] = {}
            for cell in row:
                if _local_name(cell.tag) != "c":
                    continue
                col = _column_index(cell.attrib.get("r", ""))
                if col <= 0:
                    continue
                value_node = next((child for child in cell if _local_name(child.tag) == "v"), None)
                inline_node = next((child for child in cell if _local_name(child.tag) == "is"), None)
                cell_type = cell.attrib.get("t", "")
                if cell_type == "inlineStr":
                    value: Any = _xml_text(inline_node)
                else:
                    raw = _xml_text(value_node)
                    if cell_type == "s" and raw:
                        index = int(float(raw))
                        value = self.shared_strings[index] if index < len(self.shared_strings) else ""
                    elif cell_type == "b":
                        value = raw == "1"
                    else:
                        value = raw
                values[col] = value
                max_col = max(max_col, col)
            rows[row_index] = values
            max_row = max(max_row, row_index)
        result: list[list[Any]] = []
        for row_index in range(1, max_row + 1):
            values = rows.get(row_index, {})
            result.append([values.get(col, "") for col in range(1, max_col + 1)])
        return result


def _coerce_value(value: Any, header: str) -> Any:
    if value is None:
        return ""
    if isinstance(value, bool):
        return value
    text = str(value).replace("\r\n", "\n").replace("\r", "\n").strip()
    if not text:
        return ""
    numeric_headers = {
        "Order",
        "Priority",
        "MaxSteps",
        "MaxDuration",
        "AcquiredAt",
        "HiddenCount",
        "Expected",
        "Actual/Formula",
        "Status",
        "Default",
    }
    if header in numeric_headers:
        if re.fullmatch(r"-?\d+", text):
            return int(text)
        if re.fullmatch(r"-?(?:\d+\.\d*|\d*\.\d+)", text):
            return float(text)
    return text


def _snake_case(header: str) -> str:
    clean = str(header).strip()
    clean = clean.replace("/", "_").replace("\\", "_")
    clean = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", clean)
    clean = re.sub(r"[^0-9A-Za-z_]+", "_", clean)
    clean = re.sub(r"_+", "_", clean).strip("_")
    return clean.lower() or "column"


def _rows_from_matrix(matrix: list[list[Any]]) -> list[dict[str, Any]]:
    if not matrix:
        return []
    raw_headers = [str(v).strip() for v in matrix[0]]
    while raw_headers and not raw_headers[-1]:
        raw_headers.pop()
    if not raw_headers or not any(raw_headers):
        return []
    headers: list[str] = []
    seen: dict[str, int] = {}
    for index, header in enumerate(raw_headers):
        base = header or f"column_{index + 1}"
        count = seen.get(base, 0)
        seen[base] = count + 1
        headers.append(base if count == 0 else f"{base}_{count + 1}")
    result: list[dict[str, Any]] = []
    for row in matrix[1:]:
        values = list(row[: len(headers)]) + [""] * max(0, len(headers) - len(row))
        if not any(str(value).strip() for value in values):
            continue
        result.append({header: _coerce_value(values[i], header) for i, header in enumerate(headers)})
    return result


def _canonical_rows(rows: Iterable[dict[str, Any]]) -> list[dict[str, Any]]:
    result: list[dict[str, Any]] = []
    for row in rows:
        canonical: dict[str, Any] = {}
        for key, value in row.items():
            canonical[_snake_case(key)] = value
        result.append(canonical)
    return result


def _index_rows(rows: list[dict[str, Any]], key: str | None, sheet: str, errors: list[str]) -> dict[str, dict[str, Any]]:
    if key is None:
        return {}
    indexed: dict[str, dict[str, Any]] = {}
    for row in rows:
        value = str(row.get(key, "")).strip()
        if not value:
            errors.append(f"{sheet}: blank primary key {key}")
            continue
        if value in indexed:
            errors.append(f"{sheet}: duplicate primary key {value}")
            continue
        indexed[value] = row
    return indexed


def _split_operations(text: str) -> list[str]:
    result: list[str] = []
    start = 0
    depth = 0
    for index, char in enumerate(text):
        if char in "({":
            depth += 1
        elif char in ")}":
            depth = max(0, depth - 1)
        elif char == ";" and depth == 0:
            result.append(text[start:index].strip())
            start = index + 1
    result.append(text[start:].strip())
    return [item for item in result if item]


def _condition_keys(expression: str) -> set[str]:
    if not expression:
        return set()
    clean = re.sub(r"(['\"]).*?\1", "", expression)
    pattern = re.compile(r"\b([A-Za-z_][A-Za-z0-9_.]*)\s*(?:(?:!=|>=|<=|=|>|<)|\bIN\b|\bSET\b)")
    return set(pattern.findall(clean))


def _mutation_keys(expression: str) -> set[str]:
    if not expression:
        return set()
    keys: set[str] = set()
    for operation in _split_operations(expression):
        operation = re.sub(r"^\s*(?:if|else\s+if|else)\b.*?=>\s*", "", operation, flags=re.I)
        match = re.match(r"\s*([A-Za-z_][A-Za-z0-9_.]*)\s*(?:\+=|-=|=)", operation)
        if match:
            keys.add(match.group(1))
    return keys


def _state_default(state_type: str, raw: Any) -> Any:
    text = str(raw or "").strip()
    if state_type == "bool":
        return text.lower() in {"1", "true", "yes"}
    if state_type == "int":
        try:
            return int(text)
        except ValueError:
            return 0
    if state_type == "float":
        try:
            return float(text)
        except ValueError:
            return 0.0
    if state_type == "set":
        return []
    return text


def _enum_values(row: dict[str, Any]) -> set[str]:
    meaning = str(row.get("meaning", ""))
    return {item.strip() for item in meaning.split("|") if item.strip()}


class _DslSyntaxError(ValueError):
    """Raised when a ConditionDSL expression cannot be parsed completely."""


_DSL_TOKEN_RE = re.compile(
    r"(?:>=|<=|!=|=|>|<|[(),{}]|\"(?:\\.|[^\"])*\"|“[^”]*”|"
    r"[A-Za-z_][A-Za-z0-9_.-]*|-?(?:\d+\.\d*|\d*\.\d+|\d+))"
)


def _dsl_tokens(text: str) -> list[str]:
    """Tokenize DSL while rejecting every unrecognized character."""
    tokens: list[str] = []
    position = 0
    while position < len(text):
        if text[position].isspace():
            position += 1
            continue
        match = _DSL_TOKEN_RE.match(text, position)
        if match is None:
            raise _DslSyntaxError(f"unexpected token near {text[position:position + 20]!r}")
        tokens.append(match.group(0))
        position = match.end()
    return tokens


class _ConditionParser:
    """Small recursive-descent parser for the R16.2 condition grammar."""

    def __init__(self, expression: str, states: dict[str, dict[str, Any]], location: str) -> None:
        self.expression = expression
        self.states = states
        self.location = location
        self.tokens = _dsl_tokens(expression)
        self.index = 0
        self.errors: list[str] = []

    def parse(self) -> list[str]:
        if not self.tokens:
            raise _DslSyntaxError("empty condition")
        self._parse_or()
        if self.index != len(self.tokens):
            raise _DslSyntaxError(f"unexpected token {self.tokens[self.index]!r}")
        return self.errors

    def _peek(self) -> str | None:
        return self.tokens[self.index] if self.index < len(self.tokens) else None

    def _take(self) -> str:
        token = self._peek()
        if token is None:
            raise _DslSyntaxError("unexpected end of condition")
        self.index += 1
        return token

    def _accept_keyword(self, keyword: str) -> bool:
        token = self._peek()
        if token is not None and token.upper() == keyword:
            self.index += 1
            return True
        return False

    def _parse_or(self) -> None:
        self._parse_and()
        while self._accept_keyword("OR"):
            self._parse_and()

    def _parse_and(self) -> None:
        self._parse_primary()
        while self._accept_keyword("AND"):
            self._parse_primary()

    def _parse_primary(self) -> None:
        if self._peek() == "(":
            self._take()
            self._parse_or()
            if self._take() != ")":
                raise _DslSyntaxError("missing closing parenthesis")
            return
        key = self._take()
        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_.-]*", key):
            raise _DslSyntaxError(f"expected state key, got {key!r}")
        operator = self._take()
        if operator.upper() == "IN":
            if self._take() != "{":
                raise _DslSyntaxError("IN must be followed by a set literal")
            values: list[str] = []
            if self._peek() != "}":
                while True:
                    values.append(self._take())
                    if self._peek() != ",":
                        break
                    self._take()
            if self._take() != "}":
                raise _DslSyntaxError("missing closing brace in IN expression")
            if not values:
                raise _DslSyntaxError("IN set must contain at least one value")
            self._validate_key(key, values)
            return
        if operator.upper() == "SET":
            self._validate_key(key, [])
            return
        if operator not in {"=", "!=", ">=", "<=", ">", "<"}:
            raise _DslSyntaxError(f"unknown condition operator {operator!r}")
        value = self._take()
        if value in {"(", ")", "{", "}", ","} or value.upper() in {"AND", "OR", "IN", "SET"}:
            raise _DslSyntaxError(f"expected comparison value, got {value!r}")
        self._validate_key(key, [value])

    def _validate_key(self, key: str, values: list[str]) -> None:
        if key == "EndingID":
            return
        state = self.states.get(key)
        if state is None:
            self.errors.append(f"{self.location}: unknown condition key {key}")
            return
        state_type = str(state.get("type", ""))
        allowed = _enum_values(state) if state_type == "enum" else set()
        for raw in values:
            value = raw.strip('"').strip("“”")
            if state_type == "enum" and allowed and value not in allowed:
                self.errors.append(
                    f"{self.location}: invalid enum value {key}={value}; allowed {sorted(allowed)}"
                )
            if state_type == "bool" and value.lower() not in {"0", "1", "true", "false"}:
                self.errors.append(f"{self.location}: bool {key} expects 0/1/true/false, got {value}")
            if state_type == "int" and not re.fullmatch(r"-?\d+", value):
                self.errors.append(f"{self.location}: int {key} expects an integer, got {value}")
            if state_type == "float" and not re.fullmatch(r"-?(?:\d+\.\d*|\d*\.\d+|\d+)", value):
                self.errors.append(f"{self.location}: float {key} expects a number, got {value}")


def _validate_condition_expression(
    expression: str,
    location: str,
    states: dict[str, dict[str, Any]],
    errors: list[str],
    *,
    allow_always: bool = False,
) -> None:
    clean = str(expression or "").strip()
    if not clean:
        return
    if allow_always and clean.lower() == "always":
        return
    # The workbook uses a descriptive suffix on the fallback row (for example
    # "ELSE（E03/E04/E02 均未命中）").  It is still an explicit fallback token.
    if clean.upper().startswith("ELSE"):
        return
    try:
        errors.extend(_ConditionParser(clean, states, location).parse())
    except _DslSyntaxError as exc:
        errors.append(f"{location}: invalid ConditionDSL: {exc}")


def _validate_mutation_value(
    key: str,
    operator: str,
    raw_value: str,
    location: str,
    states: dict[str, dict[str, Any]],
    errors: list[str],
) -> None:
    state = states.get(key)
    if state is None:
        if key != "EndingID":
            errors.append(f"{location}: unknown mutation key {key}")
        return
    value = raw_value.strip().strip('"').strip("“”")
    state_type = str(state.get("type", ""))
    if operator in {"+=", "-="}:
        if operator == "+=" and state_type not in {"set", "int", "float"}:
            errors.append(f"{location}: {operator} is not valid for {state_type} state {key}")
        if operator == "-=" and state_type not in {"int", "float"}:
            errors.append(f"{location}: -= is not valid for {state_type} state {key}")
    if state_type == "enum" and _enum_values(state) and value not in _enum_values(state):
        errors.append(f"{location}: invalid enum value {key}={value}; allowed {sorted(_enum_values(state))}")
    if state_type == "bool" and value.lower() not in {"0", "1", "true", "false"}:
        errors.append(f"{location}: bool {key} expects 0/1/true/false, got {value}")
    if state_type == "int" and not re.fullmatch(r"-?\d+", value):
        errors.append(f"{location}: int {key} expects an integer, got {value}")
    if state_type == "float" and not re.fullmatch(r"-?(?:\d+\.\d*|\d*\.\d+|\d+)", value):
        errors.append(f"{location}: float {key} expects a number, got {value}")


def _validate_assignment(
    operation: str,
    location: str,
    states: dict[str, dict[str, Any]],
    errors: list[str],
) -> None:
    match = re.fullmatch(
        r"\s*([A-Za-z_][A-Za-z0-9_.-]*)\s*(\+=|-=|=)\s*(\"(?:\\.|[^\"])*\"|“[^”]*”|[^\s;]+)\s*",
        operation,
    )
    if match is None:
        errors.append(f"{location}: invalid mutation syntax {operation!r}")
        return
    _validate_mutation_value(match.group(1), match.group(2), match.group(3), location, states, errors)


def _validate_mutation_expression(
    expression: str,
    location: str,
    states: dict[str, dict[str, Any]],
    errors: list[str],
) -> None:
    for index, operation in enumerate(_split_operations(str(expression or "")), start=1):
        if not operation:
            continue
        operation_location = f"{location} operation {index}"
        clean = operation.strip()
        if clean.startswith("apply "):
            if clean != "apply AutoArticleRules":
                errors.append(f"{operation_location}: unknown ruleset {clean[6:]!r}")
            continue
        # Authoring-only display/dispatch annotations are deliberately limited
        # to the two explicit forms present in the R16.2 workbook.
        if clean.startswith("choices "):
            marker = " when "
            if marker in clean:
                _validate_condition_expression(clean.split(marker, 1)[1].strip(), operation_location, states, errors)
            continue
        arrow = clean.find("=>")
        if arrow >= 0:
            prefix = clean[:arrow].strip()
            body = clean[arrow + 2 :].strip()
            if prefix == "else":
                pass
            elif prefix.startswith("if "):
                _validate_condition_expression(prefix[3:].strip(), operation_location, states, errors)
            elif prefix.startswith("else if "):
                _validate_condition_expression(prefix[8:].strip(), operation_location, states, errors)
            else:
                errors.append(f"{operation_location}: invalid conditional mutation prefix {prefix!r}")
            if body.startswith("launch "):
                if not re.fullmatch(r"launch [A-Za-z_][A-Za-z0-9_.-]*", body):
                    errors.append(f"{operation_location}: invalid launch directive {body!r}")
            elif body.startswith("choices "):
                continue
            else:
                _validate_assignment(body, operation_location, states, errors)
            continue
        _validate_assignment(clean, operation_location, states, errors)


def _validate_contract(raw: dict[str, list[dict[str, Any]]]) -> tuple[list[str], list[str], dict[str, dict[str, Any]]]:
    errors: list[str] = []
    warnings: list[str] = []
    canonical: dict[str, list[dict[str, Any]]] = {name: _canonical_rows(rows) for name, rows in raw.items()}
    indexed: dict[str, dict[str, dict[str, Any]]] = {}
    for sheet, rows in canonical.items():
        indexed[sheet] = _index_rows(rows, SHEET_INDEX_KEYS.get(sheet), sheet, errors)

    nodes = indexed.get("Nodes", {})
    choices = indexed.get("Choices", {})
    snapshots = indexed.get("Snapshots", {})
    states = indexed.get("StateDictionary", {})

    for node_id, node in nodes.items():
        node_type = str(node.get("node_type", ""))
        if node_type not in ALLOWED_NODE_TYPES:
            errors.append(f"Nodes[{node_id}]: unsupported NodeType {node_type!r}")
        next_node = str(node.get("next_node", "")).strip()
        if next_node and next_node not in nodes and next_node != "ENDING_ROUTER":
            errors.append(f"Nodes[{node_id}]: dangling NextNode {next_node}")
        snapshot = str(node.get("rollback_snapshot", "")).strip()
        if snapshot and snapshot not in snapshots:
            errors.append(f"Nodes[{node_id}]: unknown RollbackSnapshot {snapshot}")

    for choice_id, choice in choices.items():
        node_id = str(choice.get("node_id", "")).strip()
        next_node = str(choice.get("next_node", "")).strip()
        snapshot = str(choice.get("snapshot_id", "")).strip()
        if node_id not in nodes:
            errors.append(f"Choices[{choice_id}]: unknown NodeID {node_id}")
        if next_node and next_node not in nodes and next_node != "ENDING_ROUTER":
            errors.append(f"Choices[{choice_id}]: dangling NextNode {next_node}")
        if snapshot and snapshot not in snapshots:
            errors.append(f"Choices[{choice_id}]: unknown SnapshotID {snapshot}")

    for snapshot_id, snapshot in snapshots.items():
        target = str(snapshot.get("restore_target", "")).strip()
        if target and target not in nodes:
            errors.append(f"Snapshots[{snapshot_id}]: unknown RestoreTarget {target}")

    allowed_state_types = {"bool", "enum", "set", "int", "float", "string"}
    for key, state in states.items():
        state_type = str(state.get("type", "")).strip()
        scope = str(state.get("rollback_scope", "")).strip()
        if state_type not in allowed_state_types:
            errors.append(f"StateDictionary[{key}]: unsupported Type {state_type!r}")
        if scope not in {"story", "global"}:
            errors.append(f"StateDictionary[{key}]: unsupported RollbackScope {scope!r}")
        if state_type == "enum" and not _enum_values(state):
            errors.append(f"StateDictionary[{key}]: enum has no allowed values")
        if state_type == "enum":
            default = str(state.get("default", "")).strip()
            if default and default not in _enum_values(state):
                errors.append(
                    f"StateDictionary[{key}]: default {default!r} is not in {sorted(_enum_values(state))}"
                )

    # All condition and mutation references must point at typed state keys.  A
    # small whitelist covers the workbook's explicit router/puzzle sentinels.
    condition_fields = [
        ("Nodes", "preconditions"),
        ("Choices", "preconditions"),
        ("Endings", "condition"),
        ("AutoArticleRules", "condition"),
        ("PuzzleVariants", "condition"),
        ("ScrapbookRules", "condition"),
        ("EndingMontageRules", "condition"),
    ]
    mutation_fields = [
        ("Nodes", "on_enter"),
        ("Choices", "set_flags"),
        ("Choices", "clear_flags"),
        ("Choices", "promise_change"),
        ("Choices", "knowledge_change"),
        ("Choices", "article_state_change"),
        ("Endings", "global_unlock"),
    ]
    for sheet, field in condition_fields:
        for row in canonical.get(sheet, []):
            raw_expression = str(row.get(field, "") or "")
            row_id = next((str(row.get(k, "")) for k in ("node_id", "choice_id", "ending_id", "rule_id", "puzzle_id", "issue_id", "shot_id") if row.get(k)), "?")
            _validate_condition_expression(
                raw_expression,
                f"{sheet}[{row_id}].{field}",
                states,
                errors,
                allow_always=sheet == "ScrapbookRules",
            )
            for key in _condition_keys(raw_expression):
                if key not in states and key not in RESERVED_CONDITION_KEYS:
                    errors.append(f"{sheet}[{row_id}].{field}: unknown condition key {key}")
    for sheet, field in mutation_fields:
        for row in canonical.get(sheet, []):
            raw_expression = str(row.get(field, "") or "")
            row_id = next((str(row.get(k, "")) for k in ("node_id", "choice_id", "ending_id") if row.get(k)), "?")
            _validate_mutation_expression(raw_expression, f"{sheet}[{row_id}].{field}", states, errors)
            for key in _mutation_keys(raw_expression):
                if key not in states:
                    errors.append(f"{sheet}[{row_id}].{field}: unknown mutation key {key}")

    # Validate enum assignments and equality tests where the value is static.
    enum_allowed = {key: _enum_values(row) for key, row in states.items() if row.get("type") == "enum"}
    all_dsl_texts: list[tuple[str, str, str]] = []
    for sheet, field in condition_fields + mutation_fields:
        for row in canonical.get(sheet, []):
            row_id = next((str(row.get(k, "")) for k in ("node_id", "choice_id", "ending_id", "rule_id", "puzzle_id", "issue_id", "shot_id") if row.get(k)), "?")
            value = str(row.get(field, "") or "")
            if value:
                all_dsl_texts.append((f"{sheet}[{row_id}].{field}", value, field))
    for location, expression, field in all_dsl_texts:
        for key, value in re.findall(r"\b([A-Za-z_][A-Za-z0-9_.]*)\s*(?:=|=>)\s*([A-Za-z_][A-Za-z0-9_.]*)", expression):
            if key in enum_allowed and value not in enum_allowed[key] and value not in {"ELSE", "else"}:
                errors.append(f"{location}: invalid enum value {key}={value}; allowed {sorted(enum_allowed[key])}")
        for key, values in re.findall(r"\b([A-Za-z_][A-Za-z0-9_.]*)\s+IN\s*\{([^}]*)\}", expression):
            if key in enum_allowed:
                for value in values.split(","):
                    clean = value.strip()
                    if clean and clean not in enum_allowed[key]:
                        errors.append(f"{location}: invalid enum value {key} IN {{{clean}}}")

    # Contract-level invariants from the R16.2 acceptance plan.
    unit_ids = {str(row.get("unit_id", "")) for row in canonical.get("Nodes", [])}
    expected_units = {f"U{i:02d}" for i in range(1, 33)}
    missing_units = sorted(expected_units - unit_ids)
    if missing_units:
        errors.append(f"Nodes: missing UnitID(s): {', '.join(missing_units)}")
    if len(choices) != 66:
        warnings.append(f"Choices: source currently contains {len(choices)} rows; acceptance plan expects 66")
    if "D00" not in nodes:
        errors.append("Nodes: missing cold-open node D00")
    if "D65-B" not in nodes or "D65-C" not in nodes:
        errors.append("Nodes: missing D65-B/D65-C auto-build/preview nodes")
    if "SS_U32_FINAL" not in snapshots:
        errors.append("Snapshots: missing SS_U32_FINAL")
    if "P_U15_CHAIN" not in indexed.get("MicroPuzzles", {}):
        errors.append("MicroPuzzles: missing P_U15_CHAIN")
    if "P_U27_PROOF" not in indexed.get("MicroPuzzles", {}):
        errors.append("MicroPuzzles: missing P_U27_PROOF")
    ending_priorities = [str(row.get("priority", "")) for row in canonical.get("Endings", [])]
    if len(ending_priorities) != len(set(ending_priorities)):
        errors.append("Endings: duplicate priority; router order would be ambiguous")

    return errors, warnings, indexed


def compile_workbook(source: Path) -> dict[str, Any]:
    raw_matrices = XlsxReader(source).load()
    raw_rows = {name: _rows_from_matrix(matrix) for name, matrix in raw_matrices.items()}
    errors, warnings, indexed = _validate_contract(raw_rows)
    if errors:
        raise CompileFailure("\n".join(errors))

    source_hash = hashlib.sha256(source.read_bytes()).hexdigest()
    rows = {name: _canonical_rows(values) for name, values in raw_rows.items()}
    data: dict[str, Any] = {
        "schema_version": "r16.2",
        "compiler": {
            "name": "tools/r16_2_compile.py",
            "version": COMPILER_VERSION,
            "source": "docs/r16_2/source/雾港来信_R16.2_程序接入表.xlsx",
            "source_sha256": source_hash,
        },
        "meta": {
            "title": "《雾港来信》R16.2",
            "engine": "Godot 4.7",
            "start_node": "D00",
            "ending_router": "ENDING_ROUTER",
            "chapters": ["CH1", "CH2", "CH3", "CH4"],
            "choice_count": len(rows.get("Choices", [])),
        },
        "validation": {"errors": [], "warnings": warnings},
        "sheets": rows,
    }

    for sheet, key in SHEET_INDEX_KEYS.items():
        if key:
            data_key = _snake_case(sheet)
            # Keep indexed maps for runtime lookup, while retaining the raw
            # sheet-shaped arrays for author/debug tooling.
            data[data_key] = indexed.get(sheet, {})
        else:
            # Non-indexed reference/specification sheets are still part of the
            # generated runtime contract.  Preserve them as deterministic
            # arrays instead of silently dropping them during compilation.
            data[_snake_case(sheet)] = rows.get(sheet, [])
    # Friendly aliases used by the runtime.  These are references to the same
    # logical rows, not a second authoring source.
    aliases = {
        "nodes": "nodes",
        "choices": "choices",
        "states": "state_dictionary",
        "snapshots": "snapshots",
        "endings": "endings",
        "micro_puzzles": "micro_puzzles",
        "puzzle_variants": "puzzle_variants",
        "article_rules": "auto_article_rules",
        "chapters": "chapters",
        "ui_interactions": "ui_interactions",
        "newspaper_spec": "newspaper_render_spec",
        "notebook_spec": "interview_notebook_spec",
        "montage_rules": "ending_montage_rules",
        "scrapbook_rules": "scrapbook_rules",
        "knowledge_permissions": "knowledge_permissions",
    }
    for target, source_key in aliases.items():
        if source_key in data:
            data[target] = data[source_key]
        elif source_key in rows:
            data[target] = rows[source_key]
    return data


def _write_json(output: Path, data: dict[str, Any]) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(data, ensure_ascii=False, sort_keys=True, indent=2) + "\n"
    output.write_text(payload, encoding="utf-8")


def _parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--check", action="store_true", help="validate and compare deterministic output without writing")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv or sys.argv[1:])
    source = args.source if args.source.is_absolute() else ROOT / args.source
    output = args.output if args.output.is_absolute() else ROOT / args.output
    try:
        data = compile_workbook(source)
        if args.check:
            if not output.is_file():
                raise CompileFailure(f"deterministic output missing: {output}")
            existing = json.loads(output.read_text(encoding="utf-8"))
            if existing != data:
                raise CompileFailure(f"deterministic output differs from source: {output}")
            print(f"PASS: R16.2 workbook valid; deterministic output matches ({len(data['choices'])} choices, {len(data['nodes'])} nodes)")
        else:
            _write_json(output, data)
            print(f"WROTE: {output} ({len(data['choices'])} choices, {len(data['nodes'])} nodes)")
        return 0
    except (CompileFailure, OSError, KeyError, ValueError, ET.ParseError) as exc:
        print(f"R16.2 compile failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
