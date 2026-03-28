extends RigidBody3D

@export var thrust_power: float = 50000.0
@export var wind_multiplier: float = 100.0

# --- NEW: Trajectory Controls ---
@export var gravity_turn_height: float = 100.0 # Height in meters to start the curve
@export var turn_speed: float = 0.3            # How fast the rocket tilts

var is_launched:   bool  = false
var air_density:   float = 1.225
var drag_scaled:   float = 0.47
var thrust_scaled: float = 50000.0


func _ready() -> void:
	# Force the global trigger to false so it MUST wait for the UI button
	LaunchData.launch_requested = false
	is_launched = false
	
	gravity_scale   = 0.0
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO # Prevent any pre-launch wobbling
	

		
	if LaunchData.is_ready:
		_apply_launch_conditions()

func _apply_launch_conditions() -> void:
	var temp_k   = LaunchData.avg_temp + 273.15
	var pressure = 101325.0 * exp(-LaunchData.elevation / 8500.0)
	air_density  = pressure / (287.05 * temp_k)
	air_density *= 1.0 - (LaunchData.avg_humidity / 100.0) * 0.02
	drag_scaled  = 0.47 * (air_density / 1.225)
	thrust_scaled = thrust_power * (1.0 + (1.225 - air_density) * 0.05)


# --- THE FAIL-SAFE LOGIC ---
func _check_launch_safety() -> bool:
	var safe = true
	
	# Evaluate exactly the same Launch Commit Criteria (LCC)
	if LaunchData.avg_wind > 10.0:
		print("[FLIGHT COMPUTER] ABORT: Wind speeds exceed structural limits (%.1f m/s)." % LaunchData.avg_wind)
		safe = false
	if LaunchData.avg_rain > 5.0:
		print("[FLIGHT COMPUTER] ABORT: Precipitation too heavy for thermal tiles.")
		safe = false
	if LaunchData.avg_cloud > 70.0:
		print("[FLIGHT COMPUTER] ABORT: Lightning risk detected. Cloud cover at %.1f%%." % LaunchData.avg_cloud)
		safe = false
	if LaunchData.avg_temp < 2.0 or LaunchData.avg_temp > 35.0:
		print("[FLIGHT COMPUTER] ABORT: Fuel temperature parameters out of bounds.")
		safe = false
		
	return safe


func _physics_process(_delta: float) -> void:
	if not is_launched:
		# Keep listening for the UI button click
		if LaunchData.launch_requested:
			
			# Check conditions right before ignition!
			if _check_launch_safety():
				_launch()
			else:
				# Force the trigger back to false so it doesn't get stuck trying to launch
				LaunchData.launch_requested = false
				print("[ROCKET] Launch sequence terminated by internal computer.")
				
		return

	# --- THE HYPERBOLIC FLIGHT PATH ---
	
	# A. Local Thrust
	var local_up = global_transform.basis.y.normalized()
	apply_central_force(local_up * thrust_scaled)
	
	# B. The "Gravity Turn"
	if global_position.y > gravity_turn_height:
		if rotation_degrees.z > -45.0:
			angular_velocity.z = -turn_speed
		else:
			angular_velocity.z = 0.0 
			
	# C. Environmental Forces 
	apply_central_force(Vector3(LaunchData.avg_wind * wind_multiplier, 0.0, 0.0))
	
	var drag_force = -linear_velocity.normalized() * (linear_velocity.length_squared() * drag_scaled * 0.1)
	if linear_velocity.length() > 0.1:
		apply_central_force(drag_force)

func _launch() -> void:
	is_launched   = true
	gravity_scale = 1.0 # Enable world gravity
	

		
	print("[ROCKET] Ignition! Commencing Gravity Turn profile.")
