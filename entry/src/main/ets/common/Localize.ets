// 数据层展示本地化：数据（行为/类别/单位）在 model 层保持稳定中文键用于存储与逻辑，
// 仅在 UI 渲染时按 key 映射到资源，避免污染持久化数据与 CSV 往返。
// 未知键回退为传入的规范名，保证新增行为未翻译时不至于空白。

export function behaviorNameRes(key: string, fallback: string): ResourceStr {
  switch (key) {
    case 'walk': return $r('app.string.behavior_walk');
    case 'bike': return $r('app.string.behavior_bike');
    case 'bus': return $r('app.string.behavior_bus');
    case 'subway': return $r('app.string.behavior_subway');
    case 'save_power': return $r('app.string.behavior_save_power');
    case 'save_water': return $r('app.string.behavior_save_water');
    case 'recycle_paper': return $r('app.string.behavior_recycle_paper');
    case 'recycle_plastic': return $r('app.string.behavior_recycle_plastic');
    case 'recycle_metal': return $r('app.string.behavior_recycle_metal');
    case 'recycle_clothes': return $r('app.string.behavior_recycle_clothes');
    case 'clean_plate': return $r('app.string.behavior_clean_plate');
    case 'no_disposable': return $r('app.string.behavior_no_disposable');
    case 'veg_meal': return $r('app.string.behavior_veg_meal');
    default: return fallback;
  }
}

export function categoryRes(category: string): ResourceStr {
  if (category === '出行') return $r('app.string.category_travel');
  if (category === '节能') return $r('app.string.category_energy');
  if (category === '回收') return $r('app.string.category_recycle');
  if (category === '餐饮') return $r('app.string.category_food');
  return category;
}

// 多数单位（km / kWh / L / kg）跨语言通用，仅中文量词需本地化
export function unitRes(unit: string): ResourceStr {
  if (unit === '餐') return $r('app.string.unit_meal');
  if (unit === '次') return $r('app.string.unit_time');
  return unit;
}

// 将 ResourceStr 解析为当前语言字符串，供拼接或格式化占位符使用
export function resolveStr(v: ResourceStr): string {
  if (typeof v === 'string') {
    return v;
  }
  const ctx = getContext();
  if (!ctx) {
    return '';
  }
  // 注意：getStringSync(Resource) 不会代入 $r(id, ...args) 的占位符参数，
  // 必须把参数显式透传，否则会原样显示 "%s"。
  const res: Resource = v as Resource;
  const params: Array<string | number> | undefined = res.params as Array<string | number> | undefined;
  if (params !== undefined && params.length > 0) {
    return ctx.resourceManager.getStringSync(res.id, ...params);
  }
  return ctx.resourceManager.getStringSync(res.id);
}

export function badgeNameRes(key: string, fallback: string): ResourceStr {
  switch (key) {
    case 'b1': return $r('app.string.badge_b1_name');
    case 'b2': return $r('app.string.badge_b2_name');
    case 'b3': return $r('app.string.badge_b3_name');
    case 'b4': return $r('app.string.badge_b4_name');
    case 'b5': return $r('app.string.badge_b5_name');
    case 'b6': return $r('app.string.badge_b6_name');
    case 'b7': return $r('app.string.badge_b7_name');
    default: return fallback;
  }
}

export function badgeDescRes(key: string, fallback: string): ResourceStr {
  switch (key) {
    case 'b1': return $r('app.string.badge_b1_desc');
    case 'b2': return $r('app.string.badge_b2_desc');
    case 'b3': return $r('app.string.badge_b3_desc');
    case 'b4': return $r('app.string.badge_b4_desc');
    case 'b5': return $r('app.string.badge_b5_desc');
    case 'b6': return $r('app.string.badge_b6_desc');
    case 'b7': return $r('app.string.badge_b7_desc');
    default: return fallback;
  }
}

export function taskNameRes(key: string, fallback: string): ResourceStr {
  switch (key) {
    case 't1': return $r('app.string.task_t1_name');
    case 't2': return $r('app.string.task_t2_name');
    case 't3': return $r('app.string.task_t3_name');
    case 't4': return $r('app.string.task_t4_name');
    default: return fallback;
  }
}

export function taskDescRes(key: string, fallback: string): ResourceStr {
  switch (key) {
    case 't1': return $r('app.string.task_t1_desc');
    case 't2': return $r('app.string.task_t2_desc');
    case 't3': return $r('app.string.task_t3_desc');
    case 't4': return $r('app.string.task_t4_desc');
    default: return fallback;
  }
}

export function mallNameRes(id: string, fallback: string): ResourceStr {
  switch (id) {
    case 'm1': return $r('app.string.mall_m1_name');
    case 'm2': return $r('app.string.mall_m2_name');
    case 'm3': return $r('app.string.mall_m3_name');
    case 'm4': return $r('app.string.mall_m4_name');
    case 'm5': return $r('app.string.mall_m5_name');
    case 'm6': return $r('app.string.mall_m6_name');
    default: return fallback;
  }
}

export function mallDescRes(id: string, fallback: string): ResourceStr {
  switch (id) {
    case 'm1': return $r('app.string.mall_m1_desc');
    case 'm2': return $r('app.string.mall_m2_desc');
    case 'm3': return $r('app.string.mall_m3_desc');
    case 'm4': return $r('app.string.mall_m4_desc');
    case 'm5': return $r('app.string.mall_m5_desc');
    case 'm6': return $r('app.string.mall_m6_desc');
    default: return fallback;
  }
}
