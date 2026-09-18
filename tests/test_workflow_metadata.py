from pathlib import Path
import subprocess
import tempfile
import unittest


REPO_ROOT = Path(__file__).resolve().parents[1]
VALIDATOR = REPO_ROOT / "tools" / "validate_workflow_metadata.py"


VALID_ENTRY = """## RES-20260830-01
- path: `research/source.md`
- asset_type: research_index
- authority: non_authoritative_research
- lifecycle_status: active
- formal_use: advisory_only
- scope: 竞品研究来源导航
- source_basis: 文档内列明来源
- as_of: 2026-08-30
- last_reviewed: 2026-08-30
- valid_against: 当前研究文档
- decision_refs: —
- reuse_conditions: 仅用于形成建议
- refresh_trigger: 来源失效或进入新商业节点
- unresolved_conflicts: 无
- tags: competitor, research
"""


class WorkflowMetadataValidatorTests(unittest.TestCase):
    def make_repo(self, entry: str = VALID_ENTRY) -> Path:
        temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(temp_dir.cleanup)
        root = Path(temp_dir.name)

        required_files = {
            "AGENTS.md": (
                "# Rules\n## 1. 权威顺序\n## 4. 正式修改闭环\n"
                "## 8. 总调度与知识复用\n"
            ),
            "docs/AI_TEAM_OPERATING_SYSTEM.md": (
                "# Team workflow\n## 2. 三档执行强度\n"
                "## 7. 正式修改审批门\n## 9. 独立 QA\n"
            ),
            "docs/DECISIONS.md": "# Decisions\n",
            "docs/templates/AI_TASK_PACKET.md": (
                "# Task template\n## 2. 唯一目标\n"
                "## 4. 正式修改审批门\n### 变更影响检查\n"
                "| 剧情事实、因果、场次与顺序 |\n"
                "| 作者真相、角色私有知识、玩家知识与信息释放 |\n"
                "| 工作簿作者入口、同步链与程序生成物 |\n"
                "| 测试、过期基线与回归范围 |\n"
                "| Demo Hook、商店页、Trailer、定价与发行 |\n"
                "## 8. 验收计划\n"
            ),
            "docs/templates/AI_RESEARCH_RECORD.md": (
                "# Research template\n## 4. 来源\n"
                "## 7. 新鲜度与过期\n## 8. 采纳状态\n"
            ),
            "docs/templates/AI_ROLE_REPORT.md": (
                "# Role report template\n## 4. 发现与证据\n"
                "## 8. 验证记录\n## 9. 冲突、阻塞与待确认\n"
            ),
            ".agents/skills/mist-harbor-orchestrator/SKILL.md": (
                "---\nname: mist-harbor-orchestrator\n"
                "description: Coordinate project work.\n---\n"
                "## Route work\n## Enforce gates\n## Integrate and verify\n"
            ),
            "research/source.md": "# Source\n",
            "research/KNOWLEDGE_INDEX.md": (
                "# Knowledge index\n\n" + entry
            ),
        }
        for relative_path, content in required_files.items():
            path = root / relative_path
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")
        return root

    def run_validator(self, root: Path) -> subprocess.CompletedProcess:
        return subprocess.run(
            ["python3", str(VALIDATOR), "--root", str(root)],
            text=True,
            capture_output=True,
            check=False,
        )

    def test_minimal_valid_repository_passes(self) -> None:
        result = self.run_validator(self.make_repo())
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_missing_registered_file_fails(self) -> None:
        root = self.make_repo()
        (root / "research/source.md").unlink()
        result = self.run_validator(root)
        self.assertEqual(result.returncode, 1)
        self.assertIn("不存在", result.stdout)

    def test_research_cannot_claim_formal_authority(self) -> None:
        entry = VALID_ENTRY.replace(
            "authority: non_authoritative_research",
            "authority: authoritative_story",
        ).replace("formal_use: advisory_only", "formal_use: direct")
        result = self.run_validator(self.make_repo(entry))
        self.assertEqual(result.returncode, 1)
        self.assertIn("研究资料不得", result.stdout)

    def test_parent_path_escape_fails(self) -> None:
        entry = VALID_ENTRY.replace(
            "`research/source.md`", "`../outside.md`"
        )
        result = self.run_validator(self.make_repo(entry))
        self.assertEqual(result.returncode, 1)
        self.assertIn("不安全路径", result.stdout)

    def test_duplicate_asset_id_fails(self) -> None:
        result = self.run_validator(self.make_repo(VALID_ENTRY + "\n" + VALID_ENTRY))
        self.assertEqual(result.returncode, 1)
        self.assertIn("重复 asset_id", result.stdout)

    def test_superseded_entry_requires_successor(self) -> None:
        entry = VALID_ENTRY.replace("lifecycle_status: active", "lifecycle_status: superseded")
        result = self.run_validator(self.make_repo(entry))
        self.assertEqual(result.returncode, 1)
        self.assertIn("superseded_by", result.stdout)

    def test_validator_does_not_modify_indexed_file(self) -> None:
        root = self.make_repo()
        source = root / "research/source.md"
        before = source.read_bytes()
        result = self.run_validator(root)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(source.read_bytes(), before)

    def test_empty_control_file_fails(self) -> None:
        root = self.make_repo()
        (root / "docs/templates/AI_TASK_PACKET.md").write_text("", encoding="utf-8")
        result = self.run_validator(root)
        self.assertEqual(result.returncode, 1)
        self.assertIn("缺少必要标记", result.stdout)

    def test_task_template_requires_impact_check(self) -> None:
        root = self.make_repo()
        task_template = root / "docs/templates/AI_TASK_PACKET.md"
        task_template.write_text(
            task_template.read_text(encoding="utf-8").replace("### 变更影响检查\n", ""),
            encoding="utf-8",
        )
        result = self.run_validator(root)
        self.assertEqual(result.returncode, 1)
        self.assertIn("变更影响检查", result.stdout)

    def test_generated_directory_check_is_case_insensitive(self) -> None:
        root = self.make_repo()
        outputs_file = root / "outputs" / "source.md"
        outputs_file.parent.mkdir(parents=True, exist_ok=True)
        outputs_file.write_text("# Generated\n", encoding="utf-8")
        entry = VALID_ENTRY.replace("`research/source.md`", "`Outputs/source.md`")
        (root / "research/KNOWLEDGE_INDEX.md").write_text(
            "# Knowledge index\n\n" + entry,
            encoding="utf-8",
        )
        result = self.run_validator(root)
        self.assertEqual(result.returncode, 1)
        self.assertIn("生成物或临时目录", result.stdout)

    def test_research_authority_check_is_case_insensitive(self) -> None:
        root = self.make_repo()
        entry = VALID_ENTRY.replace("`research/source.md`", "`Research/source.md`").replace(
            "authority: non_authoritative_research",
            "authority: process_record",
        ).replace("formal_use: advisory_only", "formal_use: process_only")
        (root / "research/KNOWLEDGE_INDEX.md").write_text(
            "# Knowledge index\n\n" + entry,
            encoding="utf-8",
        )
        result = self.run_validator(root)
        self.assertEqual(result.returncode, 1)
        self.assertIn("研究资料不得", result.stdout)

    def test_superseded_successor_must_exist(self) -> None:
        entry = VALID_ENTRY.replace(
            "lifecycle_status: active",
            "lifecycle_status: superseded\n- superseded_by: RES-20260830-99",
        )
        result = self.run_validator(self.make_repo(entry))
        self.assertEqual(result.returncode, 1)
        self.assertIn("后继资产不存在", result.stdout)

    def test_review_date_before_source_date_warns(self) -> None:
        entry = VALID_ENTRY.replace("last_reviewed: 2026-08-30", "last_reviewed: 2026-08-29")
        result = self.run_validator(self.make_repo(entry))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("last_reviewed 早于 as_of", result.stdout)


if __name__ == "__main__":
    unittest.main()
