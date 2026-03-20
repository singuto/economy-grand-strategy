extends RefCounted
class_name GlobeMapCoords

## Unit direction in globe **local** space (Y up) to equirect UV.
## Matches [GlobeBorderOverlay.gdshader] sampling.


static func direction_to_equirect_uv(dir: Vector3) -> Vector2:
	var d := dir.normalized()
	var phi := atan2(d.x, d.z)
	var theta := asin(clampf(d.y, -1.0, 1.0))
	var u := phi / TAU + 0.5
	u = fposmod(u, 1.0)
	var v := 0.5 - theta / PI
	return Vector2(u, clampf(v, 0.0001, 0.9999))


static func country_id_at_uv(id_image: Image, uv: Vector2) -> int:
	if id_image.is_empty():
		return 0
	var w := id_image.get_width()
	var h := id_image.get_height()
	var x := int(floor(fposmod(uv.x, 1.0) * float(w)))
	var y := int(floor(clampf(uv.y, 0.0, 1.0) * float(h)))
	x = clampi(x, 0, w - 1)
	y = clampi(y, 0, h - 1)
	var p: Color = id_image.get_pixel(x, y)
	return int(round(p.r * 255.0))
