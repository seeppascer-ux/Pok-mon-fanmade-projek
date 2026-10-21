class_name BattleManager
extends Node

## Node "otak" battle Pokemon 1 lawan 1 (player vs 1 pokemon musuh).
## Tidak tahu apa-apa soal UI -- semua komunikasi ke luar lewat signal,
## jadi battle_manager ini bisa dipasangkan ke UI apa pun.

signal message(text: String) ## teks buat ditampilkan di message box
signal hp_updated(is_player: bool, current: int, max_hp: int)
signal request_player_move() ## giliran player pilih move -> UI harus munculin tombol
signal battle_ended(player_won: bool)
signal fled() ## player berhasil kabur (RUN) -- battle selesai tanpa menang/kalah
signal move_used(is_player: bool) ## dipancarkan pas attacker mulai pakai move, buat trigger animasi
signal captured(instance: PokemonInstance) ## dipancarkan begitu Poke Ball berhasil nangkap Pokemon liar
signal exp_gained(amount: int, old_exp: int, old_level: int, new_level: int) ## EXP sudah di-apply; UI pakai ini buat animasi bar + efek naik level
signal request_player_switch(forced: bool) ## UI harus buka panel party: forced=true wajib pilih pengganti (habis pingsan, tanpa tombol batal), false = ganti sukarela (boleh batal)
signal pokemon_switched() ## Pokemon player sudah bertukar; UI refresh nama/level/HP/sprite/tombol move

const TURN_DELAY: float = 0.6
const MESSAGE_DELAY: float = 0.55

var player_mon: BattleMon
var enemy_mon: BattleMon

## Seluruh party player. player_mon selalu = BattleMon baru membungkus
## party[player_party_index] -- stat stage otomatis ke-reset tiap ganti
## (standar game resmi), sementara status condition tetap menempel karena
## tersimpan di PokemonInstance-nya sendiri.
var party: Array[PokemonInstance] = []
var player_party_index: int = 0

var _battle_over: bool = false
var _awaiting_switch: bool = false ## true = lagi nunggu player pilih pengganti (mode wajib habis pingsan)
var _switch_forced: bool = false ## true = ganti gratis habis pingsan; false = ganti sukarela memakan giliran


## party_player: seluruh party (minimal 1 yang hidup; kalau semuanya pingsan
## defensif dipakai index 0). Yang pertama hidup langsung dikirim bertarung.
func start_battle(p_party: Array[PokemonInstance], enemy_instance: PokemonInstance) -> void:
	party = p_party
	player_party_index = _first_alive_index()
	player_mon = BattleMon.new(party[player_party_index])
	enemy_mon = BattleMon.new(enemy_instance)
	_battle_over = false
	_awaiting_switch = false
	_switch_forced = false

	_update_hp_signals()
	message.emit("Pokemon liar %s muncul!" % enemy_mon.get_display_name())
	await get_tree().create_timer(TURN_DELAY).timeout
	message.emit("Ayo, %s!" % player_mon.get_display_name())
	await get_tree().create_timer(TURN_DELAY).timeout

	_start_player_turn()


func _update_hp_signals() -> void:
	hp_updated.emit(true, player_mon.instance.current_hp, player_mon.instance.max_hp())
	hp_updated.emit(false, enemy_mon.instance.current_hp, enemy_mon.instance.max_hp())


func _start_player_turn() -> void:
	if _battle_over:
		return
	message.emit("Apa yang akan dilakukan %s?" % player_mon.get_display_name())
	request_player_move.emit()


## Dipanggil dari UI ketika player menekan salah satu tombol move (index 0-3).
func player_use_move(move_index: int) -> void:
	if _battle_over:
		return
	if move_index < 0 or move_index >= player_mon.instance.moves.size():
		return
	if player_mon.instance.move_pp[move_index] <= 0:
		message.emit("Tidak ada PP tersisa untuk move itu!")
		await get_tree().create_timer(MESSAGE_DELAY).timeout
		request_player_move.emit()
		return

	_resolve_turn(move_index)


