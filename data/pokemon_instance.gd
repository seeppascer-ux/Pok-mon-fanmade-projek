class_name PokemonInstance
extends Resource

## Satu ekor Pokemon yang benar-benar kamu punya (di party/PC/liar).
## Beda dari PokemonSpecies: dua ekor Pikachu bisa punya level, HP, dan IV/EV berbeda,
## walau sama-sama pakai PokemonSpecies "Pikachu" yang sama.

@export var species: PokemonSpecies
@export var level: int = 5
@export var nickname: String = ""

@export var current_hp: int = -1 ## -1 = belum di-set, akan otomatis diisi penuh
@export var exp: int = 0

## Gender Pokemon INI SENDIRI (beda per ekor, walau spesiesnya sama --
## persis kayak level/IV/EV). Di-roll otomatis oleh setup_default() sesuai
## PokemonSpecies.gender_ratio kalau belum pernah di-set.
enum Gender { MALE, FEMALE, GENDERLESS }
@export var gender: int = -1 ## -1 = belum di-roll, akan otomatis diisi setup_default()

@export_group("Individual Values (0-31)")
@export var iv_hp: int = 0
@export var iv_attack: int = 0
@export var iv_defense: int = 0
@export var iv_sp_attack: int = 0
@export var iv_sp_defense: int = 0
@export var iv_speed: int = 0

@export_group("Effort Values (0-252)")
@export var ev_hp: int = 0
@export var ev_attack: int = 0
@export var ev_defense: int = 0
@export var ev_sp_attack: int = 0
@export var ev_sp_defense: int = 0
@export var ev_speed: int = 0

@export_group("Battle Moves")
@export var moves: Array[MoveData] = []   ## maksimal 4
@export var move_pp: Array[int] = []      ## PP sekarang, urutan sama dengan "moves"

@export_group("Nature & Ability")
## Index Natures.Nature. -1 = belum di-roll (otomatis diisi acak oleh
## setup_default()). Menaikkan 1 stat +10% & menurunkan 1 stat -10%
## (HP tidak kena pengaruh), lihat data/natures.gd.
@export var nature: int = -1
## Diisi otomatis dari salah satu species.abilities (acak) oleh
## setup_default(), kecuali sudah diisi manual duluan.
@export var ability: AbilityData

@export_group("Status Condition")
## Status non-volatile yang lagi aktif (lihat StatusCondition.Status).
## NONE = sehat. Beda dari stat stage BattleMon (yang reset begitu battle
## selesai) -- status ini TETAP nempel di luar battle juga, sama seperti
## game aslinya, sampai disembuhkan lewat item atau (khusus Sleep/Freeze)
## sembuh sendiri. Jangan diubah manual -- pakai apply_status()/cure_status()
## di bawah, atau lewat battle_manager.gd pas battle.
@export var status: int = StatusCondition.Status.NONE
## Sisa giliran tertidur, cuma relevan kalau status == SLEEP.
@export var sleep_turns_left: int = 0


func get_display_name() -> String:
	return nickname if nickname != "" else species.species_name


func max_hp() -> int:
	return _calc_stat(species.base_hp, iv_hp, ev_hp, true)


func attack() -> int:
	return _calc_stat(species.base_attack, iv_attack, ev_attack, false, Natures.Stat.ATTACK)


func defense() -> int:
	return _calc_stat(species.base_defense, iv_defense, ev_defense, false, Natures.Stat.DEFENSE)


func sp_attack() -> int:
	return _calc_stat(species.base_sp_attack, iv_sp_attack, ev_sp_attack, false, Natures.Stat.SP_ATTACK)


func sp_defense() -> int:
	return _calc_stat(species.base_sp_defense, iv_sp_defense, ev_sp_defense, false, Natures.Stat.SP_DEFENSE)


func speed() -> int:
	return _calc_stat(species.base_speed, iv_speed, ev_speed, false, Natures.Stat.SPEED)


## Rumus stat resmi game Pokemon, sudah termasuk pengaruh Nature (+10%/-10%,
## HP tidak pernah kena nature). stat_index pakai enum Natures.Stat, isi -1
## kalau memang tidak mau nature berpengaruh (dipakai HP).
func _calc_stat(base: int, iv: int, ev: int, is_hp: bool, stat_index: int = -1) -> int:
	var core: int = int(floor((float(2 * base + iv + floor(ev / 4.0)) * level) / 100.0))
	if is_hp:
		return core + level + 10
	var value: int = core + 5
	if stat_index >= 0 and nature >= 0:
		value = int(floor(value * Natures.get_multiplier(nature, stat_index)))
	return value


func is_fainted() -> bool:
	return current_hp <= 0


## true kalau Pokemon ini betina -- dipakai buat milih sprite female di
## PokemonSpecies.get_front_display_texture() / get_back_display_texture().
func is_female() -> bool:
	return gender == Gender.FEMALE


func heal_full() -> void:
	current_hp = max_hp()


## ---------------------------------------------------------------------
## STATUS CONDITION
## ---------------------------------------------------------------------

func is_healthy() -> bool:
	return status == StatusCondition.Status.NONE


## Kasih status baru ke Pokemon ini. Cuma boleh 1 status aktif dalam satu
## waktu (persis kayak game asli) -- return false & tidak melakukan apa-apa
## kalau Pokemon ini sudah kena status lain.
func apply_status(new_status: int) -> bool:
	if not is_healthy() or new_status == StatusCondition.Status.NONE:
		return false
	status = new_status
	if new_status == StatusCondition.Status.SLEEP:
		sleep_turns_left = (randi() % 3) + 1 # tertidur 1-3 giliran
	return true


