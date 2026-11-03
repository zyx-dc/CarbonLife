"""Render 30 clay-style trees with Blender (5 variants x 6 stages).

No external models: everything is built from primitives so the whole set
shares one material/lighting language. Output: 512x512 RGBA PNGs with a
transparent background; a soft ground shadow is added later in post.

Run:
  blender -b -P tools/tree3d/make_trees.py
"""
import math
import os

import bpy
from mathutils import Vector

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "docs", "tasks", "tree-concept", "3d", "raw")
os.makedirs(OUT, exist_ok=True)

# variant -> sRGB main colour
PALETTE = {
    "mixed":   "#4E9F63",
    "travel":  "#2FA894",
    "recycle": "#4C8FA8",
    "energy":  "#D9A63C",
    "food":    "#C97A5E",
}
TRUNK = "#6B4B33"
FRUIT = "#8F3B2A"
CREAM = "#F4E9C8"
LEAF = "#6FBF73"


def srgb(hex_color):
    h = hex_color.lstrip("#")
    out = []
    for i in (0, 2, 4):
        c = int(h[i:i + 2], 16) / 255.0
        out.append(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)
    return (*out, 1.0)


def shade(hex_color, factor):
    h = hex_color.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) for i in (0, 2, 4))
    r, g, b = (max(0, min(255, int(round(v * factor)))) for v in (r, g, b))
    return "#%02X%02X%02X" % (r, g, b)


def clay(name, hex_color, rough=0.72, sub=0.06):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = srgb(hex_color)
    bsdf.inputs["Roughness"].default_value = rough
    for key, value in (("Subsurface Weight", sub), ("Sheen Weight", 0.18)):
        if key in bsdf.inputs:
            bsdf.inputs[key].default_value = value
    return mat


def smooth(obj):
    for poly in obj.data.polygons:
        poly.use_smooth = True


def sphere(loc, scale, mat, segments=48, rings=24):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, radius=1.0, location=loc)
    obj = bpy.context.object
    obj.scale = scale
    smooth(obj)
    obj.data.materials.append(mat)
    return obj


def cone(loc, r1, r2, depth, mat, rot=(0, 0, 0), vertices=48, subsurf=True):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=r1, radius2=r2, depth=depth,
                                    location=loc, rotation=rot)
    obj = bpy.context.object
    smooth(obj)
    if subsurf:
        mod = obj.modifiers.new("soft", "SUBSURF")
        mod.levels = 2
        mod.render_levels = 2
    obj.data.materials.append(mat)
    return obj


def cylinder(loc, radius, depth, mat, rot=(0, 0, 0), vertices=32, subsurf=True):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth,
                                        location=loc, rotation=rot)
    obj = bpy.context.object
    smooth(obj)
    if subsurf:
        mod = obj.modifiers.new("soft", "SUBSURF")
        mod.levels = 2
        mod.render_levels = 2
    obj.data.materials.append(mat)
    return obj