## Dipanggil dari UI ketika player menekan tombol RUN. Cuma masuk akal buat
## battle Pokemon liar (tidak ada battle trainer di sistem ini sekarang).
## Peluang kabur dihitung dari rumus resmi game Pokemon yang disederhanakan:
## makin cepat kamu dibanding musuh, makin gampang kabur. Kalau speed kamu
## sama atau lebih tinggi, selalu berhasil.
func player_attempt_flee() -> void:
	if _battle_over:
		return

	message.emit("%s mencoba kabur!" % player_mon.get_display_name())
	await get_tree().create_timer(MESSAGE_DELAY).timeout

	var player_speed: float = player_mon.get_speed()
	var enemy_speed: float = enemy_mon.get_speed()
	var success: bool = true
	if enemy_speed > player_speed:
		var chance: int = int((player_speed * 128.0) / maxf(enemy_speed, 1.0)) + 30
		success = (randi() % 256) < chance

	if success:
		message.emit("Kamu berhasil kabur dengan selamat!")
		await get_tree().create_timer(MESSAGE_DELAY).timeout
		_battle_over = true
		fled.emit()
		return

	message.emit("Tidak bisa kabur!")
	await get_tree().create_timer(MESSAGE_DELAY).timeout

	# Gagal kabur = buang giliran, musuh tetap menyerang duluan.
	var enemy_move_index: int = _enemy_choose_move_index()
	if enemy_move_index != -1:
		await _execute_move(enemy_mon, player_mon, enemy_move_index, false)
		if _check_faint():
			return

	await get_tree().create_timer(0.3).timeout
	_start_player_turn()


func _enemy_choose_move_index() -> int:
	var usable: Array[int] = []
	for i in enemy_mon.instance.moves.size():
		if enemy_mon.instance.move_pp[i] > 0:
			usable.append(i)
	if usable.is_empty():
		return -1
	return usable[randi() % usable.size()]


func _resolve_turn(player_move_index: int) -> void:
	var enemy_move_index: int = _enemy_choose_move_index()

	var order: Array[Dictionary] = []
	order.append({"is_player": true, "index": player_move_index})
	if enemy_move_index != -1:
		order.append({"is_player": false, "index": enemy_move_index})

	if order.size() == 2:
		var p_move: MoveData = player_mon.instance.moves[player_move_index]
		var e_move: MoveData = enemy_mon.instance.moves[enemy_move_index]
		var player_first: bool
		if p_move.priority != e_move.priority:
			## Priority dicek dulu, sebelum speed (misal Quick Attack selalu duluan).
			player_first = p_move.priority > e_move.priority
		else:
			var p_speed: float = player_mon.get_speed()
			var e_speed: float = enemy_mon.get_speed()
			player_first = p_speed > e_speed or (p_speed == e_speed and randi() % 2 == 0)
		if not player_first:
			order.reverse()

	for action in order:
		if _battle_over:
			return
		var attacker: BattleMon = player_mon if action["is_player"] else enemy_mon
		var defender: BattleMon = enemy_mon if action["is_player"] else player_mon
		await _execute_move(attacker, defender, action["index"], action["is_player"])
		if _check_faint():
			return

	if await _apply_end_of_turn_status(player_mon, true):
		return
	if await _apply_end_of_turn_status(enemy_mon, false):
		return

	await get_tree().create_timer(0.3).timeout
	_start_player_turn()


