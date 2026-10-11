import { describe, it, expect } from '@ohos/hypium';
import { CarbonFactors } from '../main/ets/model/CarbonFactors';
import { DateUtil } from '../main/ets/common/DateUtil';
import { Rewards } from '../main/ets/model/Rewards';
import { CarbonStore } from '../main/ets/model/CarbonStore';

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
}
