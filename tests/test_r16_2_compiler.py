from __future__ import annotations

import json
import re
import unittest
from pathlib import Path

import tools.r16_2_compile as compiler


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "content/程序生成_请勿手改/r16_2_runtime.json"


class R162CompilerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.data = compiler.compile_workbook(compiler.DEFAULT_SOURCE)
        cls.generated = json.loads(OUTPUT.read_text(encoding="utf-8"))

    def test_generated_output_is_deterministic(self) -> None:
        self.assertEqual(self.data, self.generated)

    def test_primary_counts_and_ids(self) -> None:
        self.assertEqual(36, len(self.data["nodes"]))
        self.assertEqual(66, len(self.data["choices"]))
        self.assertEqual("D00", self.data["meta"]["start_node"])
        self.assertIn("D15-B", self.data["nodes"])
        self.assertIn("D65-B", self.data["nodes"])
        self.assertIn("D65-C", self.data["nodes"])

    def test_all_runtime_references_resolve(self) -> None:
        nodes = self.data["nodes"]
        snapshots = self.data["snapshots"]
        for node_id, node in nodes.items():
            next_node = str(node.get("next_node", ""))
            if next_node:
                self.assertTrue(next_node in nodes or next_node == "ENDING_ROUTER", (node_id, next_node))
            rollback = str(node.get("rollback_snapshot", ""))
            if rollback:
                self.assertIn(rollback, snapshots, node_id)
        for choice_id, choice in self.data["choices"].items():
            self.assertIn(choice["node_id"], nodes, choice_id)
            next_node = str(choice.get("next_node", ""))
            self.assertTrue(next_node in nodes or next_node == "ENDING_ROUTER", (choice_id, next_node))
            snapshot = str(choice.get("snapshot_id", ""))
            if snapshot:
                self.assertIn(snapshot, snapshots, choice_id)

    def test_state_keys_cover_conditions_and_mutations(self) -> None:
        states = set(self.data["states"])
        fields = (
            ("nodes", "preconditions"),
            ("nodes", "on_enter"),
            ("choices", "preconditions"),
            ("choices", "set_flags"),
            ("choices", "promise_change"),
            ("choices", "knowledge_change"),
            ("choices", "article_state_change"),
            ("endings", "condition"),
            ("article_rules", "condition"),
        )
        token = re.compile(r"\b([A-Za-z_][A-Za-z0-9_.]*)\s*(?:(?:!=|>=|<=|=|>|<)|\bIN\b|\bSET\b|\+=|-=)")
        reserved = {"ELSE", "else", "if", "EndingID"}
        for collection, field in fields:
            for row_id, row in self.data[collection].items():
                expression = str(row.get(field, ""))
                for key in token.findall(expression):
                    if key not in reserved:
                        self.assertIn(key, states, f"{collection}[{row_id}] {field} uses {key}")

    def test_special_interaction_and_ending_contract(self) -> None:
        interactions = self.data["ui_interactions"]
        self.assertEqual(2, interactions["I_U08_HEADLINE"]["max_steps"])
        self.assertEqual(1, interactions["I_U15_CHAIN"]["max_steps"])
        self.assertEqual(1, interactions["I_U27_PROOF"]["max_steps"])
        self.assertEqual(3, interactions["I_U28_FINAL"]["max_steps"])
        endings = self.data["endings"]
        ordered = [key for key, _ in sorted(endings.items(), key=lambda item: int(item[1]["priority"]))]
        self.assertEqual(["E03", "E04", "E02", "E01"], ordered)

    def test_reference_sheets_are_preserved_for_runtime(self) -> None:
        # Non-indexed authoring sheets must not disappear when the workbook is
        # compiled; the Godot runtime consumes puzzle variants and render specs.
        self.assertEqual(4, len(self.data["puzzle_variants"]))
        self.assertGreaterEqual(len(self.data["newspaper_spec"]), 1)
        self.assertGreaterEqual(len(self.data["condition_dsl"]), 1)

    def test_condition_and_mutation_dsl_reject_malformed_input(self) -> None:
        errors: list[str] = []
        compiler._validate_condition_expression("draft_main=FULL_NAMES AND", "TEST", self.data["states"], errors)
        self.assertTrue(any("invalid ConditionDSL" in message for message in errors), errors)
        errors.clear()
        compiler._validate_condition_expression("draft_main=NOT_A_ROUTE", "TEST", self.data["states"], errors)
        self.assertTrue(any("invalid enum value" in message for message in errors), errors)
        errors.clear()
        compiler._validate_mutation_expression("apply UnknownRules", "TEST", self.data["states"], errors)
        self.assertTrue(any("unknown ruleset" in message for message in errors), errors)

    def test_main_route_shape_reaches_router(self) -> None:
        """Follow the canonical first-choice path without executing story text."""
        nodes = self.data["nodes"]
        choices = self.data["choices"]
        current = "D00"
        visited: list[str] = []
        guard = 0
        while current != "ENDING_ROUTER" and guard < 100:
            guard += 1
            visited.append(current)
            node = nodes[current]
            if node["node_type"] == "timeline_reconstruction":
                current = node["next_node"]
                continue
            eligible = [row for row in choices.values() if row["node_id"] == current]
            if eligible:
                # D65-C has the explicit confirmation choice; D65 has the
                # first main preset. All other route nodes use their first row.
                selected = eligible[0]
                current = selected["next_node"]
            else:
                current = node["next_node"]
        self.assertLess(guard, 100)
        self.assertEqual("ENDING_ROUTER", current)
        self.assertIn("D00", visited)
        self.assertIn("D15-B", visited)
        self.assertIn("D65-B", visited)
        self.assertIn("D65-C", visited)
        self.assertIn("D69", visited)


if __name__ == "__main__":
    unittest.main()