## Cek status yang menghalangi attacker bergerak (Freeze/Sleep/Paralysis)
## SEBELUM move dipakai. Return true kalau attacker boleh lanjut menyerang,
## false kalau gilirannya habis gara-gara status (move dianggap tidak jadi
## dipakai sama sekali -- PP tidak berkurang, sama seperti flee/item gagal).
func _resolve_pre_move_status(mon: BattleMon) -> bool:
	match mon.instance.status:
		StatusCondition.Status.FREEZE:
			if (randi() % 100) < 20: # 20% peluang cair tiap giliran
				mon.instance.cure_status()
				message.emit("%s tidak membeku lagi!" % mon.get_display_name())
				await get_tree().create_timer(MESSAGE_DELAY).timeout
				return true
			message.emit("%s membeku, tidak bisa bergerak!" % mon.get_display_name())
			await get_tree().create_timer(MESSAGE_DELAY).timeout
			return false

		StatusCondition.Status.SLEEP:
			mon.instance.sleep_turns_left -= 1
			if mon.instance.sleep_turns_left <= 0:
				mon.instance.cure_status()
				message.emit("%s bangun!" % mon.get_display_name())
				await get_tree().create_timer(MESSAGE_DELAY).timeout
				return true
			message.emit("%s sedang tidur..." % mon.get_display_name())
			await get_tree().create_timer(MESSAGE_DELAY).timeout
			return false

		StatusCondition.Status.PARALYSIS:
			if (randi() % 100) < 25: # 25% peluang gagal total tiap giliran
				message.emit("%s lumpuh! Tidak bisa bergerak!" % mon.get_display_name())
				await get_tree().create_timer(MESSAGE_DELAY).timeout
				return false

	return true


## Damage Poison/Burn di akhir giliran (setelah kedua Pokemon bergerak).
## Return true kalau battle jadi berakhir gara-gara damage ini (buat caller
## langsung berhenti, sama seperti _check_faint() di tempat lain).
func _apply_end_of_turn_status(mon: BattleMon, is_player: bool) -> bool:
	if _battle_over or mon.is_fainted():
		return false
	if mon.instance.status != StatusCondition.Status.POISON and mon.instance.status != StatusCondition.Status.BURN:
		return false

	var dmg: int = maxi(1, mon.instance.max_hp() / 8)
	mon.take_damage(dmg)
	hp_updated.emit(is_player, mon.instance.current_hp, mon.instance.max_hp())
	if mon.instance.status == StatusCondition.Status.POISON:
		message.emit("%s terluka akibat racun!" % mon.get_display_name())
	else:
		message.emit("%s tersiksa akibat luka bakar!" % mon.get_display_name())
	await get_tree().create_timer(MESSAGE_DELAY).timeout

	return _check_faint()


func _execute_move(attacker: BattleMon, defender: BattleMon, move_index: int, attacker_is_player: bool) -> void:
	if attacker.is_fainted():
		return

	var can_move: bool = await _resolve_pre_move_status(attacker)
	if not can_move:
		return

	var move: MoveData = attacker.instance.moves[move_index]
	attacker.instance.move_pp[move_index] = maxi(0, attacker.instance.move_pp[move_index] - 1)

	message.emit("%s pakai %s!" % [attacker.get_display_name(), move.move_name])
	move_used.emit(attacker_is_player)
	await get_tree().create_timer(TURN_DELAY).timeout

	var hits: bool = move.accuracy < 0 or (randi() % 100) < move.accuracy
	if not hits:
		message.emit("Serangan %s meleset!" % attacker.get_display_name())
		await get_tree().create_timer(MESSAGE_DELAY).timeout
		return

	if move.category != MoveData.Category.STATUS:
		var result: Dictionary = _calculate_damage(attacker, defender, move)
		var effectiveness: float = result["effectiveness"]

		if effectiveness == 0.0:
			message.emit("Tidak berpengaruh ke %s..." % defender.get_display_name())
			await get_tree().create_timer(MESSAGE_DELAY).timeout
		else:
			var dmg: int = result["damage"]
			defender.take_damage(dmg)
			hp_updated.emit(not attacker_is_player, defender.instance.current_hp, defender.instance.max_hp())
			message.emit("%s kena %d damage!" % [defender.get_display_name(), dmg])
			await get_tree().create_timer(MESSAGE_DELAY).timeout

			if result["critical"]:
				message.emit("Kena serangan kritis!")
				await get_tree().create_timer(MESSAGE_DELAY).timeout

			if effectiveness > 1.0:
				message.emit("Sangat efektif!")
				await get_tree().create_timer(MESSAGE_DELAY).timeout
			elif effectiveness < 1.0:
				message.emit("Kurang efektif...")
				await get_tree().create_timer(MESSAGE_DELAY).timeout

	if defender.is_fainted():
		return

	if move.effect != MoveData.Effect.NONE and (randi() % 100) < move.effect_chance:
		_apply_effect(attacker, defender, move, attacker_is_player)
		await get_tree().create_timer(MESSAGE_DELAY).timeout


