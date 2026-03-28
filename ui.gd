extends Control

@onready var label_location:  Label = $Location
@onready var label_wind:      Label = $Ruzgar
@onready var label_temp:      Label = $Sicaklik
@onready var label_rain:      Label = $Yagis
@onready var label_cloud:     Label = $Bulut
@onready var label_humidity:  Label = $Nem
@onready var label_elevation: Label = $Yukkseklik

@onready var launch_button: Button = $Button

var _was_ready: bool = false

func _process(_delta: float) -> void:
	if LaunchData.is_ready and not _was_ready:
		_was_ready = true
		_update_labels()

func _update_labels() -> void:
	label_location.text  = "YER: %.2f° / %.2f°"        % [LaunchData.latitude, LaunchData.longitude]
	label_wind.text      = "RÜZGAR HIZI: %.1f m/s"      % LaunchData.avg_wind
	label_temp.text      = "SICAKLIK: %.1f °C"           % LaunchData.avg_temp
	label_rain.text      = "YAĞIŞ: %.2f mm/day"          % LaunchData.avg_rain
	label_cloud.text     = "BULUT: %.1f %%"              % LaunchData.avg_cloud
	label_humidity.text  = "NEM: %.1f %%"                % LaunchData.avg_humidity
	label_elevation.text = "YUKSEKLIK: %.0f m — %s"      % [LaunchData.elevation, LaunchData.terrain]
	
	
	

func _ready() -> void:
	launch_button.pressed.connect(_on_launch_pressed)

func _on_launch_pressed() -> void:
	if LaunchData.is_ready:
		LaunchData.launch_requested = true
		print("[UI] Launch requested!")
	else:
		print("[UI] Data not ready yet — select a location first.")
		launch_button.text = "Select location first!"
