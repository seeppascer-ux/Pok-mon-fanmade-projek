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
			var old_name: String = get_display_name()
			evolve()
			messages.append("%s berevolusi jadi %s!" % [old_name, evolved_into.species_name])

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
	_apply_evolution(new_species)


## Inti proses evolusi: ganti species ke "new_species" sambil menyesuaikan
## HP saat ini secara proporsional. Dipakai semua jalur evolusi (level,
## batu, trade) supaya perilakunya konsisten.
func _apply_evolution(new_species: PokemonSpecies) -> void:
	var hp_ratio: float = float(current_hp) / float(max(max_hp(), 1))
	species = new_species
	current_hp = int(round(max_hp() * hp_ratio))


## True kalau Pokemon ini bisa berevolusi memakai batu dengan id "stone_id"
## (misal "thunder" buat Pikachu + Thunder Stone).
func can_evolve_with_stone(stone_id: String) -> bool:
	return species != null and species.can_evolve_with_stone(stone_id)


## Evolusi memakai batu evolusi (biasanya dipanggil lewat
## Bag.use_stone_on() supaya jumlah batunya di Tas ikut berkurang).
## Spesies hasil dipilih lewat species.get_evolution_for_stone(): cabang
## "evolution_branches" kalau ada (misal Eevee + Water Stone -> Vaporeon),
## kalau tidak pakai "evolves_into" seperti biasa.
## Return pesan buat UI, misal ["Pikachu berevolusi jadi Raichu!"] --
## array kosong kalau batu ini tidak cocok buat Pokemon ini.
func evolve_with_stone(stone_id: String) -> Array[String]:
	var messages: Array[String] = []
	if not can_evolve_with_stone(stone_id):
		return messages
	var old_name: String = get_display_name()
	var new_species: PokemonSpecies = species.get_evolution_for_stone(stone_id)
	_apply_evolution(new_species)
	messages.append("%s berevolusi jadi %s!" % [old_name, new_species.species_name])
	return messages


## True kalau Pokemon ini berevolusi lewat trade (misal Kadabra, Machoke,
## Graveler, Haunter).
func can_evolve_by_trade() -> bool:
	return species != null and species.can_evolve_by_trade()


## Evolusi lewat trade: panggil ini sesudah Pokemon ini ditukar (di game
## single-player, "trade" bisa disimulasikan misal lewat NPC penukar atau
## mesin trade -- fungsi inilah yang menjalankan evolusinya).
## Return pesan buat UI -- array kosong kalau Pokemon ini bukan evolusi trade.
func evolve_by_trade() -> Array[String]:
	var messages: Array[String] = []
	if not can_evolve_by_trade():
		return messages
	var old_name: String = get_display_name()
	var new_species: PokemonSpecies = species.evolves_into
	_apply_evolution(new_species)
	messages.append("%s berevolusi jadi %s!" % [old_name, new_species.species_name])
	return messages


## ---------------------------------------------------------------------
## SAVE / LOAD (dipakai SaveSystem)
## ---------------------------------------------------------------------

## Serialize ke Dictionary yang aman JSON. Species disimpan sebagai
## species_id (stabil lintas sesi), move/ability/item sebagai resource_path
## (+ nama sebagai fallback kalau path tidak ketemu).
func to_dict() -> Dictionary:
	var move_paths: Array = []
	var move_names: Array = []
	for m in moves:
		move_paths.append(m.resource_path)
		move_names.append(m.move_name)
	return {
		"species_id": species.species_id if species != null else 0,
		"level": level,
		"nickname": nickname,
		"current_hp": current_hp,
		"exp": exp,
		"gender": gender,
		"nature": nature,
		"iv": [iv_hp, iv_attack, iv_defense, iv_sp_attack, iv_sp_defense, iv_speed],
		"ev": [ev_hp, ev_attack, ev_defense, ev_sp_attack, ev_sp_defense, ev_speed],
		"moves": move_paths,
		"move_names": move_names,
		"move_pp": move_pp.duplicate(),
		"ability": ability.resource_path if ability != null else "",
		"ability_name": ability.ability_name if ability != null else "",
		"status": status,
		"sleep_turns_left": sleep_turns_left,
	}


## Bangun PokemonInstance dari Dictionary hasil to_dict(). Defensif:
## key hilang -> pakai default wajar; species tidak dikenal -> return null
## (entri dilewati pemanggil, bukan crash); move/ability tidak ketemu ->
## dilewati / null (setup_default bisa me-roll ulang ability bila perlu).
static func from_dict(d: Dictionary) -> PokemonInstance:
	var species := SaveLookup.species_by_id(int(d.get("species_id", 0)))
	if species == null:
		push_warning("SaveSystem: species_id %s tidak dikenal, entri dilewati." % str(d.get("species_id", 0)))
		return null
	var inst := PokemonInstance.new()
	inst.species = species
	inst.level = maxi(1, int(d.get("level", 5)))
	inst.nickname = str(d.get("nickname", ""))
	inst.exp = maxi(0, int(d.get("exp", 0)))
	inst.gender = int(d.get("gender", -1))
	inst.nature = int(d.get("nature", -1))
	var ivs: Array = d.get("iv", [])
	if ivs.size() >= 6:
		inst.iv_hp = int(ivs[0])
		inst.iv_attack = int(ivs[1])
		inst.iv_defense = int(ivs[2])
		inst.iv_sp_attack = int(ivs[3])
		inst.iv_sp_defense = int(ivs[4])
		inst.iv_speed = int(ivs[5])
	var evs: Array = d.get("ev", [])
	if evs.size() >= 6:
		inst.ev_hp = int(evs[0])
		inst.ev_attack = int(evs[1])
		inst.ev_defense = int(evs[2])
		inst.ev_sp_attack = int(evs[3])
		inst.ev_sp_defense = int(evs[4])
		inst.ev_speed = int(evs[5])
	var move_paths: Array = d.get("moves", [])
	var move_names: Array = d.get("move_names", [])
	var pps: Array = d.get("move_pp", [])
	for i in range(move_paths.size()):
		var mv := SaveLookup.move_by_path(str(move_paths[i]))
		if mv == null and i < move_names.size():
			mv = SaveLookup.move_by_name(str(move_names[i]))
		if mv == null:
			continue
		inst.moves.append(mv)
		var pp := mv.max_pp
		if i < pps.size():
			pp = clampi(int(pps[i]), 0, mv.max_pp)
		inst.move_pp.append(pp)
		if inst.moves.size() >= 4:
			break
	var ability := SaveLookup.ability_by_path(str(d.get("ability", "")))
	if ability == null:
		ability = SaveLookup.ability_by_name(str(d.get("ability_name", "")))
	inst.ability = ability
	inst.status = int(d.get("status", StatusCondition.Status.NONE))
	inst.sleep_turns_left = maxi(0, int(d.get("sleep_turns_left", 0)))
	inst.current_hp = clampi(int(d.get("current_hp", inst.max_hp())), 0, inst.max_hp())
	return inst
