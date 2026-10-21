class_name Pokedex
extends Resource

## Data Pokedex milik player: species mana aja yang PERNAH DILIHAT (seen -
## misal ketemu di rumput tinggi walau belum ditangkap) dan yang PERNAH
## DITANGKAP/DIMILIKI (caught). Disimpan sebagai PokemonSpecies.species_id,
## BUKAN posisi file di folder data/species/, supaya tetap valid walau
## urutan file berubah.
##
## Cara pakai (biasanya otomatis lewat world.gd, tidak perlu manual):
##   pokedex.mark_seen(wild_pokemon.species)     -- begitu ketemu liar
##   pokedex.mark_caught(caught_pokemon.species) -- begitu berhasil ditangkap

@export var seen_ids: Array[int] = []
@export var caught_ids: Array[int] = []


## Tandai 1 spesies sebagai "pernah dilihat". Aman dipanggil berkali-kali
## buat spesies yang sama (tidak akan dobel di array).
func mark_seen(species: PokemonSpecies) -> void:
	if species == null:
		return
	if not seen_ids.has(species.species_id):
		seen_ids.append(species.species_id)


## Tandai 1 spesies sebagai "pernah ditangkap" -- otomatis juga menandai
## "pernah dilihat" (logis: tidak mungkin nangkep tanpa pernah lihat).
func mark_caught(species: PokemonSpecies) -> void:
	if species == null:
		return
	mark_seen(species)
	if not caught_ids.has(species.species_id):
		caught_ids.append(species.species_id)


func is_seen(species_id: int) -> bool:
	return seen_ids.has(species_id)


func is_caught(species_id: int) -> bool:
	return caught_ids.has(species_id)


## ---------------------------------------------------------------------
## SAVE / LOAD (dipakai SaveSystem)
## ---------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"seen": seen_ids.duplicate(), "caught": caught_ids.duplicate()}


static func from_dict(d: Dictionary) -> Pokedex:
	var dex := Pokedex.new()
	for value in d.get("seen", []):
		var sid := int(value)
		if not dex.seen_ids.has(sid):
			dex.seen_ids.append(sid)
	for value in d.get("caught", []):
		var sid := int(value)
		if not dex.caught_ids.has(sid):
			dex.caught_ids.append(sid)
	return dex
