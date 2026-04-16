extends Node3D

@export var cloud_scene: PackedScene  # Drag your Cloud.tscn mesh here!
@export var cloud_count: int = 50     # How many clouds to spawn
@export var spawn_radius: float = 500.0 # How far out they spread
@export var min_height: float = 100.0   # Minimum altitude (pixels/units above ground)
@export var max_height: float = 250.0   # Maximum altitude
@export var min_scale: float = 5.0      # Smallest cloud size
@export var max_scale: float = 20.0     # Biggest cloud size

func _ready() -> void:
	spawn_clouds()

func spawn_clouds() -> void:
	if not cloud_scene:
		print("[ERROR] No Cloud Scene assigned to CloudManager!")
		return

	for i in range(cloud_count):
		# 1. Create a new instance of your cloud mesh
		var cloud = cloud_scene.instantiate()
		add_child(cloud)
		
		# 2. Randomize Position
		var random_x = randf_range(-spawn_radius, spawn_radius)
		var random_z = randf_range(-spawn_radius, spawn_radius)
		var random_y = randf_range(min_height, max_height)
		
		cloud.position = Vector3(random_x, random_y, random_z)
		
		# 3. Randomize Scale (Uniform scaling so they don't look stretched)
		var s = randf_range(min_scale, max_scale)
		cloud.scale = Vector3(s, s, s)
		
		# 4. Randomize Rotation (Makes the same mesh look like different clouds)
		cloud.rotation.y = randf_range(0, TAU) # TAU is 360 degrees in radians
		
		# 5. Optional: Randomize Transparency/Color slightly
		# if cloud is a MeshInstance3D:
		#    cloud.set_instance_shader_parameter("seed", randf())
