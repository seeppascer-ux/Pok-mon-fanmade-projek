class_name PokemonSpecies
extends Resource

## Data DASAR per spesies Pokemon (mirip data Pokedex).
## Ini BUKAN Pokemon yang kamu punya di party -- lihat PokemonInstance untuk itu.

enum GrowthRate { FAST, MEDIUM_FAST, MEDIUM_SLOW, SLOW }

@export var species_id: int = 0
@export var species_name: String = "Monster"
@export_multiline var pokedex_description: String = ""

@export_group("Tipe")
@export var type1: Types.Type = Types.Type.NORMAL
@export var type2: Types.Type = Types.Type.NONE

@export_group("Base Stats")
@export var base_hp: int = 45
@export var base_attack: int = 49
@export var base_defense: int = 49
@export var base_sp_attack: int = 65
@export var base_sp_defense: int = 65
@export var base_speed: int = 45

@export_group("Info Liar")
@export var catch_rate: int = 45 ## 0-255, makin kecil makin susah ditangkap
@export var base_exp_yield: int = 64
@export var growth_rate: GrowthRate = GrowthRate.MEDIUM_FAST

## Peluang gender per spesies (persis seperti game asli).
## Dipakai PokemonInstance.setup_default() buat nge-roll gender pas Pokemon
## ini pertama kali dibuat, supaya sprite female bisa otomatis kepakai.
enum GenderRatio {
	GENDERLESS,        ## Tidak punya gender (contoh: Magnemite, Voltorb, Ditto)
	ALWAYS_MALE,       ## 100% jantan (contoh: Tauros, Nidoran-m)
	ALWAYS_FEMALE,     ## 100% betina (contoh: Chansey, Nidoran-f)
	MOSTLY_MALE,       ## 87.5% jantan / 12.5% betina (paling umum di Gen 1)
	MALE_FEMALE_EQUAL, ## 50% jantan / 50% betina
	MOSTLY_FEMALE,     ## 25% jantan / 75% betina (contoh: Clefairy, Vulpix)
}

@export_group("Gender")
@export var gender_ratio: GenderRatio = GenderRatio.MOSTLY_MALE

@export_group("Moveset")
## Move yang otomatis dikuasai saat Pokemon ini pertama kali didapat.
@export var starting_moves: Array[MoveData] = []

@export_group("Learnset (Level Up)")
## Daftar move yang otomatis dipelajari pas naik level. Isi tiap baris
## dengan New Resource > "LevelUpMove" (level + move). Tidak perlu urut,
## sistem otomatis cari yang cocok tiap kali PokemonInstance.level_up()
## dipanggil.
@export var level_up_moves: Array[LevelUpMove] = []

@export_group("Ability")
## Ability normal yang mungkin dimiliki spesies ini -- kalau diisi lebih
## dari 1, salah satunya dipilih ACAK saat Pokemon baru dibuat (lihat
## roll_ability() / PokemonInstance.setup_default()). Kosongkan kalau
## belum mau pakai ability.
@export var abilities: Array[AbilityData] = []
## Ability langka/opsional (belum ada sistem "peluang muncul" khusus --
## kalau mau dipakai, isi manual field "ability" di PokemonInstance).
@export var hidden_ability: AbilityData

@export_group("Evolusi")
## Spesies hasil evolusi. Kosongkan (null) kalau Pokemon ini tidak
## berevolusi lagi (misal sudah bentuk terakhir).
@export var evolves_into: PokemonSpecies
## Level minimum buat evolusi lewat naik level. 0 = tidak berevolusi lewat
## level (lihat "evolution_stone" / "evolves_by_trade" di bawah buat cara lain).
@export var evolution_level: int = 0
## Batu evolusi yang dibutuhkan: id batu ("fire", "water", "thunder",
## "leaf", "moon") -- harus sama persis dengan ItemData.evolution_stone_id
## batu yang dipakai. "" = bukan evolusi batu.
@export var evolution_stone: String = ""
## true kalau spesies ini berevolusi lewat trade (tukar Pokemon), misal
## Kadabra -> Alakazam. Diproses lewat PokemonInstance.evolve_by_trade().
@export var evolves_by_trade: bool = false
## Evolusi bercabang memakai batu: peta stone_id String -> PokemonSpecies,
## misal Eevee: {"water": Vaporeon, "thunder": Jolteon, "fire": Flareon}.
## Dipakai kalau satu field "evolution_stone"/"evolves_into" tidak cukup
## karena satu spesies bisa berevolusi ke beberapa spesies berbeda
## tergantung batu yang dipakai. Dictionary kosong = tidak ada cabang
## (pakai field lama seperti biasa, JANGAN isi keduanya).
@export var evolution_branches: Dictionary = {}

