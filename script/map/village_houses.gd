extends Node2D

## Menambah rumah-rumah desa secara programmatic saat scene dimuat.
## Lebih aman daripada mengedit tile_map_data (PackedByteArray) manual.
##
## Memakai big-tile yang SUDAH didefinisikan di TileSet layer ini:
## - atap  : atlas (0,42), ukuran 16x7 tile
## - badan : atlas (0,49), ukuran 16x15 tile (sudah punya collision)
## Rumah asli di tscn memakai pola yang sama: badan 11 tile di bawah atap.

const ROOF_ATLAS: Vector2i = Vector2i(0, 42)
const BODY_ATLAS: Vector2i = Vector2i(0, 49)
const BODY_Y_OFFSET: int = 11
const SOURCE_ID: int = 0

## Sudut kiri-atas ATAP tiap rumah tambahan (dalam tile).
## Dipilih di area kosong: tidak menutupi objek, tidak di rumput tinggi,
## tidak menutupi spawn player (36,20) maupun rumah asli (77,21).
const HOUSES: Array[Vector2i] = [
	Vector2i(50, 15),
	Vector2i(20, 25),
]

@onready var layer: TileMapLayer = $TileMapLayer


func _ready() -> void:
	if layer == null:
		push_warning("village_houses: TileMapLayer tidak ketemu")
		return
	for h in HOUSES:
		layer.set_cell(h, SOURCE_ID, ROOF_ATLAS)
		var body_cell: Vector2i = h + Vector2i(0, BODY_Y_OFFSET)
		layer.set_cell(body_cell, SOURCE_ID, BODY_ATLAS)
		_add_body_collision(body_cell)


## StaticBody eksplisit untuk badan rumah (16x15 tile).
## Dipakai karena collision polygon bawaan tile tidak selalu aktif
## di physics space; cara ini dijamin menghalangi player.
func _add_body_collision(body_cell: Vector2i) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(body_cell) * 16.0 + Vector2(128, 120)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(252, 236)
	col.shape = shape
	body.add_child(col)
	add_child(body)
