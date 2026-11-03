# 开源树素材与生成方式

## 素材来源

- **Temaki** by Bryan Housel — **CC0 1.0**（公有领域，可商用，免署名）
- 通过 Iconify API 获取：`https://api.iconify.design/temaki/<name>.svg`
- 使用到的图标：
  - `tree-broadleaved`（均衡 / 餐饮共用）
  - `tree-palm`（出行）
  - `tree-leafless`（回收）
  - `tree-needleleaved`（节能）
- 未使用 game-icons（CC BY 3.0，需署名）；如后续换用，需在“关于”页补充作者与许可证。

## 派生方式

`tools/tree_os/gen.py` 读取上面的 15×15 单路径 SVG：

1. 按 200×200 画布缩放，底部对齐 y=178
2. 复制一层深色路径、错位 0.2/0.26（约 2–3px），做出一点厚度
3. 每个形态 6 个阶段：
   - 0 种子、1 幼苗：程序化绘制（与 Temaki 同样的粗轮廓）
   - 2 小树 55%、3 开花 72%、4 结果 88%、5 常青 100%
   - 3 开花：5 颗奶油色花点（无瞳孔，避免像眼睛）
   - 4 结果：3 颗大果；回收型改为“枯枝回芽”，长绿芽不结红果
   - 5 常青：整体加深 8%；回收型在枝头补叶子
4. 生成 30 张到 `docs/tasks/tree-concept/open-source/generated/`
5. 复制到 `entry/src/main/resources/base/media/tree_{variant}_{stage}.svg`

## 重新生成

```powershell
python tools\tree_os\gen.py
Copy-Item "docs\tasks\tree-concept\open-source\generated\tree_*.svg" `
  "entry\src\main\resources\base\media\" -Force
```

## 动效

在 `SaplingView.ets` 中用 ArkUI 原生实现，不引入第三方运行时：

- 首次出现：`grow 0.84 → 1`，520ms ease-out，同时上移 12px
- 阶段提升：`grow 0.90 → 1`，460ms；叠加原有 360ms 交叉淡入
- 减弱动效开启时：直接切图，不做缩放/淡入
