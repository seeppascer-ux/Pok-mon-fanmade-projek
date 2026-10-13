extends CharacterBody2D

## Dipancarkan setiap kali player selesai berpindah 1 kotak grid.
## Dipakai world.gd buat cek encounter Pokemon liar di rumput tinggi.
signal moved

## Ukuran satu kotak grid dalam pixel.
## HARUS SAMA dengan "Tile Size" di TileSet milikmu
## (cek: klik Worldmap -> Inspector -> Tile Set -> lihat Tile Size).
@export var tile_size: int = 16

## Lama waktu (detik) untuk berpindah 1 kotak. Kecilkan angka ini kalau mau player lebih cepat.
@export var move_time: float = 0.15

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var tilemap: TileMapLayer = get_node("../Worldmap")
@onready var objects_layer: TileMapLayer = get_node("../objek")
@onready var camera: Camera2D = $Camera2D

var is_moving := false
var input_direction := Vector2.ZERO
var facing := "down"
## true saat dialog NPC / cutscene: player tidak bisa digerakkan.
var input_locked := false

func _ready() -> void:
	add_to_group("player")
	# Pastikan player mulai tepat di tengah grid, bukan posisi sembarangan
	position = position.snapped(Vector2(tile_size, tile_size))
	_setup_camera_limits()

## Batasi Camera2D biar tidak nampilin area kosong di luar peta (misal pas
## player jalan mepet ke pinggir map). Dihitung OTOMATIS dari ukuran
## sebenarnya TileMapLayer "Worldmap" (pakai get_used_rect(), jadi kalau
## petanya diedit/diperbesar di editor, batas kamera ikut menyesuaikan
## sendiri tanpa perlu ubah angka manual di sini atau di Inspector).
func _setup_camera_limits() -> void:
	if camera == null or tilemap == null or tilemap.tile_set == null:
		return

	var used_rect: Rect2i = tilemap.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		return # peta kosong (belum ada tile) -- biarkan limit default

	var cell_size: Vector2 = Vector2(tilemap.tile_set.tile_size)
	var top_left: Vector2 = tilemap.to_global(Vector2(used_rect.position) * cell_size)
	var bottom_right: Vector2 = tilemap.to_global(
		Vector2(used_rect.position + used_rect.size) * cell_size
	)

	camera.limit_left = int(top_left.x)
	camera.limit_top = int(top_left.y)
	camera.limit_right = int(bottom_right.x)
	camera.limit_bottom = int(bottom_right.y)

func _physics_process(_delta: float) -> void:
	if input_locked:
		return
	if not is_moving and input_direction != Vector2.ZERO:
		_try_move(input_direction)

func _try_move(dir: Vector2) -> void:
	var target_pos: Vector2 = position + dir * tile_size
	if _can_move_to(target_pos):
		_move_to(target_pos)
	else:
		# Nabrak tembok: tetap hadap ke arah itu, tapi tidak jalan
		_face(dir)
		animated_sprite.play("idle_" + facing)
		_try_talk_to_npc(target_pos)


## Bump-to-talk: kalau kotak yang ditabrak ada NPC-nya, ajak bicara.
func _try_talk_to_npc(target_pos: Vector2) -> void:
	if input_locked:
		return
	for n in get_tree().get_nodes_in_group("npc"):
		var npc := n as Node2D
		if npc == null:
			continue
		if npc.position.distance_to(target_pos) < tile_size * 0.6:
			if npc.has_method("interact") and not bool(npc.get("talking")):
				npc.interact(self)
			break

func _can_move_to(target_pos: Vector2) -> bool:
	# Gunakan collision TileMapLayer secara langsung.
	# Jadi tile yang punya Physics Collision akan menghalangi Player.
	var motion := target_pos - global_position
	return not test_move(global_transform, motion)

func _move_to(target_pos: Vector2) -> void:
	is_moving = true
	animated_sprite.play("walk_" + facing)

	var tween := create_tween()
	tween.tween_property(self, "position", target_pos, move_time)
	tween.finished.connect(_on_move_finished)

func _on_move_finished() -> void:
	is_moving = false
	if input_direction == Vector2.ZERO:
		animated_sprite.play("idle_" + facing)
	moved.emit()

func _face(dir: Vector2) -> void:
	if dir == Vector2.UP:
		facing = "up"
	elif dir == Vector2.DOWN:
		facing = "down"
	elif dir == Vector2.LEFT:
		facing = "left"
	elif dir == Vector2.RIGHT:
		facing = "right"

# ------------------- Tombol UI -------------------

func _on_upbutton_button_down() -> void:
	if input_locked:
		return
	input_direction = Vector2.UP
	_face(Vector2.UP)

func _on_upbutton_button_up() -> void:
	if input_direction == Vector2.UP:
		input_direction = Vector2.ZERO

func _on_dwbutton_button_down() -> void:
	if input_locked:
		return
	input_direction = Vector2.DOWN
	_face(Vector2.DOWN)

func _on_dwbutton_button_up() -> void:
	if input_direction == Vector2.DOWN:
		input_direction = Vector2.ZERO

func _on_lbutton_button_down() -> void:
	if input_locked:
		return
	input_direction = Vector2.LEFT
	_face(Vector2.LEFT)

func _on_lbutton_button_up() -> void:
	if input_direction == Vector2.LEFT:
		input_direction = Vector2.ZERO

func _on_rbutton_button_down() -> void:
	if input_locked:
		return
	input_direction = Vector2.RIGHT
	_face(Vector2.RIGHT)

func _on_rbutton_button_up() -> void:
	if input_direction == Vector2.RIGHT:
		input_direction = Vector2.ZERO
