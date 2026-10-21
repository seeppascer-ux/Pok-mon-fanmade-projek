class_name SaveSystem
extends RefCounted

## API save/load terpusat (single slot v1): satu file user://savegame.json.
## Semua fungsi STATIC -- tidak perlu autoload, cukup panggil
## SaveSystem.has_save() / SaveSystem.save_game(...) dari mana saja.
##
## Format file (JSON):
## {
##   "format_version": 1,
##   "playtime_seconds": 1234.5,
##   "map_id": "world",
##   "player_position": [320.0, 160.0],
##   "party": [ {...PokemonInstance...}, ... ],
##   "bag": { "slots": [ {"item_path": ..., "item_name": ..., "qty": n} ] },
##   "pokedex": { "seen": [1, 4], "caught": [1] },
##   "pc_box": { "stored": [ {...PokemonInstance...} ] }
## }
##
## Loading defensif: file hilang/rusak/versi tak dikenal -> return false +
## get_last_error() berisi pesan jelas. TIDAK PERNAH crash; game tetap bisa
## mulai baru.

const SAVE_PATH := "user://savegame.json"
const FORMAT_VERSION := 1
const DEFAULT_MAP_ID := "world"

static var _last_error: String = ""
## Hasil load_game() yang sukses, diambil world.gd lewat take_pending_load().
static var _pending: Dictionary = {}


static func get_last_error() -> String:
	return _last_error


static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


static func has_pending_load() -> bool:
	return not _pending.is_empty()


## Ambil data hasil load_game() sekaligus mengosongkan buffer internal,
## supaya world berikutnya tidak ke-load data basi.
static func take_pending_load() -> Dictionary:
	var data := _pending
	_pending = {}
	return data


## Simpan seluruh state game. Return true kalau berhasil ditulis.
static func save_game(party: Array[PokemonInstance], bag: Bag, pokedex: Pokedex,
		pc_box: PCBox, map_id: String, player_pos: Vector2,
		playtime_seconds: float) -> bool:
	_last_error = ""
	if party.is_empty():
		_last_error = "Party kosong, tidak ada yang disimpan."
		return false
	var party_arr: Array = []
	for mon in party:
		if mon != null and mon.species != null:
			party_arr.append(mon.to_dict())
	if party_arr.is_empty():
		_last_error = "Tidak ada Pokemon valid di party."
		return false
	var data := {
		"format_version": FORMAT_VERSION,
		"playtime_seconds": playtime_seconds,
		"map_id": map_id if map_id != "" else DEFAULT_MAP_ID,
		"player_position": [player_pos.x, player_pos.y],
		"party": party_arr,
		"bag": bag.to_dict() if bag != null else Bag.new().to_dict(),
		"pokedex": pokedex.to_dict() if pokedex != null else Pokedex.new().to_dict(),
		"pc_box": pc_box.to_dict() if pc_box != null else PCBox.new().to_dict(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		_last_error = "Gagal membuka file save untuk ditulis."
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	return true


## Auto-save: wrapper save_game buat titik-titik otomatis (selesai battle,
## selesai menangkap, pindah map). Dipanggil world.gd, bukan manual.
static func autosave(party: Array[PokemonInstance], bag: Bag, pokedex: Pokedex,
		pc_box: PCBox, map_id: String, player_pos: Vector2,
		playtime_seconds: float) -> bool:
	return save_game(party, bag, pokedex, pc_box, map_id, player_pos, playtime_seconds)


## Hook pindah map (dipakai world.notify_map_changed): catat map & posisi
## baru lalu auto-save. Siap dipakai begitu ada map kedua, dst.
static func notify_map_changed(map_id: String, player_pos: Vector2,
		party: Array[PokemonInstance], bag: Bag, pokedex: Pokedex,
		pc_box: PCBox, playtime_seconds: float) -> bool:
	return autosave(party, bag, pokedex, pc_box, map_id, player_pos, playtime_seconds)


## Baca & validasi file save. True -> data siap diambil take_pending_load().
## False -> get_last_error() menjelaskan kenapa (file hilang/rusak/versi
## tak dikenal/party tak valid). Tidak pernah crash.
static func load_game() -> bool:
	_last_error = ""
	_pending = {}
	if not FileAccess.file_exists(SAVE_PATH):
		_last_error = "File save tidak ditemukan."
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		_last_error = "Gagal membuka file save untuk dibaca."
		return false
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		_last_error = "File save rusak (bukan JSON yang valid)."
		return false
	var data: Dictionary = parsed
	if not data.has("format_version"):
		_last_error = "File save rusak (versi format tidak ditemukan)."
		return false
	var version := int(data["format_version"])
	if version != FORMAT_VERSION:
		_last_error = "Versi save %d tidak didukung (game ini memakai versi %d)." % [version, FORMAT_VERSION]
		return false

	var party: Array[PokemonInstance] = []
	var party_raw: Array = _as_array(data.get("party", []))
	for entry in party_raw:
		if entry is Dictionary:
			var mon := PokemonInstance.from_dict(entry)
			if mon != null:
				party.append(mon)
	if party.is_empty():
		_last_error = "File save rusak (party kosong/tidak valid)."
		return false

	# Bagian non-party bersifat defensif: kalau rusak, pakai default kosong
	# dan load tetap lanjut -- yang penting party selamat.
	var bag := Bag.from_dict(_as_dict(data.get("bag", {})))
	var dex := Pokedex.from_dict(_as_dict(data.get("pokedex", {})))
	var box := PCBox.from_dict(_as_dict(data.get("pc_box", {})))

	var pos := Vector2.ZERO
	var pos_raw: Array = _as_array(data.get("player_position", []))
	if pos_raw.size() >= 2:
		pos = Vector2(float(pos_raw[0]), float(pos_raw[1]))

	_pending = {
		"party": party,
		"bag": bag,
		"pokedex": dex,
		"pc_box": box,
		"map_id": str(data.get("map_id", DEFAULT_MAP_ID)),
		"player_pos": pos,
		"playtime": float(data.get("playtime_seconds", 0.0)),
	}
	return true


## Hapus file save. True juga kalau memang tidak ada file (tidak ada yang
## perlu dihapus). Dipakai menu utama saat konfirmasi "mulai baru".
static func delete_save() -> bool:
	_last_error = ""
	if not FileAccess.file_exists(SAVE_PATH):
		return true
	var err := DirAccess.remove_absolute(SAVE_PATH)
	if err != OK:
		_last_error = "Gagal menghapus file save."
		return false
	return true


static func _as_dict(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}


static func _as_array(value: Variant) -> Array:
	return value if value is Array else []