def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def setup_scene(main_hex):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    try:
        scene.cycles.device = "GPU"
    except Exception:
        pass
    scene.cycles.samples = 64
    try:
        scene.cycles.use_denoising = True
    except Exception:
        pass
    scene.render.film_transparent = True
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    try:
        scene.eevee.taa_render_samples = 64
    except Exception:
        pass
    try:
        scene.view_settings.look = "AgX - Medium High Contrast"
    except Exception:
        pass

    world = bpy.data.worlds.new("world")
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    bg.inputs[0].default_value = (0.008, 0.010, 0.007, 1.0)
    bg.inputs[1].default_value = 0.45
    scene.world = world

    # camera
    cam_data = bpy.data.cameras.new("cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = 3.35
    cam = bpy.data.objects.new("cam", cam_data)
    scene.collection.objects.link(cam)
    cam.location = (2.8, -7.2, 3.3)
    target = bpy.data.objects.new("target", None)
    scene.collection.objects.link(target)
    target.location = (0.0, 0.0, 1.55)
    con = cam.constraints.new("TRACK_TO")
    con.target = target
    con.track_axis = "TRACK_NEGATIVE_Z"
    con.up_axis = "UP_Y"
    scene.camera = cam

    def area(name, loc, energy, size, color=(1, 1, 1), shape="DISK"):
        data = bpy.data.lights.new(name, "AREA")
        data.energy = energy
        data.size = size
        data.shape = shape
        data.color = color
        obj = bpy.data.objects.new(name, data)
        scene.collection.objects.link(obj)
        obj.location = loc
        c = obj.constraints.new("TRACK_TO")
        c.target = target
        c.track_axis = "TRACK_NEGATIVE_Z"
        c.up_axis = "UP_Y"
        return obj

    area("key", (-3.6, -4.2, 5.2), 620, 6.0, (1.0, 0.96, 0.90))
    area("fill", (4.2, -3.0, 2.6), 150, 5.0, (0.82, 0.90, 1.0))
    area("rim", (0.4, 4.6, 5.0), 520, 4.0, (1.0, 1.0, 0.94))
    area("bounce", (0.0, -1.0, -1.6), 60, 4.0, (0.9, 0.95, 0.85))

    return scene


def add_root(parts):
    root = bpy.data.objects.new("root", None)
    bpy.context.scene.collection.objects.link(root)
    for p in parts:
        p.parent = root
    return root


def broadleaf(main, deep, light):
    trunk_mat = clay("trunk", TRUNK, 0.8, 0.0)
    trunk = cone((0, 0, 1.02), 0.20, 0.12, 1.95, trunk_mat, subsurf=False)
    root = sphere((0, 0, 0.10), (0.34, 0.34, 0.14), trunk_mat)
    soil = sphere((0, 0, 0.03), (0.58, 0.58, 0.10), clay("soil", "#4A3A2A", 0.9, 0.0))
    canopy = [
        sphere((0, 0.16, 2.08), (0.82, 0.82, 0.74), deep),
        sphere((-0.52, 0.06, 1.88), (0.48, 0.48, 0.42), deep),
        sphere((0.54, 0.02, 1.90), (0.48, 0.48, 0.42), deep),
        sphere((0.0, -0.30, 2.02), (0.56, 0.56, 0.50), main),
        sphere((-0.34, -0.06, 2.38), (0.44, 0.44, 0.40), main),
        sphere((0.36, -0.04, 2.34), (0.42, 0.42, 0.38), main),
        sphere((-0.10, -0.42, 2.30), (0.36, 0.36, 0.32), light),
        sphere((0.20, -0.40, 2.14), (0.34, 0.34, 0.30), light),
    ]
    tufts = [
        sphere((-0.66, -0.10, 1.82), (0.20, 0.14, 0.10), main, segments=24, rings=12),
        sphere((0.68, -0.06, 1.84), (0.20, 0.14, 0.10), main, segments=24, rings=12),
        sphere((-0.16, -0.50, 2.42), (0.18, 0.12, 0.09), light, segments=24, rings=12),
        sphere((0.22, -0.48, 2.36), (0.18, 0.12, 0.09), light, segments=24, rings=12),
    ]
    return [soil, root, trunk, *canopy, *tufts]


def conifer(main):
    trunk = cone((0, 0, 0.55), 0.13, 0.09, 1.1, clay("trunk", TRUNK, 0.8, 0.0))
    tiers = [
        cone((0, 0, 1.30), 0.92, 0.02, 1.15, main, vertices=64),
        cone((0, 0, 1.95), 0.72, 0.02, 1.00, main, vertices=64),
        cone((0, 0, 2.50), 0.50, 0.02, 0.85, main, vertices=64),
    ]
    return [trunk, *tiers]


def palm(main):
    parts = []
    xs = [0.0, 0.06, 0.14, 0.24, 0.34]
    zs = [0.25, 0.75, 1.25, 1.72, 2.12]
    for i in range(len(xs) - 1):
        loc = ((xs[i] + xs[i + 1]) / 2, 0, (zs[i] + zs[i + 1]) / 2)
        depth = math.dist((xs[i], 0, zs[i]), (xs[i + 1], 0, zs[i + 1])) + 0.05
        ang = math.atan2(xs[i + 1] - xs[i], zs[i + 1] - zs[i])
        parts.append(cylinder(loc, 0.11 - i * 0.012, depth, clay("trunk", TRUNK, 0.8, 0.0),
                              rot=(0, ang, 0), vertices=24))
    top = (0.36, 0, 2.16)
    for i in range(7):
        a = math.radians(i * 360 / 7)
        leaf = sphere((top[0] + 0.62 * math.cos(a), 0.62 * math.sin(a), top[2] + 0.10),
                      (0.72, 0.20, 0.10), main)
        leaf.rotation_euler = (math.radians(-12), math.radians(-18), a)
        parts.append(leaf)
    return parts


def bare(main):
    trunk = cone((0, 0, 0.95), 0.15, 0.08, 1.9, clay("trunk", TRUNK, 0.8, 0.0))
    parts = [trunk]
    for i, (x, z, ang) in enumerate([(-0.45, 1.55, 42), (0.45, 1.62, -42), (-0.20, 1.85, 20), (0.22, 1.90, -22)]):
        parts.append(cone((x, 0, z), 0.06, 0.03, 0.85, clay("branch", TRUNK, 0.8, 0.0),
                          rot=(0, math.radians(ang), 0)))
    return parts


def build(variant, stage):
    main = clay("canopy_" + variant, PALETTE[variant])
    trunk_mat = clay("trunk", TRUNK, 0.8, 0.0)
    parts = []

    if stage == 0:
        soil = sphere((0, 0, 0.10), (0.55, 0.55, 0.12), clay("soil", "#4A3A2A", 0.9, 0.0))
        seed = sphere((0, 0, 0.30), (0.16, 0.13, 0.22), clay("seed", "#A97C50", 0.8, 0.0))
        sprout = sphere((0.03, 0, 0.50), (0.06, 0.04, 0.12), main)
        leaf = sphere((0.14, 0, 0.55), (0.16, 0.05, 0.07), main)
        leaf.rotation_euler = (0, math.radians(28), 0)
        return [soil, seed, sprout, leaf]

    if stage == 1:
        stem = cone((0, 0, 0.55), 0.05, 0.03, 1.0, trunk_mat)
        leaves = []
        for i, (x, z, ang) in enumerate([(-0.22, 0.95, 32), (0.22, 1.05, -32), (0.0, 1.20, 0)]):
            leaf = sphere((x, 0, z), (0.28, 0.07, 0.12), main)
            leaf.rotation_euler = (0, math.radians(ang), 0)
            leaves.append(leaf)
        return [stem, *leaves]

    deep = clay("canopy_deep_" + variant, shade(PALETTE[variant], 0.76))
    light = clay("canopy_light_" + variant, shade(PALETTE[variant], 1.12))
    if variant == "mixed" or variant == "food":
        parts = broadleaf(main, deep, light)
    elif variant == "travel":
        parts = palm(main)
    elif variant == "recycle":
        parts = bare(main)
    else:
        parts = conifer(main)

    flowers = []
    fruits = []
    if stage == 3:
        for i in range(5):
            a = math.radians(i * 72)
            flowers.append(sphere((0.55 * math.cos(a), 0.55 * math.sin(a), 2.25 + 0.12 * math.sin(a * 2)),
                                  (0.10, 0.10, 0.10), clay("flower", CREAM, 0.6, 0.0)))
    if stage >= 4:
        for i in range(3):
            a = math.radians(20 + i * 120)
            fruits.append(sphere((0.48 * math.cos(a), 0.48 * math.sin(a), 2.05 + 0.1 * math.sin(a)),
                                 (0.13, 0.13, 0.13), clay("fruit", FRUIT, 0.55, 0.0)))

    if variant == "recycle":
        if stage >= 4:
            for i in range(4):
                a = math.radians(30 + i * 90)
                flowers.append(sphere((0.55 * math.cos(a), 0.55 * math.sin(a), 1.9 + 0.15 * math.sin(a)),
                                      (0.10, 0.10, 0.10), clay("bud", LEAF, 0.7, 0.0)))
        if stage >= 5:
            for i in range(6):
                a = math.radians(i * 60)
                leaf = sphere((0.7 * math.cos(a), 0.7 * math.sin(a), 1.85 + 0.2 * math.sin(a * 2)),
                              (0.18, 0.07, 0.05), clay("leaf", LEAF, 0.7, 0.0))
                leaf.rotation_euler = (0, 0, a)
                flowers.append(leaf)

    parts.extend(flowers)
    parts.extend(fruits)

    scale = {2: 0.55, 3: 0.72, 4: 0.88, 5: 1.0}[stage]
    root = add_root(parts)
    root.scale = (scale, scale, scale)
    return parts


def render(variant, stage):
    clear_scene()
    scene = setup_scene(PALETTE[variant])
    build(variant, stage)
    scene.render.filepath = os.path.join(OUT, f"tree_{variant}_{stage}.png")
    bpy.ops.render.render(write_still=True)


def main():
    for variant in PALETTE:
        for stage in range(6):
            render(variant, stage)
            print("rendered", variant, stage, flush=True)


if __name__ == "__main__":
    import sys
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    if len(argv) >= 2:
        render(argv[0], int(argv[1]))
    else:
        main()
