# 碳小树 · 3D 软陶版

## 素材来源

- **Kenney Nature Kit** — **CC0**（公有领域，可商用，免署名）
- 使用的模型（`Models/GLTF format/*.glb`）：
  - `tree_oak`（均衡）
  - `tree_palmBend`（出行）
  - `tree_thin`（回收）
  - `tree_pineTallA`（节能）
  - `tree_fat`（餐饮）
- 模型包不在仓库内（约 28 MB）。复现时从 https://kenney.nl/assets/nature-kit 下载，
  解压到 `docs/tasks/tree-concept/3d/nature-kit/`。

## 渲染

- Blender 5.2 + Cycles（GPU），512×512，透明背景
- 统一软陶材质：Principled BSDF，粗糙度 0.72，轻微次表面
- 三点光：暖主光 + 冷补光 + 背轮廓光
- 五种形态各自主色，树干统一 `#6B4B33`
- 阶段：
  - 0 种子：土丘 + 种子 + 芽（程序化低模）
  - 1 幼苗：茎 + 三片叶
  - 2 小树：模型缩到 55%
  - 3 开花：树冠前侧 3 朵五瓣小花
  - 4 结果：树冠前侧 3 颗小果
  - 5 常青：100% + 回收型枝头补叶
- 果实/花放在树冠**前侧表面**，避免从侧面看像螺栓

## 命令

```powershell
# 单张测试：variant stage
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b `
  -P tools\tree3d\make_trees_kenney.py -- mixed 4

# 全部 30 张
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b `
  -P tools\tree3d\make_trees_kenney.py

# 加接触阴影，导出 512 与 256
python tools\tree3d\post.py
```

## 接入 App

- 256px 版本复制到 `entry/src/main/resources/base/media/tree_{variant}_{stage}.png`
- `SaplingView` 的资源名不变（`$r('app.media.tree_mixed_0')` 等），无需改映射
- 生长动效仍在 ArkUI 里：首次 `0.84 → 1`，阶段提升 `0.90 → 1`，叠加 360ms 交叉淡入

## 说明

- 早期尝试过的 Temaki（CC0）与 OpenDesign 生成版本已被本套替换，历史在 git 中。
- 失败稿（纸雕滤镜、基础几何体拼树）未保留，避免混淆。
