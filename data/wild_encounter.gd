class_name WildEncounter
extends Resource

## Satu baris di "tabel encounter" milik sebuah TallGrassZone.
## Contoh: Pikachu, level 2-5, weight 1 -> makin besar weight dibanding
## entry lain di zona yang sama, makin sering Pokemon ini yang muncul.

@export var species: PokemonSpecies
@export var min_level: int = 2
@export var max_level: int = 5
@export var weight: int = 1 ## relatif terhadap entry lain di array yang sama
