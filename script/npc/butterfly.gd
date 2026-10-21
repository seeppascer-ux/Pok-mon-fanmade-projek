class_name Butterfly
extends Node2D

## Kupu-kupu ambient: terbang pola lissajous di sekitar titik awal,
## sayap mengepak via scale.

@export var flight_radius: float = 90.0
@export var flight_speed: float = 1.0

var _home: Vector2
var _t: float = 0.0
var _phase: float = 0.0
var _sprite: Sprite2D


func _ready() -> void:
	_home = position
	_phase = randf() * TAU
	_t = randf() * 10.0
	_sprite = Sprite2D.new()
	_sprite.texture = preload("res://asset/village/butterfly.png")
	_sprite.z_index = 3
	add_child(_sprite)


func _process(delta: float) -> void:
	_t += delta * flight_speed
	var px: float = cos(_t * 0.6 + _phase) * flight_radius
	var py: float = sin(_t * 0.9 + _phase * 1.7) * flight_radius * 0.55
	position = _home + Vector2(px, py)
	# Kepak sayap: pipihkan horizontal berirama
	var flap: float = 0.65 + 0.35 * absf(sin(_t * 14.0))
	_sprite.scale = Vector2(flap, 1.0)
