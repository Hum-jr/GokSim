extends Control

@onready var lat_input:   LineEdit = $Label/Lat
@onready var lon_input:   LineEdit = $Label/Lon
@onready var confirm_btn: Button   = $Button

func _ready() -> void:
	lat_input.placeholder_text = "Enlem (-90 / 90)"
	lon_input.placeholder_text = "Boylam (-180 / 180)"
	confirm_btn.pressed.connect(_on_confirm_pressed)

	if LaunchData.manual_lat != 0.0:
		lat_input.text = str(LaunchData.manual_lat)
	if LaunchData.manual_lon != 0.0:
		lon_input.text = str(LaunchData.manual_lon)

func _on_confirm_pressed() -> void:
	var lat_text = lat_input.text.strip_edges()
	var lon_text = lon_input.text.strip_edges()
	if lat_text.is_empty() or lon_text.is_empty():
		print("[INPUT] Lütfen her iki alanı da doldurun.")
		return
	if not lat_text.is_valid_float() or not lon_text.is_valid_float():
		print("[INPUT] Lütfen geçerli sayılar girin.")
		return
	var lat = lat_text.to_float()
	var lon = lon_text.to_float()
	if lat < -90.0 or lat > 90.0:
		print("[INPUT] Enlem -90 ile 90 arasında olmalıdır.")
		return
	if lon < -180.0 or lon > 180.0:
		print("[INPUT] Boylam -180 ile 180 arasında olmalıdır.")
		return
	LaunchData.manual_lat = lat
	LaunchData.manual_lon = lon
	LaunchData.use_manual  = true
	print("[INPUT] Koordinatlar girildi: %.4f, %.4f" % [lat, lon])
	get_tree().change_scene_to_file("res://base.tscn")  # 👈 add this, adjust path if needed
