"""Render the final 30-tree set from Kenney Nature Kit (CC0) with clay materials.

5 variants:
  mixed   tree_oak
  travel  tree_palmBend
  recycle tree_thin
  energy  tree_pineTallA
  food    tree_fat

Stages: seed, sprout, sapling 55%, bloom 72%, fruit 88%, evergreen 100%.
Output: 512x512 RGBA PNGs in docs/tasks/tree-concept/3d/kenney/
"""
import math
import os
import sys

import bpy
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from make_trees import setup_scene, clay, shade, PALETTE, TRUNK, FRUIT, CREAM, LEAF  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
MODELS = os.path.join(ROOT, "docs", "tasks", "tree-concept", "3d", "nature-kit", "Models", "GLTF format")
OUT = os.path.join(ROOT, "docs", "tasks", "tree-concept", "3d", "kenney")
os.makedirs(OUT, exist_ok=True)

MODEL = {
    "mixed": "tree_oak",
    "travel": "tree_palmBend",
    "recycle": "tree_thin",
    "energy": "tree_pineTallA",
    "food": "tree_fat",
}

# 装饰位置（归一化到 2.8 高之后的坐标）
ANCHORS = {
    "tree_oak": {
        "flower": [(0.34, -0.52, 2.28), (-0.30, -0.50, 2.12), (0.02, -0.66, 2.42)],
        "fruit": [(0.30, -0.60, 2.06), (-0.26, -0.58, 1.94), (0.02, -0.72, 2.22)],
    },
    "tree_fat": {
        "flower": [(0.38, -0.58, 2.02), (-0.32, -0.56, 1.92), (0.02, -0.72, 2.18)],
        "fruit": [(0.32, -0.68, 1.94), (-0.28, -0.64, 1.84), (0.02, -0.78, 2.06)],
    },
    "tree_palmBend": {
        "flower": [(0.48, -0.18, 2.55), (0.18, 0.22, 2.52), (0.32, 0.02, 2.62)],
        "fruit": [(0.52, -0.08, 2.46), (0.28, 0.16, 2.44), (0.42, 0.20, 2.40)],
    },
    "tree_pineTallA": {
        "flower": [(0.0, -0.34, 2.30), (0.26, -0.24, 1.90), (-0.26, -0.20, 1.55)],
        "fruit": [(0.0, -0.38, 2.14), (0.28, -0.24, 1.80), (-0.28, -0.20, 1.45)],
    },
    "tree_thin": {
        "flower": [(0.0, -0.30, 2.40), (0.18, -0.16, 2.00), (-0.08, -0.14, 1.60)],
        "fruit": [(0.0, -0.32, 2.24), (0.18, -0.18, 1.90), (-0.05, -0.14, 1.55)],
    },
}

STAGE_SCALE = {2: 0.55, 3: 0.72, 4: 0.88, 5: 1.0}


def ico(loc, scale, mat, subdivisions=1, smooth=False):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdivisions, radius=1.0, location=loc)
    obj = bpy.context.object
    obj.scale = scale
    if smooth:
        for p in obj.data.polygons:
            p.use_smooth = True
    obj.data.materials.append(mat)
    return obj


def lowpoly_cone(loc, r1, r2, depth, mat, rot=(0, 0, 0), vertices=8):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=r1, radius2=r2, depth=depth,
                                    location=loc, rotation=rot)
    obj = bpy.context.object
    obj.data.materials.append(mat)
    return obj


def normalize(objs, target_height=2.8):
    bpy.context.view_layer.update()
    pts = []
    for o in objs:
        for c in o.bound_box:
            pts.append(o.matrix_world @ Vector(c))
    minz = min(p.z for p in pts)
    maxz = max(p.z for p in pts)
    cx = (min(p.x for p in pts) + max(p.x for p in pts)) / 2
    cy = (min(p.y for p in pts) + max(p.y for p in pts)) / 2
    s = target_height / max(0.001, maxz - minz)
    for o in objs:
        o.location = ((o.location.x - cx) * s, (o.location.y - cy) * s, (o.location.z - minz) * s)
        o.scale = (o.scale.x * s, o.scale.y * s, o.scale.z * s)


def import_model(name, canopy, bark):
    bpy.ops.import_scene.gltf(filepath=os.path.join(MODELS, name + ".glb"))
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    for o in meshes:
        for slot in o.material_slots:
            n = (slot.material.name if slot.material else "").lower()
            slot.material = bark if ("wood" in n or "bark" in n or "trunk" in n) else canopy
    normalize(meshes)
    return meshes


