import { describe, it, expect } from '@ohos/hypium';
import { CarbonFactors } from '../main/ets/model/CarbonFactors';
import { DateUtil } from '../main/ets/common/DateUtil';
import { Rewards } from '../main/ets/model/Rewards';
import { CarbonStore } from '../main/ets/model/CarbonStore';
import { Sapling, DayStat, SaplingState } from '../main/ets/model/Sapling';

export default function localUnitTest() {
  describe('DateUtil', () => {
    it('dayKey_pads_month_and_day', 0, () => {
      const ts = new Date(2026, 0, 5, 10, 0, 0).getTime();
      expect(DateUtil.dayKey(ts)).assertEqual('2026-01-05');
    });

    it('startOfWeek_returns_monday', 0, () => {
      const wed = new Date(2026, 8, 23, 12, 0, 0).getTime();
      const monday = DateUtil.startOfWeek(wed);
      expect(new Date(monday).getDay()).assertEqual(1);
    });

    it('dayKeyToTimestamp_roundtrips', 0, () => {
      const ts = DateUtil.dayKeyToTimestamp('2026-09-25');
      expect(DateUtil.dayKey(ts)).assertEqual('2026-09-25');
    });
  });

  describe('CarbonFactors', () => {
    it('find_returns_matching_behavior', 0, () => {
      expect(CarbonFactors.find('walk').factor).assertEqual(0.17);
      expect(CarbonFactors.find('walk').unit).assertEqual('km');
    });

    it('find_falls_back_to_first_for_unknown_key', 0, () => {
      expect(CarbonFactors.find('__unknown__').key).assertEqual(CarbonFactors.BEHAVIORS[0].key);
    });

    it('getByCategory_returns_non_empty_list', 0, () => {
      expect(CarbonFactors.getByCategory('回收').length > 0).assertTrue();
    });
  });

  describe('Rewards', () => {
    it('treeCount_is_zero_when_no_records', 0, () => {
      expect(Rewards.treeCount(CarbonStore.get())).assertEqual(0);
    });
  });

  describe('Backup', () => {
    it('snapshot_contains_all_sections', 0, () => {
      const text = CarbonStore.get().exportSnapshot();
      expect(text.indexOf('"app"') >= 0).assertTrue();
      expect(text.indexOf('CarbonLife') >= 0).assertTrue();
      expect(text.indexOf('"version"') >= 0).assertTrue();
      expect(text.indexOf('"records"') >= 0).assertTrue();
      expect(text.indexOf('"redemptions"') >= 0).assertTrue();
      expect(text.indexOf('"taskRewards"') >= 0).assertTrue();
    });
  });

  describe('ImportValidation', () => {
    it('importJson_rejects_non_json', 0, () => {
      expect(CarbonStore.get().importJson('not a json')).assertEqual(-1);
    });

    it('importJson_drops_records_without_id', 0, () => {
      // 无 id / 空 id 的记录应被丢弃，且不产生任何新增
      expect(CarbonStore.get().importJson('[{"amount":1},{"id":""}]')).assertEqual(0);
    });
  });

  describe('Sapling', () => {
    const day = (dateKey: string, records: number, tasks: number): DayStat => {
      const d: DayStat = { dateKey: dateKey, records: records, tasks: tasks };
      return d;
    };

    it('stageOf_matches_thresholds', 0, () => {
      expect(Sapling.stageOf(0)).assertEqual(0);
      expect(Sapling.stageOf(59)).assertEqual(0);
      expect(Sapling.stageOf(60)).assertEqual(1);
      expect(Sapling.stageOf(179)).assertEqual(1);
      expect(Sapling.stageOf(180)).assertEqual(2);
      expect(Sapling.stageOf(2400)).assertEqual(5);
    });

    it('compute_single_day_grows_six_records_to_sprout', 0, () => {
      const s: SaplingState = Sapling.compute([day('2026-10-20', 6, 0)], '2026-10-20');
      expect(s.growth).assertEqual(60);
      expect(s.stage).assertEqual(1);
      expect(s.streak).assertEqual(1);
      expect(s.todayGrowth).assertEqual(60);
      expect(s.capped).assertFalse();
    });

    it('compute_caps_daily_growth_at_80', 0, () => {
      const s: SaplingState = Sapling.compute([day('2026-10-20', 20, 0)], '2026-10-20');
      expect(s.growth).assertEqual(80);
      expect(s.capped).assertTrue();
    });

    it('compute_counts_daily_tasks', 0, () => {
      const s: SaplingState = Sapling.compute([day('2026-10-20', 0, 2)], '2026-10-20');
      expect(s.growth).assertEqual(30);
      expect(s.todayGrowth).assertEqual(30);
    });

    it('compute_applies_streak_bonus_on_consecutive_days', 0, () => {
      // 第 1 天 4 条 = 40；第 2 天 4 条 = 40 * 1.05 = 42
      const s: SaplingState = Sapling.compute([
        day('2026-10-19', 4, 0),
        day('2026-10-20', 4, 0)
      ], '2026-10-20');
      expect(s.growth).assertEqual(82);
      expect(s.streak).assertEqual(2);
      expect(s.bestStreak).assertEqual(2);
      expect(s.todayGrowth).assertEqual(42);
    });

    it('compute_resets_streak_when_days_are_not_adjacent', 0, () => {
      // 中间断了一天：连续天数必须重置为 1，且不享受加成
      const s: SaplingState = Sapling.compute([
        day('2026-10-18', 4, 0),
        day('2026-10-20', 4, 0)
      ], '2026-10-20');
      expect(s.streak).assertEqual(1);
      expect(s.todayGrowth).assertEqual(40);
    });

    it('compute_reaches_max_stage', 0, () => {
      const days: DayStat[] = [];
      for (let i: number = 1; i <= 30; i++) {
        const dk: string = '2026-10-' + (i < 10 ? '0' : '') + i.toString();
        days.push(day(dk, 8, 0));
      }
      const s: SaplingState = Sapling.compute(days, '2026-10-30');
      expect(s.stage).assertEqual(5);
      expect(s.maxed).assertTrue();
      expect(s.progress).assertEqual(1);
    });
  });
}
