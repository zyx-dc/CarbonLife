export interface BehaviorDef {
  key: string;
  category: string;
  name: string;
  unit: string;
  factor: number;
  step: number;
  icon: string;
  tip: string;
}

export interface CarbonRecord {
  id: string;
  behaviorKey: string;
  category: string;
  name: string;
  amount: number;
  unit: string;
  factor: number;
  saved: number;
  points: number;
  timestamp: number;
  dateKey: string;
  note: string;
}

export interface BadgeDef {
  key: string;
  name: string;
  desc: string;
  icon: string;
  target: number;
}

export interface DailyTask {
  key: string;
  name: string;
  desc: string;
  points: number;
}

export interface CategoryStat {
  category: string;
  saved: number;
  color: string;
}

export interface TrendPoint {
  label: string;
  value: number;
}

export interface KnowledgeItem {
  id: string;
  title: ResourceStr;
  tag: ResourceStr;
  summary: ResourceStr;
  content: ResourceStr;
  points: ResourceStr[];
  factLabel: ResourceStr;
  fact: ResourceStr;
  readMin: number;
}

export interface QuizOption {
  label: ResourceStr;
  score: number;
}

export interface QuizQuestion {
  id: string;
  q: ResourceStr;
  options: QuizOption[];
}

export interface RedeemItem {
  id: string;
  name: string;
  desc: string;
  cost: number;
  icon: string;
  category: string;
}

export interface RedemptionRecord {
  id: string;
  itemId: string;
  itemName: string;
  cost: number;
  timestamp: number;
}

// 每日任务的奖励发放记录：保证同一任务在同一天只发放一次积分
export interface TaskRewardRecord {
  dateKey: string;
  taskKey: string;
  points: number;
  timestamp: number;
}
