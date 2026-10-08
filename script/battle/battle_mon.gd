class_name BattleMon
extends RefCounted

## Bungkus PokemonInstance selama satu battle berlangsung.
## Stat stage (naik/turun sementara akibat move kayak Growl) disimpan di sini,
## BUKAN di PokemonInstance, supaya begitu battle selesai stat balik normal
## dan HP/PP yang memang harus permanen tetap tersimpan di instance aslinya.

var instance: PokemonInstance

var stage_attack: int = 0
var stage_defense: int = 0
var stage_sp_attack: int = 0
var stage_sp_defense: int = 0
var stage_speed: int = 0
var stage_accuracy: int = 0
var stage_evasion: int = 0


func _init(p_instance: PokemonInstance) -> void:
	instance = p_instance
	instance.setup_default()


func get_display_name() -> String:
	return instance.get_display_name()


func _stage_multiplier(stage: int) -> float:
	stage = clampi(stage, -6, 6)
	if stage >= 0:
		return (2.0 + stage) / 2.0
	return 2.0 / (2.0 - stage)


func get_attack() -> float:
	var value: float = instance.attack() * _stage_multiplier(stage_attack)
	if instance.status == StatusCondition.Status.BURN:
		value *= 0.5 # Burn separuhin Attack fisik, persis kayak game asli
	return value


func get_defense() -> float:
	return instance.defense() * _stage_multiplier(stage_defense)


func get_sp_attack() -> float:
	return instance.sp_attack() * _stage_multiplier(stage_sp_attack)


func get_sp_defense() -> float:
	return instance.sp_defense() * _stage_multiplier(stage_sp_defense)


func get_speed() -> float:
	var value: float = instance.speed() * _stage_multiplier(stage_speed)
	if instance.status == StatusCondition.Status.PARALYSIS:
		value *= 0.25 # Paralysis motongin Speed jadi 1/4, persis kayak game asli
	return value


## Ubah salah satu stat stage. Mengembalikan berapa besar perubahan yang
## BENAR-BENAR terjadi (bisa 0 kalau sudah mentok di +6/-6).
func modify_stage(stat_name: String, amount: int) -> int:
	var before: int = 0
	match stat_name:
		"attack":
			before = stage_attack
		"defense":
			before = stage_defense
		"sp_attack":
			before = stage_sp_attack
		"sp_defense":
			before = stage_sp_defense
		"speed":
			before = stage_speed
		"accuracy":
			before = stage_accuracy
		"evasion":
			before = stage_evasion
		_:
			return 0

	var after: int = clampi(before + amount, -6, 6)
	match stat_name:
		"attack":
			stage_attack = after
		"defense":
			stage_defense = after
		"sp_attack":
			stage_sp_attack = after
		"sp_defense":
			stage_sp_defense = after
		"speed":
			stage_speed = after
		"accuracy":
			stage_accuracy = after
		"evasion":
			stage_evasion = after

	return after - before


func is_fainted() -> bool:
	return instance.is_fainted()


func take_damage(amount: int) -> void:
	instance.current_hp = maxi(0, instance.current_hp - amount)


func heal(amount: int) -> void:
	instance.current_hp = mini(instance.max_hp(), instance.current_hp + amount)
