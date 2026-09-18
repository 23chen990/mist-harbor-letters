from pathlib import Path
import re


GAME_STATE_PATH = Path(__file__).resolve().parents[1] / "scripts" / "game_state.gd"
PUBLIC_DEATH_CONCLUSION = "赵敬文死在春和后巷石埠附近，警方认定为失足落水身亡"


def test_reporter_public_death_conclusion() -> None:
    source = GAME_STATE_PATH.read_text(encoding="utf-8")
    catalog_match = re.search(
        r"const KNOWLEDGE_CATALOG: Array\[String\] = \[(.*?)\n\]",
        source,
        re.DOTALL,
    )
    assert catalog_match is not None, "无法读取运行时知识目录"

    reporter_entries = re.findall(r'"([^"\n]*赵敬文[^"\n]*)"', catalog_match.group(1))
    assert PUBLIC_DEATH_CONCLUSION in reporter_entries, "运行时知识目录没有同步赵敬文失足落水身亡的公开结论"
    for entry in reporter_entries:
        assert "自杀" not in entry and "投水自尽" not in entry, (
            f"运行时知识目录仍含赵敬文自杀的旧公开口径：{entry}"
        )


if __name__ == "__main__":
    test_reporter_public_death_conclusion()
    print("PASS: reporter public death conclusion is synchronized")