func cure_status() -> void:
	status = StatusCondition.Status.NONE
	sleep_turns_left = 0


func get_status_name() -> String:
	return StatusCondition.status_name(status)


## Bikin PokemonInstance baru cuma dari species + level, tanpa perlu bikin
## file .tres PokemonInstance manual dulu di FileSystem. Cocok buat testing
## cepat -- misal ganti musuh di battle cuma dengan drag file species +
## ketik level, lihat script/battle_quick_test.gd buat contoh pemakaiannya.
##
##   var wild_bulbasaur := PokemonInstance.from_species(bulbasaur_species, 6)
##
## HP dan moves otomatis keisi penuh sesuai species begitu instance ini
## dipakai lewat battle_ui.start() (karena start() manggil setup_default()).
static func from_species(species_data: PokemonSpecies, at_level: int = 5) -> PokemonInstance:
	var instance := PokemonInstance.new()
	instance.species = species_data
	instance.level = at_level
	return instance


## Panggil sekali saat Pokemon ini pertama kali dibuat/didapat,
## supaya HP dan moves awalnya otomatis terisi dari species.
func setup_default() -> void:
	if current_hp < 0:
		current_hp = max_hp()
	if moves.is_empty() and species != null:
		for m in species.starting_moves:
			if moves.size() < 4:
				moves.append(m)
				move_pp.append(m.max_pp)
	if gender < 0 and species != null:
		gender = species.roll_gender()
	if nature < 0:
		nature = Natures.random_nature()
	if ability == null and species != null:
		ability = species.roll_ability()


## Naikin level Pokemon ini 1 tingkat, otomatis belajar move baru dari
## learnset species-nya kalau slot move masih kosong (maks 4, sama seperti
## game asli -- kalau slot penuh, move baru dilewati & dikasih tau lewat
## pesan, bukan otomatis lupa move lama). HP saat ini TIDAK ikut naik
## otomatis di sini -- panggil heal_full() sendiri kalau perlu.
## Return: Array[String] pesan-pesan yang bisa langsung ditampilkan ke UI,
## misal ["Charmander naik ke Level 6!", "Charmander belajar Ember!"].
func level_up() -> Array[String]:
	var messages: Array[String] = []
	level += 1
	messages.append("%s naik ke Level %d!" % [get_display_name(), level])
	if species != null:
		for new_move in species.get_moves_learned_at(level):
			if moves.size() < 4:
				moves.append(new_move)
				move_pp.append(new_move.max_pp)
				messages.append("%s belajar %s!" % [get_display_name(), new_move.move_name])
			else:
				messages.append(
					"%s pengen belajar %s, tapi sudah tahu 4 move!" %
					[get_display_name(), new_move.move_name]
				)
	return messages


## Berapa EXP lagi yang dibutuhkan buat naik ke level berikutnya (0 kalau
## sudah Level 100 atau belum punya species). Cocok buat nampilin EXP bar
## di UI party/status screen.
func exp_to_next_level() -> int:
	if species == null or level >= 100:
		return 0
	return maxi(0, species.total_exp_for_level(level + 1) - exp)


## Tambahin EXP ke Pokemon ini (biasanya dipanggil sekali tiap menang
## battle, lihat BattleManager._grant_exp()). Otomatis naik level SEBANYAK
## yang dibutuhkan (bisa naik lebih dari 1 level sekaligus kalau EXP-nya
## banyak, misal lawan Pokemon liar level jauh lebih tinggi), dan otomatis
## cek+jalanin evolusi tiap kali naik level (beda dari level_up() polos
## yang harus manual panggil check_evolution()/evolve() -- di sini sudah
## digabung supaya alur "menang battle -> EXP -> naik level -> evolusi"
## bisa dipanggil cuma dengan 1 fungsi ini).
## Return: Array[String] pesan-pesan buat ditampilkan ke UI, urut dari
## "dapat EXP" -> "naik level" -> "belajar move" -> "berevolusi".
func gain_exp(amount: int) -> Array[String]:
	var messages: Array[String] = []
	if species == null or amount <= 0:
		return messages

	exp += amount
	messages.append("%s dapat %d EXP!" % [get_display_name(), amount])

	while level < 100 and exp >= species.total_exp_for_level(level + 1):
		messages.append_array(level_up())
		var evolved_into: PokemonSpecies = check_evolution()
		if evolved_into != null:
			evolve()
			messages.append("%s berevolusi jadi %s!" % [get_display_name(), evolved_into.species_name])

	return messages


## Return PokemonSpecies hasil evolusi kalau Pokemon ini seharusnya
## berevolusi di level sekarang, atau null kalau belum saatnya/tidak
## berevolusi. Cek ini biasanya dipanggil sesudah level_up().
func check_evolution() -> PokemonSpecies:
	if species != null and species.can_evolve_at(level):
		return species.evolves_into
	return null


## Jalankan evolusi (ganti species jadi hasil check_evolution()). Level,
## nickname, IV/EV, nature, gender, dan moves yang sudah dipunya TETAP sama
## -- cuma species & stat dasarnya yang berubah. HP saat ini disesuaikan
## proporsional (persentase HP sebelum & sesudah evolusi sama).
## Tidak melakukan apa-apa kalau belum waktunya berevolusi.
func evolve() -> void:
	var new_species := check_evolution()
	if new_species == null:
		return
	var hp_ratio: float = float(current_hp) / float(max(max_hp(), 1))
	species = new_species
	current_hp = int(round(max_hp() * hp_ratio))