func _apply_effect(attacker: BattleMon, defender: BattleMon, move: MoveData, attacker_is_player: bool) -> void:
	var target_is_self: bool = move.effect_target == MoveData.StatTarget.SELF
	var target: BattleMon = attacker if target_is_self else defender
	var target_is_player: bool = attacker_is_player if target_is_self else not attacker_is_player

	match move.effect:
		MoveData.Effect.STAT_CHANGE:
			var stat_names: Array[String] = [
				"attack", "defense", "sp_attack", "sp_defense", "speed", "accuracy", "evasion"
			]
			var stat_name: String = stat_names[move.effect_stat]
			var applied: int = target.modify_stage(stat_name, move.effect_amount)
			if applied == 0:
				message.emit("Stat %s milik %s tidak bisa naik/turun lagi!" % [stat_name, target.get_display_name()])
			elif applied > 0:
				message.emit("%s milik %s naik!" % [stat_name, target.get_display_name()])
			else:
				message.emit("%s milik %s turun!" % [stat_name, target.get_display_name()])

		MoveData.Effect.HEAL:
			var heal_amount: int = int(target.instance.max_hp() * (move.effect_amount / 100.0))
			target.heal(heal_amount)
			hp_updated.emit(target_is_player, target.instance.current_hp, target.instance.max_hp())
			message.emit("HP %s pulih!" % target.get_display_name())

		MoveData.Effect.STATUS_CONDITION:
			if not target.instance.is_healthy():
				message.emit("%s sudah kena status lain!" % target.get_display_name())
				return
			if _is_immune_to_status(target.instance.species, move.effect_status):
				message.emit("Tidak berpengaruh ke %s..." % target.get_display_name())
				return
			target.instance.apply_status(move.effect_status)
			message.emit("%s jadi %s!" % [target.get_display_name(), StatusCondition.status_name(move.effect_status)])


## Tipe tertentu kebal status tertentu, persis kayak game asli: Fire kebal
## Burn, Poison kebal Poison, Electric kebal Paralysis, Ice kebal Freeze.
func _is_immune_to_status(species: PokemonSpecies, status: int) -> bool:
	if species == null:
		return false
	match status:
		StatusCondition.Status.BURN:
			return species.type1 == Types.Type.FIRE or species.type2 == Types.Type.FIRE
		StatusCondition.Status.POISON:
			return species.type1 == Types.Type.POISON or species.type2 == Types.Type.POISON
		StatusCondition.Status.PARALYSIS:
			return species.type1 == Types.Type.ELECTRIC or species.type2 == Types.Type.ELECTRIC
		StatusCondition.Status.FREEZE:
			return species.type1 == Types.Type.ICE or species.type2 == Types.Type.ICE
	return false


