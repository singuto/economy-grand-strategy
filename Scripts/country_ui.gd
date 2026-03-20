extends Control
class_name CountryUiPanel

@onready var _flag: TextureRect = %FlagRect
@onready var _label: Label = %CountryNameLabel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()


func show_country(entry: CountryEntry) -> void:
	if entry == null:
		hide_panel()
		return
	_flag.texture = entry.flag
	_label.text = entry.display_name
	mouse_filter = Control.MOUSE_FILTER_STOP
	show()


func hide_panel() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()
