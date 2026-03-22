extends Node3D

const ORBIT_SPEED_MOUSE := 0.0002
const ORBIT_SPEED_KEYS := 0.2
const ZOOM_SPEED := 0.05
const ZOOM_SPEED_KEYS := 2.0
const MIN_DISTANCE := 4.22
const MAX_DISTANCE := 7.0

const CLICK_DRAG_PX := 10.0
const CLICK_MAX_MS := 450

var _camera_pivot: Node3D
var _camera: Camera3D
var _distance: float
var _last_mouse_pos: Vector2
var _dragging := false
var _press_pos: Vector2
var _press_time_ms: int

@onready var _picker = $GlobeCountryPicker
@onready var _country_ui = $CountryUiLayer/CountryUiPanel


func _ready() -> void:
	_camera_pivot = $CameraPivot
	_camera = $CameraPivot/Camera3D
	_distance = _camera.position.z
	_last_mouse_pos = get_viewport().get_mouse_position()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				_dragging = true
				_press_pos = event.position
				_press_time_ms = Time.get_ticks_msec()
				_last_mouse_pos = event.position
			else:
				_dragging = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var zoom := ZOOM_SPEED * pow(_distance / MIN_DISTANCE, 1.5)
			_distance = clampf(_distance - zoom, MIN_DISTANCE, MAX_DISTANCE)
			_camera.position.z = _distance
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var zoom := ZOOM_SPEED * pow(_distance / MIN_DISTANCE, 1.5)
			_distance = clampf(_distance + zoom, MIN_DISTANCE, MAX_DISTANCE)
			_camera.position.z = _distance
	elif event is InputEventMouseMotion and _dragging:
		var delta = event.position - _last_mouse_pos
		_last_mouse_pos = event.position
		var speed := pow(_distance - (MIN_DISTANCE - 0.8), 3) * ORBIT_SPEED_MOUSE
		_camera_pivot.rotate_y(-delta.x * speed)
		_camera_pivot.rotate_object_local(Vector3.RIGHT, -delta.y * speed)


func _process(delta: float) -> void:
	var turn := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT):
		turn.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT):
		turn.x += 1.0
	if Input.is_key_pressed(KEY_UP):
		turn.y -= 1.0
	if Input.is_key_pressed(KEY_DOWN):
		turn.y += 1.0
	if turn != Vector2.ZERO:
		var speed := pow(_distance - (MIN_DISTANCE - 0.8), 3) * ORBIT_SPEED_KEYS * delta
		_camera_pivot.rotate_y(turn.x * speed)
		_camera_pivot.rotate_object_local(Vector3.RIGHT, turn.y * speed)

	if Input.is_key_pressed(KEY_PAGEUP):
		_distance = clampf(_distance - ZOOM_SPEED_KEYS * delta, MIN_DISTANCE, MAX_DISTANCE)
		_camera.position.z = _distance
	if Input.is_key_pressed(KEY_PAGEDOWN):
		_distance = clampf(_distance + ZOOM_SPEED_KEYS * delta, MIN_DISTANCE, MAX_DISTANCE)
		_camera.position.z = _distance
