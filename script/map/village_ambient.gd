extends Node2D

## Suasana desa: daun-daun berjatuhan + kupu-kupu beterbangan.
## Tempel di node "Ambient" dalam scene/world.tscn.

## Area daun (pixel, world space) -- sekitar desa pertama.
@export var leaf_area: Rect2 = Rect2(350, 120, 950, 520)
@export var leaf_count: int = 36
## Posisi kupu-kupu (pixel, world space).
@export var butterfly_spots: Array[Vector2] = [
	Vector2(480, 280),
	Vector2(680, 380),
	Vector2(560, 200),
]


func _ready() -> void:
	_make_leaves()
	_make_butterflies()


func _make_leaves() -> void:
	var p := CPUParticles2D.new()
	p.amount = leaf_count
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = leaf_area.size * 0.5
	p.position = leaf_area.get_center()
	p.direction = Vector2(0.25, 1.0)
	p.spread = 20.0
	p.initial_velocity_min = 10.0
	p.initial_velocity_max = 26.0
	p.gravity = Vector2.ZERO
	p.damping_min = 0.0
	p.damping_max = 4.0
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.3
	p.color = Color(0.5, 0.78, 0.38, 0.9)
	p.texture = preload("res://asset/village/leaf.png")
	p.z_index = 5
	add_child(p)


func _make_butterflies() -> void:
	for spot in butterfly_spots:
		var b := Butterfly.new()
		b.position = spot
		b.flight_radius = randf_range(70.0, 110.0)
		b.flight_speed = randf_range(0.8, 1.2)
		add_child(b)