@export_group("Visual")
## Sprite diam (fallback). Kalau field "Sprite Front/Back Sheet" di bawah
## diisi, sprite animasi itu yang dipakai dan field ini diabaikan buat
## tampilan battle -- boleh tetap diisi sebagai cadangan.
@export var icon: Texture2D
## Sprite depan jantan (default).
@export_subgroup("Depan (Male)")
@export var sprite_front_sheet: Texture2D
@export var sprite_front_columns: int = 1
@export var sprite_front_rows: int = 1
@export var sprite_front_frame_count: int = 0
@export var sprite_front_fps: float = 16.0

## Sprite depan betina. Kosong = otomatis memakai sprite jantan.
@export_subgroup("Depan (Female)")
@export var sprite_front_female_sheet: Texture2D
@export var sprite_front_female_columns: int = 1
@export var sprite_front_female_rows: int = 1
@export var sprite_front_female_frame_count: int = 0
@export var sprite_front_female_fps: float = 16.0

## Sprite belakang jantan (default).
@export_subgroup("Belakang (Male)")
@export var sprite_back_sheet: Texture2D
@export var sprite_back_columns: int = 1
@export var sprite_back_rows: int = 1
@export var sprite_back_frame_count: int = 0
@export var sprite_back_fps: float = 6.0

## Sprite belakang betina. Kosong = otomatis memakai sprite jantan.
@export_subgroup("Belakang (Female)")
@export var sprite_back_female_sheet: Texture2D
@export var sprite_back_female_columns: int = 1
@export var sprite_back_female_rows: int = 1
@export var sprite_back_female_frame_count: int = 0
@export var sprite_back_female_fps: float = 6.0


## Nge-roll gender acak buat 1 ekor Pokemon baru berdasarkan gender_ratio
## spesies ini. Hasilnya cocok dipakai langsung ke PokemonInstance.gender
## (nilainya sama persis dengan enum PokemonInstance.Gender: 0=MALE, 1=FEMALE,
## 2=GENDERLESS).
func roll_gender() -> int:
	var male_chance: float
	match gender_ratio:
		GenderRatio.GENDERLESS:
			return 2 # PokemonInstance.Gender.GENDERLESS
		GenderRatio.ALWAYS_MALE:
			return 0 # PokemonInstance.Gender.MALE
		GenderRatio.ALWAYS_FEMALE:
			return 1 # PokemonInstance.Gender.FEMALE
		GenderRatio.MOSTLY_MALE:
			male_chance = 0.875
		GenderRatio.MALE_FEMALE_EQUAL:
			male_chance = 0.5
		GenderRatio.MOSTLY_FEMALE:
			male_chance = 0.25
		_:
			male_chance = 0.875

	return 0 if randf() < male_chance else 1


## Pilih 1 ability acak dari "abilities" (dipakai PokemonInstance.setup_default()
## buat ngisi field "ability" pas Pokemon baru dibuat). Return null kalau
## spesies ini belum diisi ability sama sekali.
func roll_ability() -> AbilityData:
	if abilities.is_empty():
		return null
	return abilities[randi() % abilities.size()]


## Semua move yang dipelajari TEPAT di level "target_level" (biasanya
## dipanggil sekali tiap kali Pokemon naik 1 level, lewat
## PokemonInstance.level_up()).
func get_moves_learned_at(target_level: int) -> Array[MoveData]:
	var result: Array[MoveData] = []
	for lm in level_up_moves:
		if lm != null and lm.level == target_level and lm.move != null:
			result.append(lm.move)
	return result


## Semua move yang seharusnya SUDAH dikuasai kalau Pokemon ini ditangkap
## langsung di "target_level" (dari level 1 sampai target_level), diurutkan
## dari level terbaru. Berguna buat ngisi moveset Pokemon liar/trainer level
## tinggi tanpa perlu main level-up manual satu-satu.
func get_moves_known_at(target_level: int) -> Array[MoveData]:
	var sorted_moves := level_up_moves.duplicate()
	sorted_moves.sort_custom(func(a, b): return a.level > b.level)
	var result: Array[MoveData] = []
	for lm in sorted_moves:
		if lm != null and lm.level <= target_level and lm.move != null:
			result.append(lm.move)
	return result


