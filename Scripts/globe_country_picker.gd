extends Node
class_name GlobeCountryPicker

@export var globe_path: NodePath = ^"Globe"
@export var country_database: CountryDatabase
@export var id_map_path: String = "res://Data/CountryIdMap.png"

var _id_image: Image
var _globe: Node3D


func _ready() -> void:
	_globe = get_node_or_null(globe_path) as Node3D
	var tex: Texture2D = load(id_map_path) as Texture2D
	if tex == null:
		push_error("GlobeCountryPicker: could not load id map texture: %s" % id_map_path)
		_id_image = Image.create(1, 1, false, Image.FORMAT_R8)
		_id_image.fill(Color.BLACK)
		return
	_id_image = tex.get_image()
	if _id_image == null or _id_image.is_empty():
		push_error("GlobeCountryPicker: id map has no Image data: %s" % id_map_path)
		_id_image = Image.create(1, 1, false, Image.FORMAT_R8)
		_id_image.fill(Color.BLACK)


func pick_country_id_at_screen(camera: Camera3D, screen_pos: Vector2) -> int:
	if _globe == null or camera == null or _id_image.is_empty():
		return 0
	var ray_origin := camera.project_ray_origin(screen_pos)
	var ray_dir := camera.project_ray_normal(screen_pos)
	var to := ray_origin + ray_dir * 1.0e4
	var hitq := PhysicsRayQueryParameters3D.create(ray_origin, to)
	hitq.collide_with_areas = false
	var w3 := get_viewport().world_3d
	if w3 == null:
		return 0
	var space: PhysicsDirectSpaceState3D = w3.direct_space_state
	var hit: Dictionary = space.intersect_ray(hitq)
	if hit.is_empty():
		return 0
	var local: Vector3 = _globe.to_local(hit.position)
	var uv := GlobeMapCoords.direction_to_equirect_uv(local)
	return GlobeMapCoords.country_id_at_uv(_id_image, uv)


func get_entry(country_id: int) -> CountryEntry:
	if country_database == null:
		return null
	return country_database.get_entry(country_id)
