class_name NPC
extends CharacterBody2D

## Warga desa: jalan-jalan santai di sekitar titik awal, bisa diajak bicara
## dengan cara menabraknya (bump-to-talk, karena kontrolnya D-pad).
## Sprite diambil dari asset/Autotiles/n.png yang sama dengan player,
## dibedakan lewat tint warna.

@export var npc_name: String = "Warga"
@export var dialogue_lines: Array[String] = ["Halo!"]
@export var tint: Color = Color.WHITE
@export var wander_enabled: bool = true
## Jarak maksimal (dalam tile) dari titik awal saat wandering.
@export var wander_radius_tiles: int = 3

const SHEET: Texture2D = preload("res://asset/Autotiles/n.png")
const CELL: int = 64
const TILE: int = 16
const STEP_TIME: float = 0.18
## Urutan baris di spritesheet: 0=down, 1=left, 2=right, 3=up.
const DIRS: Array[String] = ["down", "left", "right", "up"]
const DIR_VEC: Array[Vector2] = [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.UP]

var facing: String = "down"
var talking: bool = false

var _home: Vector2
var _sprite: AnimatedSprite2D
var _bubble: PanelContainer
var _bubble_label: Label


func _ready() -> void:
	add_to_group("npc")
	position = position.snapped(Vector2(TILE, TILE))
	_home = position
	z_index = 2
	_build_collision()
	_build_sprite()
	_build_bubble()
	_sprite.play("idle_down")
	_wander_loop()


func _build_collision() -> void:
	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(12, 12)
	col.shape = shape
	col.position = Vector2(0, 10)
	add_child(col)


func _cell(col: int, row: int) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = SHEET
	at.region = Rect2(col * CELL, row * CELL, CELL, CELL)
	return at


func _build_sprite() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "AnimatedSprite2D"
	var frames := SpriteFrames.new()
	for r in range(4):
		var d: String = DIRS[r]
		frames.add_animation("idle_" + d)
		frames.add_frame("idle_" + d, _cell(0, r))
		frames.set_animation_speed("idle_" + d, 8)
		frames.add_animation("walk_" + d)
		for c in range(4):
			frames.add_frame("walk_" + d, _cell(c, r))
		frames.set_animation_speed("walk_" + d, 8)
	_sprite.frames = frames
	_sprite.modulate = tint
	_sprite.position = Vector2(0, -8)
	add_child(_sprite)


func _build_bubble() -> void:
	_bubble = PanelContainer.new()
	_bubble.name = "Bubble"
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.96)
	sb.border_color = Color(0.15, 0.2, 0.3, 1)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	_bubble.add_theme_stylebox_override("panel", sb)
	_bubble_label = Label.new()
	_bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble_label.custom_minimum_size = Vector2(190, 0)
	_bubble_label.add_theme_font_size_override("font_size", 14)
	_bubble_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.15, 1))
	_bubble.add_child(_bubble_label)
	_bubble.position = Vector2(-105, -108)
	_bubble.z_index = 20
	_bubble.visible = false
	add_child(_bubble)


func _face_toward(target: Vector2) -> void:
	var d: Vector2 = target - position
	if absf(d.x) > absf(d.y):
		facing = "right" if d.x > 0 else "left"
	else:
		facing = "down" if d.y > 0 else "up"


## Dipanggil player saat menabrak NPC ini.
func interact(player: Node2D) -> void:
	if talking:
		return
	talking = true
	_face_toward(player.position)
	_sprite.play("idle_" + facing)
	if player.has_method("set"):
		player.set("input_locked", true)
	_bubble.visible = true
	for line in dialogue_lines:
		_bubble_label.text = line
		await get_tree().create_timer(2.6).timeout
		if not is_inside_tree():
			return
	_bubble.visible = false
	if is_instance_valid(player) and player.has_method("set"):
		player.set("input_locked", false)
	talking = false


func _wander_loop() -> void:
	while is_inside_tree():
		await get_tree().create_timer(randf_range(1.6, 3.6)).timeout
		if not is_inside_tree() or talking or not wander_enabled:
			continue
		if randf() < 0.7:
			var dir: Vector2 = DIR_VEC[randi() % 4]
			await _try_step(dir)


func _try_step(dir: Vector2) -> void:
	_face(dir)
	var target: Vector2 = position + dir * TILE
	# Jangan keluar dari radius wandering
	if (target - _home).length() > wander_radius_tiles * TILE + 1.0:
		return
	if test_move(global_transform, target - global_position):
		return
	_sprite.play("walk_" + facing)
	var tween := create_tween()
	tween.tween_property(self, "position", target, STEP_TIME)
	await tween.finished
	if is_inside_tree():
		_sprite.play("idle_" + facing)


func _face(dir: Vector2) -> void:
	if dir == Vector2.UP:
		facing = "up"
	elif dir == Vector2.DOWN:
		facing = "down"
	elif dir == Vector2.LEFT:
		facing = "left"
	elif dir == Vector2.RIGHT:
		facing = "right"
