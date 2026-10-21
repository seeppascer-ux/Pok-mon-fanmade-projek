class_name SaveLookup
extends RefCounted

## Resolver resource buat sistem save/load: mengubah id/path yang tersimpan
## di JSON kembali menjadi resource aslinya. Hasil scan di-cache supaya
## folder cuma dibaca sekali per sesi. Semua fungsi defensif -- return null
## kalau tidak ketemu, tidak pernah crash.

const SPECIES_DIR := "res://data/species/"
const ITEMS_DIR := "res://data/items/"
const MOVES_DIR := "res://data/moves/"
const ABILITIES_DIR := "res://data/abilities/"

static var _species_cache: Dictionary = {}
static var _species_scanned: bool = false
static var _item_cache: Dictionary = {}
static var _items_scanned: bool = false
static var _move_cache: Dictionary = {}
static var _moves_scanned: bool = false
static var _ability_cache: Dictionary = {}
static var _abilities_scanned: bool = false


## Cari PokemonSpecies berdasarkan species_id (kunci stabil lintas sesi,
## tidak tergantung urutan/nama file).
static func species_by_id(species_id: int) -> PokemonSpecies:
	if not _species_scanned:
		_scan_species()
	return _species_cache.get(species_id)


static func _scan_species() -> void:
	_species_scanned = true
	_species_cache.clear()
	var dir := DirAccess.open(SPECIES_DIR)
	if dir == null:
		return
	for file_name in dir.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var res := load(SPECIES_DIR + file_name) as PokemonSpecies
		if res != null:
			_species_cache[res.species_id] = res


## Item diidentifikasi lewat resource_path (unik & stabil). Fallback ke
## item_by_name kalau path-nya kosong/tidak ketemu.
static func item_by_path(path: String) -> ItemData:
	if not _items_scanned:
		_scan_items()
	return _item_cache.get(path)


static func item_by_name(item_name: String) -> ItemData:
	if not _items_scanned:
		_scan_items()
	for key in _item_cache:
		var item: ItemData = _item_cache[key]
		if item.item_name == item_name:
			return item
	return null


static func _scan_items() -> void:
	_items_scanned = true
	_item_cache.clear()
	var dir := DirAccess.open(ITEMS_DIR)
	if dir == null:
		return
	for file_name in dir.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var res := load(ITEMS_DIR + file_name) as ItemData
		if res != null:
			_item_cache[res.resource_path] = res


static func move_by_path(path: String) -> MoveData:
	if not _moves_scanned:
		_scan_moves()
	return _move_cache.get(path)


static func move_by_name(move_name: String) -> MoveData:
	if not _moves_scanned:
		_scan_moves()
	for key in _move_cache:
		var move: MoveData = _move_cache[key]
		if move.move_name == move_name:
			return move
	return null


static func _scan_moves() -> void:
	_moves_scanned = true
	_move_cache.clear()
	var dir := DirAccess.open(MOVES_DIR)
	if dir == null:
		return
	for file_name in dir.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var res := load(MOVES_DIR + file_name) as MoveData
		if res != null:
			_move_cache[res.resource_path] = res


static func ability_by_path(path: String) -> AbilityData:
	if not _abilities_scanned:
		_scan_abilities()
	return _ability_cache.get(path)


static func ability_by_name(ability_name: String) -> AbilityData:
	if not _abilities_scanned:
		_scan_abilities()
	for key in _ability_cache:
		var ability: AbilityData = _ability_cache[key]
		if ability.ability_name == ability_name:
			return ability
	return null


static func _scan_abilities() -> void:
	_abilities_scanned = true
	_ability_cache.clear()
	var dir := DirAccess.open(ABILITIES_DIR)
	if dir == null:
		return
	for file_name in dir.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var res := load(ABILITIES_DIR + file_name) as AbilityData
		if res != null:
			_ability_cache[res.resource_path] = res
