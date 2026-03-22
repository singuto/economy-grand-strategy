# Equirectangular → Godot cubemap

Converts a 2:1 equirectangular PNG into a single stitched image that Godot can import as a **Cubemap** (`cubemap_texture` importer). Resampling uses Lanczos (OpenCV).

## One-time setup

From the repository root:

```bash
cd Tools/equirect_to_godot_cubemap
python3 -m venv .venv
.venv/bin/python3 -m pip install -r requirements.txt
```

The project `.gitignore` already ignores `.venv/`; do not commit the virtualenv.

## Province map (bundled input)

`ProvinceMap.png` in this folder is the equirect source. To regenerate the cubemap used under `Textures/Globe/`:

```bash
cd Tools/equirect_to_godot_cubemap
.venv/bin/python3 equirect_to_godot_cubemap.py ProvinceMap.png ../../Textures/Globe/ProvinceMapCubemap.png
```

That writes **`Textures/Globe/ProvinceMapCubemap.png`** with the default **`2x3`** face arrangement (same as the existing globe cubemaps in this project: Godot **Import → Slices → Arrangement → 2×3**, which is `slices/arrangement=1` in the `.import` file).

## General usage

```bash
.venv/bin/python3 equirect_to_godot_cubemap.py <input_equirect.png> <output_cubemap.png> [options]
```

| Option | Default | Meaning |
|--------|---------|---------|
| `--layout` | `2x3` | Slice layout: `1x6`, `2x3`, `3x2`, or `6x1`. Must match the cubemap arrangement you set in Godot’s import settings. |
| `--face-size N` | `¼` of source **width** | Square face size in pixels. |

Face order in the script matches Godot: **X+, X-, Y+, Y-, Z+, Z-** (Y+ up, Z- forward).

## Godot

After adding or replacing the PNG under `res://`, open the project (or focus the editor) so Godot runs the import pass. Assign the resource as a `CompressedCubemap` like the other files in `Textures/Globe/`. If the import preview looks wrong, the **Slices → Arrangement** value almost certainly does not match the `--layout` you used when generating the file.
