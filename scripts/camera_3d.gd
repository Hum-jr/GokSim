extends Camera3D

# --- Inspector Variables ---
@export var target_mesh: Node3D
@export var drag_sensitivity: float = 0.005
@export var zoom_speed: float = 3.0
@export var min_zoom: float = 70.0
@export var max_zoom: float = 300.0
@export var min_pitch: float = 0.05

# --- Internal Variables ---
var is_dragging: bool = false
var yaw: float = 0.0
var pitch: float = 0.5
var camera_distance: float = 150.0

func _ready() -> void:
	if target_mesh:
		# Derive yaw, pitch, distance from actual world position
		var offset = global_position - target_mesh.global_position
		camera_distance = clamp(offset.length(), min_zoom, max_zoom)
		var dir = offset.normalized()
		pitch = asin(dir.y)
		yaw   = atan2(dir.x, dir.z)
		pitch = clamp(pitch, min_pitch, PI / 2 - 0.01)
	# No update_camera_position() call here — camera is already there

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			is_dragging = event.pressed
			get_viewport().set_input_as_handled()

		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			camera_distance = clamp(camera_distance - zoom_speed, min_zoom, max_zoom)
			update_camera_position()
			get_viewport().set_input_as_handled()

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			camera_distance = clamp(camera_distance + zoom_speed, min_zoom, max_zoom)
			update_camera_position()
			get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion and is_dragging:
		yaw   -= event.relative.x * drag_sensitivity
		pitch -= event.relative.y * drag_sensitivity
		pitch  = clamp(pitch, min_pitch, PI / 2 - 0.01)
		update_camera_position()
		get_viewport().set_input_as_handled()

func update_camera_position() -> void:
	if not target_mesh: return
	var offset = Vector3()
	offset.x = camera_distance * cos(pitch) * sin(yaw)
	offset.y = camera_distance * sin(pitch)
	offset.z = camera_distance * cos(pitch) * cos(yaw)
	global_position = target_mesh.global_position + offset
	look_at(target_mesh.global_position, Vector3.UP)
