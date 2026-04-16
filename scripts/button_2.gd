extends Button

# This creates a folder icon in the Inspector so you can easily pick your Globe scene!
@export_file("*.tscn") var place_selection_scene: String 

func _ready() -> void:
	# Connect the click event
	pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	print("[SYSTEM] Returning to Place Selection...")
	
	# 1. CRITICAL: Reset the global variables!
	# If we don't do this, the next rocket might auto-launch instantly.
	LaunchData.is_ready = false
	LaunchData.launch_requested = false
	
	# 2. Change the scene
	if place_selection_scene != "":
		get_tree().change_scene_to_file(place_selection_scene)
	else:
		print("[ERROR] You forgot to assign the scene path in the Inspector!")
