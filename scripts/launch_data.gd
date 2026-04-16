# LaunchData.gd — Add this as an Autoload in Project > Project Settings > Autoload
extends Node

var avg_temp:     float = 0.0
var avg_wind:     float = 0.0
var avg_rain:     float = 0.0
var avg_cloud:    float = 0.0
var avg_humidity: float = 0.0
var elevation:    float = 0.0
var terrain:      String = ""
var latitude:     float = 0.0
var longitude:    float = 0.0
var status:       String = ""
var is_ready:     bool = false
var launch_requested: bool = false

# Manual input
var manual_lat:   float = 0.0
var manual_lon:   float = 0.0
var use_manual:   bool  = false
