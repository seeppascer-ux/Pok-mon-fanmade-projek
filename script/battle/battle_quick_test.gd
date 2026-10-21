extends Node

## Scene test cepat buat battle -- bedanya sama battle_test.tscn: di sini
## kamu TIDAK perlu bikin file PokemonInstance (.tres) manual dulu.
## Tinggal drag file PokemonSpecies langsung (misal charmander.tres,
## pikachu.tres) ke 2 field di bawah + isi level, langsung jalan.
##
## Kenapa masih ada 2 lapis (Species vs Instance)? Karena battle butuh info
## yang cuma dipunyai 1 EKOR Pokemon tertentu (level, HP sekarang, moves
## yang sudah dipelajari) -- itu tidak ada di data Species (species cuma
## nyimpen base stat & tipe, sama buat semua Pokemon sejenis). Script ini
## cuma bikinin PokemonInstance itu otomatis di belakang layar lewat
## PokemonInstance.from_species(), jadi kamu tidak perlu sentuh file .tres
## instance sama sekali kalau cuma buat testing cepat.

@export var player_species: PokemonSpecies
@export var player_level: int = 5

@export var enemy_species: PokemonSpecies
@export var enemy_level: int = 5


func _ready() -> void:
	if player_species == null or enemy_species == null:
		push_warning("battle_quick_test: isi dulu 'Player Species' dan 'Enemy Species' di Inspector.")
		return

	var player_pokemon: PokemonInstance = PokemonInstance.from_species(player_species, player_level)
	var enemy_pokemon: PokemonInstance = PokemonInstance.from_species(enemy_species, enemy_level)

	var battle_scene: BattleUI = preload("res://scene/battle_ui.tscn").instantiate()
	add_child(battle_scene)
	var party: Array[PokemonInstance] = [player_pokemon]
	battle_scene.start(party, enemy_pokemon)