## Rumus damage disederhanakan dari rumus resmi game Pokemon. Critical hit
## disederhanakan jadi peluang tetap 1/16 (~6%, tidak memperhitungkan stage
## rasio/move ber-crit-tinggi seperti game asli), kali damage x2.
func _calculate_damage(attacker: BattleMon, defender: BattleMon, move: MoveData) -> Dictionary:
	if move.power <= 0:
		return {"damage": 0, "effectiveness": 1.0, "critical": false}

	var def_species: PokemonSpecies = defender.instance.species
	var effectiveness: float = TypeChart.get_multiplier(move.type, def_species.type1, def_species.type2)
	if effectiveness == 0.0:
		return {"damage": 0, "effectiveness": 0.0, "critical": false}

	var level: int = attacker.instance.level
	var atk: float = attacker.get_sp_attack() if move.category == MoveData.Category.SPECIAL else attacker.get_attack()
	var def_stat: float = defender.get_sp_defense() if move.category == MoveData.Category.SPECIAL else defender.get_defense()

	var atk_species: PokemonSpecies = attacker.instance.species
	var stab: float = 1.5 if (move.type == atk_species.type1 or move.type == atk_species.type2) else 1.0

	var is_critical: bool = (randi() % 16) == 0
	var crit_multiplier: float = 2.0 if is_critical else 1.0

	var random_factor: float = randf_range(0.85, 1.0)
	var base: float = (((2.0 * level / 5.0) + 2.0) * move.power * (atk / maxf(def_stat, 1.0))) / 50.0 + 2.0
	var damage: int = maxi(1, int(floor(base * stab * effectiveness * crit_multiplier * random_factor)))

	return {"damage": damage, "effectiveness": effectiveness, "critical": is_critical}


func _check_faint() -> bool:
	if enemy_mon.is_fainted():
		message.emit("%s pingsan!" % enemy_mon.get_display_name())
		_end_battle(true)
		return true
	if player_mon.is_fainted():
		message.emit("%s pingsan!" % player_mon.get_display_name())
		if _has_alive_party_member():
			# Belum kalah -- player WAJIB pilih pengganti (ganti gratis,
			# musuh tidak menyerang). Battle lanjut di player_switch_to().
			_awaiting_switch = true
			_switch_forced = true
			request_player_switch.emit(true)
		else:
			# Seluruh party pingsan -> baru kalah.
			_end_battle(false)
		return true
	return false


## Index party pertama yang masih hidup (defensif: 0 kalau semua pingsan).
func _first_alive_index() -> int:
	for i in party.size():
		if not party[i].is_fainted():
			return i
	return 0


## true kalau masih ada anggota party yang hidup (termasuk yang bertarung).
func _has_alive_party_member() -> bool:
	for mon in party:
		if not mon.is_fainted():
			return true
	return false


## ---------------------------------------------------------------------
## GANTI POKEMON
## ---------------------------------------------------------------------

## Dipanggil UI begitu player memilih Pokemon dari panel party.
## Dua mode, ditentukan flag internal:
## - Mode wajib (_awaiting_switch, habis pingsan): ganti GRATIS, musuh TIDAK
##   menyerang, lalu giliran player dimulai lagi.
## - Mode sukarela (dari tombol Pokemon di menu utama): ganti MEMAKAN
##   giliran -- musuh menyerang setelah ganti, persis kayak game resmi.
## UI seharusnya sudah mencegah pilihan tak valid (pingsan / sedang
## bertarung); validasi di sini cuma pengaman lapis kedua.
func player_switch_to(index: int) -> void:
	if _battle_over:
		return
	if index < 0 or index >= party.size():
		return
	if index == player_party_index:
		return
	if party[index].is_fainted():
		return
	var free_switch: bool = _awaiting_switch and _switch_forced
	_awaiting_switch = false
	_switch_forced = false
	await _do_switch(index, free_switch)


func _do_switch(index: int, free_switch: bool) -> void:
	var old_name: String = player_mon.get_display_name()
	message.emit("Kembali, %s!" % old_name)
	await get_tree().create_timer(MESSAGE_DELAY).timeout

	player_party_index = index
	# BattleMon baru = semua stat stage ke-reset (standar game resmi);
	# status condition tetap menempel karena tersimpan di instance.
	player_mon = BattleMon.new(party[index])
	_update_hp_signals()
	pokemon_switched.emit()
	message.emit("Ayo, %s!" % player_mon.get_display_name())
	await get_tree().create_timer(TURN_DELAY).timeout

	if free_switch:
		_start_player_turn()
		return

	# Ganti sukarela memakan giliran: musuh menyerang setelah ganti.
	var enemy_move_index: int = _enemy_choose_move_index()
	if enemy_move_index != -1:
		await _execute_move(enemy_mon, player_mon, enemy_move_index, false)
		if _check_faint():
			return

	await get_tree().create_timer(0.3).timeout
	_start_player_turn()