def canopy_bounds(meshes, canopy_mat):
    pts = []
    for o in meshes:
        mw = o.matrix_world
        for poly in o.data.polygons:
            try:
                mat = o.data.materials[poly.material_index]
            except Exception:
                mat = None
            if mat is not None and mat.name == canopy_mat.name:
                for vi in poly.vertices:
                    pts.append(mw @ o.data.vertices[vi].co)
    if not pts:
        return Vector((0, 0, 2.0)), Vector((0.6, 0.6, 0.6))
    xs = [p.x for p in pts]
    ys = [p.y for p in pts]
    zs = [p.z for p in pts]
    center = Vector(((min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, (min(zs) + max(zs)) / 2))
    radii = Vector(((max(xs) - min(xs)) / 2, (max(ys) - min(ys)) / 2, (max(zs) - min(zs)) / 2))
    return center, radii


def flower(loc, petal_mat, center_mat, size=0.05):
    parts = []
    for i in range(5):
        a = math.radians(i * 72)
        p = (loc[0] + 0.095 * math.cos(a), loc[1] + 0.095 * math.sin(a), loc[2])
        parts.append(ico(p, (size * 1.35, size * 1.35, size * 0.7), petal_mat))
    parts.append(ico(loc, (size * 0.45, size * 0.45, size * 0.35), center_mat))
    return parts


def berry(loc, mat, size=0.11):
    return ico(loc, (size, size, size * 0.9), mat)


def finish(parts, scale):
    root = bpy.data.objects.new("root", None)
    bpy.context.scene.collection.objects.link(root)
    for o in parts:
        o.parent = root
    root.scale = (scale, scale, scale)
    return parts


def build(variant, stage):
    main_hex = PALETTE[variant]
    canopy = clay("canopy_" + variant, main_hex)
    bark = clay("bark", TRUNK, 0.8, 0.0)

    if stage == 0:
        soil = ico((0, 0, 0.12), (0.68, 0.68, 0.16), clay("soil", "#4A3A2A", 0.9, 0.0))
        seed = ico((0, 0, 0.40), (0.22, 0.18, 0.29), clay("seed", "#A97C50", 0.8, 0.0))
        leaf = lowpoly_cone((0.14, 0, 0.64), 0.17, 0.0, 0.30, canopy,
                            rot=(0, math.radians(55), 0))
        return finish([soil, seed, leaf], 1.55)

    if stage == 1:
        stem = lowpoly_cone((0, 0, 0.62), 0.06, 0.03, 1.15, bark)
        leaves = [
            lowpoly_cone((-0.20, 0, 1.02), 0.34, 0.0, 0.12, canopy, rot=(0, math.radians(70), 0)),
            lowpoly_cone((0.20, 0, 1.12), 0.34, 0.0, 0.12, canopy, rot=(0, math.radians(-70), 0)),
            lowpoly_cone((0.0, 0, 1.30), 0.26, 0.0, 0.10, canopy, rot=(math.radians(0), 0, 0)),
        ]
        return finish([stem, *leaves], 1.05)

    model = MODEL[variant]
    meshes = import_model(model, canopy, bark)

    ornaments = []
    if stage >= 3:
        cream = clay("cream", CREAM, 0.6, 0.0)
        pollen = clay("pollen", "#D9A63C", 0.55, 0.0)
        fruit = clay("fruit", FRUIT, 0.55, 0.0)
        for (x, y, z) in ANCHORS[model]["flower"]:
            ornaments.extend(flower((x, y, z), cream, pollen))
        if stage >= 4:
            for (x, y, z) in ANCHORS[model]["fruit"]:
                ornaments.append(berry((x, y, z), fruit))
    if variant == "recycle" and stage >= 5:
        leaf_mat = clay("leaf", LEAF, 0.7, 0.0)
        for i in range(5):
            a = math.radians(i * 72)
            ornaments.append(ico((0.34 * math.cos(a), 0.34 * math.sin(a), 2.1 + 0.30 * math.sin(a)),
                                 (0.13, 0.09, 0.09), leaf_mat))

    return finish(meshes + ornaments, STAGE_SCALE[stage])


def render(variant, stage):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = setup_scene(PALETTE[variant])
    build(variant, stage)
    scene.render.filepath = os.path.join(OUT, f"tree_{variant}_{stage}.png")
    bpy.ops.render.render(write_still=True)
    print("rendered", variant, stage, flush=True)


def main():
    for variant in MODEL:
        for stage in range(6):
            render(variant, stage)


if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    if len(argv) >= 2:
        render(argv[0], int(argv[1]))
    else:
        main()
