class_name TallGrassZone
extends Area2D

## Tempel script ini ke sebuah Area2D (+ CollisionShape2D di dalamnya) yang
## menutupi area rumput tinggi / gua / air tempat Pokemon liar bisa muncul.
## world.gd otomatis menemukan semua zona ini lewat grup "tall_grass" --
## tidak perlu didaftarkan manual di tempat lain.
##
## Cara pakai:
## 1. Tambah node Area2D baru sebagai child dari "world", kasih nama
##    misalnya "RumputTinggi1".
## 2. Tempel script ini ke node itu.
## 3. Tambah CollisionShape2D di dalamnya, gambar area rumputnya.
## 4. Isi "Wild Encounters" di Inspector dengan Pokemon apa saja yang boleh
##    muncul di situ (klik Array > tambah elemen > New WildEncounter).

@export var wild_encounters: Array[WildEncounter] = []
@export_range(0.0, 1.0, 0.01) var encounter_chance: float = 0.1 ## peluang per 1 langkah

## true kalau player sedang berdiri di dalam zona ini.
var player_inside: bool = false


func _ready() -> void:
	add_to_group("tall_grass")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = false


## Dipanggil world.gd tiap kali player selesai 1 langkah & sedang di dalam
## zona ini. Return true kalau encounter beneran terjadi.
func roll_encounter() -> bool:
	if wild_encounters.is_empty():
		return false
	return randf() < encounter_chance


## Pilih 1 Pokemon liar secara acak (pakai weight) dan buatkan
## PokemonInstance baru yang siap dipakai battle (sudah setup_default()).
func pick_wild_pokemon() -> PokemonInstance:
	var total_weight: int = 0
	for entry in wild_encounters:
		total_weight += maxi(entry.weight, 1)

	var roll: int = randi() % maxi(total_weight, 1)
	var cumulative: int = 0
	var chosen: WildEncounter = wild_encounters[0]
	for entry in wild_encounters:
		cumulative += maxi(entry.weight, 1)
		if roll < cumulative:
			chosen = entry
			break

	var instance := PokemonInstance.new()
	instance.species = chosen.species
	instance.level = randi_range(chosen.min_level, chosen.max_level)
	instance.setup_default()
	return instance
