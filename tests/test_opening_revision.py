"""DEC34 的内容验收；检查由作者工作簿同步生成的运行表。"""
import csv
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class OpeningRevision(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with (ROOT / 'content/程序生成_请勿手改/剧情剧本.csv').open(encoding='utf-8-sig') as f:
            cls.rows = list(csv.DictReader(f))
        cls.by_id = {r['自动ID']: r for r in cls.rows}

    def test_short_opening_keeps_death_hook_and_job(self):
        opening = '\n'.join(r['NPC台词'] for r in self.rows if r['自动ID'].startswith('P0001'))
        self.assertLessEqual(opening.count('「'), 5)
        for fact in ['春和', '没人接', '人也是在那儿没的', '十一点半']:
            self.assertIn(fact, opening)
        self.assertNotIn('半个钟头', opening)
        self.assertNotIn('留几栏', opening)

    def test_four_clues_go_straight_to_letter_preparation(self):
        self.assertEqual(self.by_id['P0013']['下一话题'], '前序·准备出发')
        self.assertNotIn('P0016', self.by_id)
        self.assertNotIn('P0017', self.by_id)
        self.assertNotIn('P0018', self.by_id)
        self.assertIn('寻找回信', self.by_id['P0007']['玩家可选台词'])

    def test_disclosure_has_distinct_immediate_replies(self):
        options = [r for r in self.rows if r['对话阶段'] == '第一章·纪念演出采访·材料透露' and r['玩家可选台词']]
        self.assertEqual(len(options), 2)
        self.assertEqual(len({r['下一话题'] for r in options}), 2)
        for option in options:
            self.assertEqual(option['是否说出口'], '是')
            self.assertIn('lin_disclosure=', option['状态写入（不显示）'])
            reply = [r for r in self.rows if r['对话阶段'] == option['下一话题']]
            self.assertTrue(any(r['NPC台词'] for r in reply))
            self.assertTrue(all('已回信' not in r['玩家因此知道什么'] for r in reply))

    def test_original_interview_does_not_certify_missing_reply(self):
        self.assertNotIn('您没有回', self.by_id['C04_010']['NPC台词'])
        self.assertIn('留底旁', self.by_id['C04_010']['NPC台词'])
        self.assertEqual(self.by_id['C04_030']['出现条件'], 'letter_preparation=left_home')
        self.assertIn('没有拿出纸面', self.by_id['C04_030']['NPC台词'])

    def test_protagonist_dialogue_is_marked_as_spoken(self):
        for row in self.rows:
            if row['内容类型'] == 'NPC台词' and '沈砚舟：「' in row['NPC台词']:
                self.assertEqual(row['是否说出口'], '是', row['自动ID'])

    def test_unique_ids_and_valid_links(self):
        self.assertEqual(len(self.rows), len(self.by_id))
        stages = {r['对话阶段'] for r in self.rows}
        for row in self.rows:
            if row['下一话题']:
                self.assertIn(row['下一话题'], stages, row['自动ID'])


if __name__ == '__main__':
    unittest.main()
