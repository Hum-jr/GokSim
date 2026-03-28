# Earth.gd (on the MeshInstance3D)
extends MeshInstance3D

@export var drag_sensitivity: float = 0.3

var _is_dragging: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_is_dragging = event.pressed

	if event is InputEventMouseMotion and _is_dragging:
		var delta = event.relative
		rotate_y(deg_to_rad(-delta.x * drag_sensitivity))
		rotate_x(deg_to_rad(-delta.y * drag_sensitivity))
