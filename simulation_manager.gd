extends Node3D

@onready var nasa_api: HTTPRequest      = $NasaAPI
@onready var elevation_api: HTTPRequest = $ElevationAPI
@onready var lat_input: LineEdit        = $"../Control/Label/Lat"
@onready var lon_input: LineEdit        = $"../Control/Label/Lon"
@onready var confirm_btn: Button        = $"../Control/Button"

@export var marker_scene: PackedScene
@export var globe_radius: float = 1.0

var current_marker: Node3D = null
var _last_lat: float = 0.0
var _last_lon: float = 0.0
var _nasa_done: bool = false
var _elevation_done: bool = false

func _ready() -> void:
	$"../Control".mouse_filter = Control.MOUSE_FILTER_PASS
	$"../Control/Label".mouse_filter = Control.MOUSE_FILTER_PASS
	lat_input.mouse_filter = Control.MOUSE_FILTER_STOP
	lon_input.mouse_filter = Control.MOUSE_FILTER_STOP
	confirm_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	
	if nasa_api:
		nasa_api.request_completed.connect(_on_weather_received)
		nasa_api.set_tls_options(TLSOptions.client_unsafe())
	if elevation_api:
		elevation_api.request_completed.connect(_on_elevation_received)
		elevation_api.set_tls_options(TLSOptions.client_unsafe())
		
	if confirm_btn:
		confirm_btn.pressed.connect(_on_confirm_pressed)
		
	if lat_input and lon_input:
		lat_input.placeholder_text = "Enlem (-90 / 90)"
		lon_input.placeholder_text = "Boylam (-180 / 180)"

func on_globe_clicked(hit_position: Vector3) -> void:
	var coords = vector3_to_lat_lon(hit_position)
	_last_lat  = coords.x
	_last_lon  = coords.y
	
	if lat_input and lon_input:
		lat_input.text = "%.4f" % _last_lat
		lon_input.text = "%.4f" % _last_lon
		
	place_marker(hit_position)
	_start_fetch(_last_lat, _last_lon)

func _on_confirm_pressed() -> void:
	var lat_text = lat_input.text.strip_edges()
	var lon_text = lon_input.text.strip_edges()
	if lat_text.is_empty() or lon_text.is_empty(): return
	if not lat_text.is_valid_float() or not lon_text.is_valid_float(): return
	
	var lat = lat_text.to_float()
	var lon = lon_text.to_float()
	if lat < -90.0 or lat > 90.0: return
	if lon < -180.0 or lon > 180.0: return
	
	_last_lat = lat
	_last_lon = lon
	place_marker(lat_lon_to_vector3(lat, lon))
	_start_fetch(lat, lon)

func _start_fetch(lat: float, lon: float) -> void:
	LaunchData.is_ready = false
	_nasa_done          = false
	_elevation_done     = false
	
	print("[SYSTEM] Fetching Live Weather (NOAA GFS)...")
	var w_url = "https://api.open-meteo.com/v1/forecast?latitude=%s&longitude=%s&current=temperature_2m,relative_humidity_2m,precipitation,cloud_cover,wind_speed_10m" % [str(lat), str(lon)]
	if nasa_api: nasa_api.request(w_url)

	print("[SYSTEM] Fetching Elevation Data...")
	var e_url = "https://api.open-meteo.com/v1/elevation?latitude=%s&longitude=%s" % [str(lat), str(lon)]
	if elevation_api: elevation_api.request(e_url)

func _on_weather_received(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	if response_code != 200: 
		print("⚠️ [NETWORK ERROR] Using SMART simulated fallback data.")
		LaunchData.avg_temp     = (35.0 - (abs(_last_lat) * 0.6)) + randf_range(-4.0, 4.0) 
		LaunchData.avg_wind     = randf_range(2.0, 12.0)
		LaunchData.avg_rain     = randf_range(2.0, 8.0) if (abs(_last_lat) < 15.0 or abs(_last_lat) > 50.0) else randf_range(0.0, 2.0)
		LaunchData.avg_cloud    = randf_range(40.0, 90.0) if (abs(_last_lat) < 15.0 or abs(_last_lat) > 50.0) else randf_range(10.0, 40.0)
		LaunchData.avg_humidity = randf_range(30.0, 70.0)
		LaunchData.status       = "⚠️ Simüle Edilmiş Veri"
	else:
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var current = json.get_data()["current"]
			LaunchData.avg_temp     = current["temperature_2m"]
			LaunchData.avg_wind     = current["wind_speed_10m"]
			LaunchData.avg_rain     = current["precipitation"]
			LaunchData.avg_cloud    = current["cloud_cover"]
			LaunchData.avg_humidity = current["relative_humidity_2m"]
			
			LaunchData.status = "✅ Fırlatmaya Uygun (GO)"
			if LaunchData.avg_wind > 10.0:       LaunchData.status = "⚠️ İPTAL: Şiddetli Rüzgar"
			elif LaunchData.avg_rain > 5.0:      LaunchData.status = "🌧️ İPTAL: Yağış Riski"
			elif LaunchData.avg_cloud > 70.0:    LaunchData.status = "☁️ İPTAL: Yıldırım/Bulut Riski"
			elif LaunchData.avg_humidity > 80.0: LaunchData.status = "💧 İPTAL: Yüksek Nem"
			
	LaunchData.latitude  = _last_lat
	LaunchData.longitude = _last_lon
	_nasa_done = true
	_check_launch_data_complete()

func _on_elevation_received(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	if response_code != 200: 
		LaunchData.elevation = randf_range(0.0, 1500.0)
		LaunchData.terrain   = "Arazi (Simüle)"
	else:
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			LaunchData.elevation = json.get_data()["elevation"][0]
			LaunchData.terrain   = "Lowland"
			if LaunchData.elevation > 3000:    LaunchData.terrain = "High Mountain"
			elif LaunchData.elevation > 1000:  LaunchData.terrain = "Mountain"
			elif LaunchData.elevation > 200:   LaunchData.terrain = "Highland"
			elif LaunchData.elevation < 0:     LaunchData.terrain = "Below Sea Level"
			
	_elevation_done = true
	_check_launch_data_complete()

func _check_launch_data_complete() -> void:
	if _nasa_done and _elevation_done:
		if LaunchData.is_ready: return 
		LaunchData.is_ready = true
		print("[LAUNCH DATA] Ready. Switching to Launch Scene in 5 seconds...")
		await get_tree().create_timer(5.0).timeout
		get_tree().change_scene_to_file("res://base.tscn")

func place_marker(pos: Vector3):
	if marker_scene:
		if not current_marker:
			current_marker = marker_scene.instantiate()
			get_tree().root.add_child(current_marker)
		current_marker.global_position = pos
		current_marker.look_at(pos * 2, Vector3.UP)

func lat_lon_to_vector3(lat: float, lon: float) -> Vector3:
	var lat_rad = deg_to_rad(lat)
	var lon_rad = deg_to_rad(lon)
	return Vector3(globe_radius * cos(lat_rad) * sin(lon_rad), globe_radius * sin(lat_rad), globe_radius * cos(lat_rad) * cos(lon_rad))

func vector3_to_lat_lon(point: Vector3) -> Vector2:
	var dir = point.normalized()
	var longitude = rad_to_deg(atan2(dir.x, dir.z)) + 180.0
	if longitude > 180: longitude -= 360
	elif longitude < -180: longitude += 360
	return Vector2(rad_to_deg(asin(dir.y)), longitude)