func _end_battle(player_won: bool) -> void:
	_battle_over = true
	await get_tree().create_timer(0.8).timeout
	if player_won:
		message.emit("Kamu menang!")
		await get_tree().create_timer(MESSAGE_DELAY).timeout
		await _grant_exp()
	else:
		message.emit("Kamu kalah...")
	await get_tree().create_timer(0.8).timeout
	battle_ended.emit(player_won)


## ---------------------------------------------------------------------
## EXP SETELAH MENANG
## ---------------------------------------------------------------------

## Rumus EXP disederhanakan dari rumus resmi game Pokemon buat battle liar
## 1 lawan 1 tanpa exp-share (a=1, trainer bonus tidak dipakai karena
## sistem ini belum ada battle trainer): base_exp_yield musuh * level musuh / 7.
func _grant_exp() -> void:
	if enemy_mon.instance.species == null or player_mon.instance.is_fainted():
		return

	var exp_gain: int = int(floor((enemy_mon.instance.species.base_exp_yield * enemy_mon.instance.level) / 7.0))
	if exp_gain <= 0:
		return

	var old_level: int = player_mon.instance.level
	var old_exp: int = player_mon.instance.exp
	var messages: Array[String] = player_mon.instance.gain_exp(exp_gain)
	exp_gained.emit(exp_gain, old_exp, old_level, player_mon.instance.level)
	for m in messages:
		message.emit(m)
		await get_tree().create_timer(MESSAGE_DELAY).timeout

	hp_updated.emit(true, player_mon.instance.current_hp, player_mon.instance.max_hp())


## ---------------------------------------------------------------------
## POKE BALL / CAPTURE
## ---------------------------------------------------------------------

## Dipanggil dari UI (lewat menu Tas) begitu player pilih Poke Ball buat
## dilempar ke Pokemon liar. "ball" harus ItemData dengan category POKE_BALL.
## Item-nya sendiri (pengurangan jumlah di Tas) sudah harus dikurangi DULU
## oleh caller sebelum manggil ini (lihat battle_ui.gd), sama seperti
## melempar bola beneran -- dipakai walau gagal nangkap.
func player_use_poke_ball(ball: ItemData) -> void:
	if _battle_over:
		return

	message.emit("Kamu melempar %s!" % ball.item_name)
	await get_tree().create_timer(MESSAGE_DELAY).timeout

	var target: PokemonInstance = enemy_mon.instance
	var catch_chance: float = _calculate_catch_chance(target, ball)

	message.emit("...")
	await get_tree().create_timer(MESSAGE_DELAY).timeout

	if randf() < catch_chance:
		message.emit("Gotcha! %s berhasil ditangkap!" % target.get_display_name())
		await get_tree().create_timer(MESSAGE_DELAY).timeout
		_battle_over = true
		captured.emit(target)
		battle_ended.emit(true)
		return

	message.emit("Yah, %s lepas!" % target.get_display_name())
	await get_tree().create_timer(MESSAGE_DELAY).timeout

	# Gagal nangkap = buang giliran, musuh tetap menyerang duluan (sama
	# seperti gagal kabur di player_attempt_flee()).
	var enemy_move_index: int = _enemy_choose_move_index()
	if enemy_move_index != -1:
		await _execute_move(enemy_mon, player_mon, enemy_move_index, false)
		if _check_faint():
			return

	await get_tree().create_timer(0.3).timeout
	_start_player_turn()


