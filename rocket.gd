extends RigidBody3D

@export var thrust_power: float = 50000.0 # Force in Newtons
@export var wind_multiplier: float = 100.0 # Increased so wind actually pushes the heavy rocket

var is_launched:   bool  = false
var air_density:   float = 1.225
var drag_scaled:   float = 0.47
var thrust_scaled: float = 50000.0

@onready var smoke_particles: GPUParticles3D = $GPUParticles3D # Make sure your smoke node is here!

func _ready() -> void:
	gravity_scale   = 0.0
	linear_velocity = Vector3.ZERO
	
	if smoke_particles:
		smoke_particles.emitting = false
		
	print("[ROCKET] Ready. is_ready=", LaunchData.is_ready, " launch_requested=", LaunchData.launch_requested)
	
	if LaunchData.is_ready:
		_apply_launch_conditions()

func _apply_launch_conditions() -> void:
	# 1. Barometric Pressure & Ideal Gas Law Math (Excellent work here!)
	var temp_k   = LaunchData.avg_temp + 273.15
	var pressure = 101325.0 * exp(-LaunchData.elevation / 8500.0)
	air_density  = pressure / (287.05 * temp_k)
	
	# 2. Humidity adjustment
	air_density *= 1.0 - (LaunchData.avg_humidity / 100.0) * 0.02
	
	# 3. Dynamic Drag and Thrust
	drag_scaled  = 0.47 * (air_density / 1.225)
	thrust_scaled = thrust_power * (1.0 + (1.225 - air_density) * 0.05)

	print("--- FLIGHT DYNAMICS ---")
	print("Air density: %.4f kg/m³" % air_density)
	print("Thrust:      %.1f N"     % thrust_scaled)
	print("Drag Coeff:  %.3f"       % drag_scaled)
	print("-----------------------")

func _physics_process(_delta: float) -> void: # Changed 'delta' to '_delta' since we don't need it
	if not is_launched:
		if LaunchData.launch_requested:
			_launch()
		return

	# --- THE CORRECTED PHYSICS ---
	
	# 1. Wind Force (Pushing on the X axis)
	apply_central_force(Vector3(LaunchData.avg_wind * wind_multiplier, 0.0, 0.0))
	
	# 2. Main Engine Thrust (Pushing UP) - Removed '* delta'
	apply_central_force(Vector3(0.0, thrust_scaled, 0.0))
	
	# 3. Aerodynamic Drag (Opposing current movement direction)
	# Using velocity squared for more realistic high-speed drag!
	var drag_force = -linear_velocity.normalized() * (linear_velocity.length_squared() * drag_scaled * 0.1)
	if linear_velocity.length() > 0.1: # Only apply if moving to prevent jitter
		apply_central_force(drag_force)

func _launch() -> void:
	is_launched   = true
	LaunchData.launch_requested = false
	gravity_scale = 1.0 # Let gravity take over!
	
	if smoke_particles:
		smoke_particles.emitting = true
		
	print("[ROCKET] Ignition! Liftoff!")