## True kalau spesies ini seharusnya berevolusi di level "target_level".
func can_evolve_at(target_level: int) -> bool:
	return evolves_into != null and evolution_level > 0 and target_level >= evolution_level


## Spesies hasil evolusi memakai batu dengan id "stone_id" (misal "water"
## buat Water Stone). Mengembalikan spesies cabang dari "evolution_branches"
## kalau batu ini ada di peta cabang; kalau tidak, pakai jalur lama
## ("evolution_stone" cocok + "evolves_into"). Return null kalau batu ini
## tidak cocok buat spesies ini (pemanggil harus menolak evolusi).
func get_evolution_for_stone(stone_id: String) -> PokemonSpecies:
	if evolution_branches.has(stone_id):
		var branched := evolution_branches[stone_id] as PokemonSpecies
		if branched != null:
			return branched
	if evolves_into != null and evolution_stone != "" and evolution_stone == stone_id:
		return evolves_into
	return null


## True kalau spesies ini berevolusi memakai batu dengan id "stone_id"
## (misal "fire" buat Fire Stone), lewat field lama ATAU peta cabang
## "evolution_branches". Lihat PokemonInstance.evolve_with_stone().
func can_evolve_with_stone(stone_id: String) -> bool:
	return get_evolution_for_stone(stone_id) != null


## True kalau spesies ini berevolusi lewat trade.
## Lihat PokemonInstance.evolve_by_trade().
func can_evolve_by_trade() -> bool:
	return evolves_into != null and evolves_by_trade


## Total EXP kumulatif (dari Level 1) yang dibutuhkan buat sampai
## "target_level", berdasarkan growth_rate spesies ini. Dipakai
## PokemonInstance.gain_exp() buat nentuin kapan harus naik level.
func total_exp_for_level(target_level: int) -> int:
	# Rumus kurva EXP ditulis LANGSUNG di sini (bukan manggil class lain
	# kayak ExpCurve) supaya tidak ada risiko error "Nonexistent function"
	# gara-gara urutan load antar script class_name di Godot.
	var n: float = float(maxi(target_level, 0))
	match growth_rate:
		GrowthRate.FAST:
			return int(floor(0.8 * pow(n, 3)))
		GrowthRate.MEDIUM_FAST:
			return int(floor(pow(n, 3)))
		GrowthRate.MEDIUM_SLOW:
			var value: float = (1.2 * pow(n, 3)) - (15.0 * pow(n, 2)) + (100.0 * n) - 140.0
			return maxi(0, int(floor(value)))
		GrowthRate.SLOW:
			return int(floor(1.25 * pow(n, 3)))
		_:
			return int(floor(pow(n, 3)))


## Texture final untuk sprite depan battle.
## is_female = true memakai sprite Female jika tersedia.
func get_front_display_texture(is_female: bool = false) -> Texture2D:
	if is_female and sprite_front_female_sheet != null:
		return SpriteSheetUtil.build_from_grid(
			sprite_front_female_sheet,
			sprite_front_female_columns,
			sprite_front_female_rows,
			sprite_front_female_frame_count,
			sprite_front_female_fps
		)

	if sprite_front_sheet != null:
		return SpriteSheetUtil.build_from_grid(
			sprite_front_sheet,
			sprite_front_columns,
			sprite_front_rows,
			sprite_front_frame_count,
			sprite_front_fps
		)

	return icon


## Texture final untuk sprite belakang player.
## is_female = true memakai sprite Female jika tersedia.
func get_back_display_texture(is_female: bool = false) -> Texture2D:
	if is_female and sprite_back_female_sheet != null:
		return SpriteSheetUtil.build_from_grid(
			sprite_back_female_sheet,
			sprite_back_female_columns,
			sprite_back_female_rows,
			sprite_back_female_frame_count,
			sprite_back_female_fps
		)

	if sprite_back_sheet != null:
		return SpriteSheetUtil.build_from_grid(
			sprite_back_sheet,
			sprite_back_columns,
			sprite_back_rows,
			sprite_back_frame_count,
			sprite_back_fps
		)

	return icon