## Peluang tangkap (0.0-1.0), disederhanakan dari rumus shake resmi game
## Pokemon jadi 1 perhitungan langsung: makin sedikit HP musuh & makin
## bagus bola & musuh lagi kena status, makin gampang. species.catch_rate
## (0-255) yang nentuin dasar susah/gampangnya spesies itu ditangkap.
func _calculate_catch_chance(target: PokemonInstance, ball: ItemData) -> float:
	if target.species == null:
		return 0.0

	var max_hp: float = maxf(float(target.max_hp()), 1.0)
	var hp_factor: float = (3.0 * max_hp - 2.0 * float(target.current_hp)) / (3.0 * max_hp)

	var status_bonus: float = 1.0
	if target.status == StatusCondition.Status.SLEEP or target.status == StatusCondition.Status.FREEZE:
		status_bonus = 2.5
	elif not target.is_healthy():
		status_bonus = 1.5

	var chance: float = hp_factor * (target.species.catch_rate / 255.0) * ball.catch_multiplier * status_bonus
	return clampf(chance, 0.0, 1.0)


## ---------------------------------------------------------------------
## ITEM / BAG (di luar Poke Ball -- Potion, Antidote, Revive, dst)
## ---------------------------------------------------------------------

## Dipanggil dari UI begitu player pakai item non-Poke-Ball ke "target"
## (biasanya player_mon.instance = yang sedang bertarung; item belum bisa
## dipakai ke Pokemon cadangan di party). Item-nya sendiri dikurangi
## dari "bag" DI SINI, cuma kalau efeknya beneran kepakai (misal Potion ke
## Pokemon yang HP-nya sudah penuh TIDAK memakan item).
func player_use_item(item: ItemData, target: PokemonInstance, bag: Bag) -> void:
	if _battle_over or item == null:
		return

	message.emit("Kamu memakai %s!" % item.item_name)
	await get_tree().create_timer(MESSAGE_DELAY).timeout

	var used: bool = false

	if item.category == ItemData.Category.REVIVE:
		if target.is_fainted():
			target.current_hp = mini(target.max_hp(), item.heal_amount if item.heal_amount >= 0 else target.max_hp())
			used = true
			message.emit("%s pulih kembali!" % target.get_display_name())
			hp_updated.emit(target == player_mon.instance, target.current_hp, target.max_hp())
		else:
			message.emit("%s belum pingsan." % target.get_display_name())

	elif item.category == ItemData.Category.HEAL_HP or item.category == ItemData.Category.HEAL_AND_CURE:
		if target.is_fainted():
			message.emit("%s sudah pingsan." % target.get_display_name())
		elif target.current_hp >= target.max_hp():
			message.emit("HP %s sudah penuh." % target.get_display_name())
		else:
			var heal: int = item.heal_amount if item.heal_amount >= 0 else target.max_hp()
			target.current_hp = mini(target.max_hp(), target.current_hp + heal)
			used = true
			message.emit("HP %s pulih!" % target.get_display_name())
			hp_updated.emit(target == player_mon.instance, target.current_hp, target.max_hp())

	if item.category == ItemData.Category.CURE_STATUS or item.category == ItemData.Category.HEAL_AND_CURE:
		var cures_this: bool = item.cures_all_status or target.status == item.cures_status
		if not target.is_healthy() and cures_this:
			message.emit("%s sembuh dari %s!" % [target.get_display_name(), target.get_status_name()])
			target.cure_status()
			used = true
		elif item.category == ItemData.Category.CURE_STATUS and not used:
			message.emit("Tidak ada efek.")

	await get_tree().create_timer(MESSAGE_DELAY).timeout

	if not used:
		_start_player_turn()
		return

	bag.remove_item(item, 1)

	# Pakai item = buang giliran, musuh tetap menyerang duluan (kalau masih hidup).
	var enemy_move_index: int = _enemy_choose_move_index()
	if enemy_move_index != -1 and not enemy_mon.is_fainted():
		await _execute_move(enemy_mon, player_mon, enemy_move_index, false)
		if _check_faint():
			return

	await get_tree().create_timer(0.3).timeout
	_start_player_turn()
