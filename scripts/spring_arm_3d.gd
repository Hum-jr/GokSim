extends SpringArm3D

@export var zoom_speed: float = 20.0
@export var min_zoom: float = 20.0
@export var max_zoom: float = 1000.0
@export var drag_sensitivity: float = 0.005
@export var surface_hover_distance: float = 2.0

@onready var world_env: WorldEnvironment = get_tree().get_first_node_in_group("world_env")
# (requires you add WorldEnvironment to a group called "world_env" in the inspector)

var is_dragging: bool = false
var _click_start: Vector2 = Vector2.ZERO
var active_tween: Tween
var initial_basis: Basis

@onready var camera: Camera3D = $Camera3D
@onready var sim: Node = $"../SimulationManager"

func _ready() -> void:
	initial_basis = transform.basis
	spring_length = max_zoom

func _unhandled_input(event: InputEvent) -> void:
	# --- 1. KEYBOARD ---
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			reset_camera()

	# --- 2. MOUSE BUTTONS ---
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			is_dragging = event.pressed

		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_click_start = event.position
			else:
				# Only treat as click if mouse barely moved
				if event.position.distance_to(_click_start) < 5.0:
					shoot_ray(event.position)

		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if active_tween: active_tween.kill()
			spring_length = clamp(spring_length - zoom_speed, min_zoom, max_zoom)

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if active_tween: active_tween.kill()
			spring_length = clamp(spring_length + zoom_speed, min_zoom, max_zoom)

	# --- 3. DRAG ROTATION ---
	elif event is InputEventMouseMotion and is_dragging:
		global_rotate(Vector3.UP, -event.relative.x * drag_sensitivity)
		global_rotate(transform.basis.x, -event.relative.y * drag_sensitivity)
		transform.basis = transform.basis.orthonormalized()

func shoot_ray(mouse_pos: Vector2):
	var space_state = get_world_3d().direct_space_state
	var origin = camera.project_ray_origin(mouse_pos)
	var end    = origin + camera.project_ray_normal(mouse_pos) * 2000.0
	var query  = PhysicsRayQueryParameters3D.create(origin, end)
	var result = space_state.intersect_ray(query)

	if result:
		var hit_point = result.position
		cinematic_zoom_to(hit_point)
		# Tell SimulationManager about the click
		if sim:
			sim.on_globe_clicked(hit_point)

func cinematic_zoom_to(target_point: Vector3):
	if active_tween and active_tween.is_running():
		active_tween.kill()

	active_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var safe_up = Vector3.UP
	if abs(target_point.normalized().y) > 0.99:
		safe_up = Vector3.RIGHT

	var target_transform = transform.looking_at(-target_point, safe_up)
	var perfect_zoom_distance = target_point.length() + surface_hover_distance

	active_tween.tween_property(self, "quaternion", target_transform.basis.get_rotation_quaternion(), 1.0)
	active_tween.tween_property(self, "spring_length", perfect_zoom_distance, 1.0)

func reset_camera():
	if active_tween and active_tween.is_running():
		active_tween.kill()

	active_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.tween_property(self, "quaternion", initial_basis.get_rotation_quaternion(), 1.0)
	active_tween.tween_property(self, "spring_length", max_zoom, 1.0)
	
func _process(_delta: float) -> void:
	if world_env and world_env.environment and world_env.environment.sky:
		var yaw := global_transform.basis.get_euler().y
		world_env.environment.sky_rotation = Vector3(0.0, yaw, 0.0)
