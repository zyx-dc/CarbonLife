# Research / discovery

## Question

Before choosing content structure or visual direction, what must be verified?

## Findings

- **App 形态**：HarmonyOS / OpenHarmony 原生应用（ArkTS + ArkUI 声明式 UI，Stage 模型，
  compatibleSdkVersion 26.0.0，deviceTypes: phone/tablet）；包名 `com.example.carbonlife`。
- **核心闭环**：记录低碳行为 → 按「活动量 × 排放因子」算减排量与碳积分 → 积分兑换/徽章/植树 →
  家庭碳积分共享。
- **13 种行为**：出行 / 节能 / 回收 / 餐饮四大类。
- **端侧能力**：CoreVisionKit 端侧物体检测（识图推荐行为，图片不出本机）；
  DistributedDataObject 家庭同步；BackgroundTasksKit 代理提醒。
- **隐私**：记录仅存本机 Preferences；家庭数据仅同账号设备间同步；识图本机完成。
- **设计系统（唯一真相 = DESIGN.md）**：双主题「夜行荧光」（暗）/「日光纸感」（浅）；
  青柠为稀缺信号色，电青仅用于积分/成就。
- **真实截图位置**：根目录 `app_home_new.jpeg` / `app_record_new2.jpeg` / `app_dashboard.jpeg` /
  `app_rewards_v4.jpeg` / `app_knowledge.jpeg` / `screen3.jpeg`；`docs/qa/` 下另有深色首页
  `qa_dark_home.jpeg`、识图 `app_food.jpeg`、看板 `qa_dash_week.jpeg` 等。
- **验收事实（来自 QA_REPORT.md）**：9/22 基线 PASS 3 / FAIL 3 / BLOCKED 1；
  10/01 复测：记录增删实时刷新、图表刷新、家庭聚合（本地侧）均由 FAIL/BLOCKED 转为 PASS；
  分布式权限弹窗与跨设备聚合仍需真机复测。
- **待完成（只可写入展望）**：真实碳普惠平台 API、AGC 云备份、系统无障碍、平板多列布局。
- **红线**：仓库已做去标识化——不得出现团队/成员/指导老师/院校信息。

## Decision

采用「参赛答辩」结构（context → problem → solution → users → features → 5 highlights →
design → tech → privacy → QA → roadmap），15 页，16:9，中文；视觉采用「森境双调」。
