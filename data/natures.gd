class_name Natures
extends RefCounted

## Sistem Nature (sifat) Pokemon. 1 dari 25 nature di-roll acak buat tiap
## PokemonInstance baru (lihat PokemonInstance.setup_default()). Nature
## menaikkan 1 stat +10% dan menurunkan 1 stat lain -10% (HP tidak pernah
## kena pengaruh nature, sama seperti game aslinya). 5 nature "netral"
## (Hardy, Docile, Serious, Bashful, Quirky) tidak menaikkan/menurunkan apa-apa.

enum Nature {
	HARDY, LONELY, BRAVE, ADAMANT, NAUGHTY,
	BOLD, DOCILE, RELAXED, IMPISH, LAX,
	TIMID, HASTY, SERIOUS, JOLLY, NAIVE,
	MODEST, MILD, QUIET, BASHFUL, RASH,
	CALM, GENTLE, SASSY, CAREFUL, QUIRKY,
}

## Index stat, dipakai bareng PokemonInstance._calc_stat()
enum Stat { ATTACK, DEFENSE, SP_ATTACK, SP_DEFENSE, SPEED }

## Tiap nature: [stat_yang_naik, stat_yang_turun]. -1 berarti tidak ada
## (nature netral).
const _TABLE := {
	Nature.HARDY:   [-1, -1],
	Nature.LONELY:  [Stat.ATTACK, Stat.DEFENSE],
	Nature.BRAVE:   [Stat.ATTACK, Stat.SPEED],
	Nature.ADAMANT: [Stat.ATTACK, Stat.SP_ATTACK],
	Nature.NAUGHTY: [Stat.ATTACK, Stat.SP_DEFENSE],
	Nature.BOLD:    [Stat.DEFENSE, Stat.ATTACK],
	Nature.DOCILE:  [-1, -1],
	Nature.RELAXED: [Stat.DEFENSE, Stat.SPEED],
	Nature.IMPISH:  [Stat.DEFENSE, Stat.SP_ATTACK],
	Nature.LAX:     [Stat.DEFENSE, Stat.SP_DEFENSE],
	Nature.TIMID:   [Stat.SPEED, Stat.ATTACK],
	Nature.HASTY:   [Stat.SPEED, Stat.DEFENSE],
	Nature.SERIOUS: [-1, -1],
	Nature.JOLLY:   [Stat.SPEED, Stat.SP_ATTACK],
	Nature.NAIVE:   [Stat.SPEED, Stat.SP_DEFENSE],
	Nature.MODEST:  [Stat.SP_ATTACK, Stat.ATTACK],
	Nature.MILD:    [Stat.SP_ATTACK, Stat.DEFENSE],
	Nature.QUIET:   [Stat.SP_ATTACK, Stat.SPEED],
	Nature.BASHFUL: [-1, -1],
	Nature.RASH:    [Stat.SP_ATTACK, Stat.SP_DEFENSE],
	Nature.CALM:    [Stat.SP_DEFENSE, Stat.ATTACK],
	Nature.GENTLE:  [Stat.SP_DEFENSE, Stat.DEFENSE],
	Nature.SASSY:   [Stat.SP_DEFENSE, Stat.SPEED],
	Nature.CAREFUL: [Stat.SP_DEFENSE, Stat.SP_ATTACK],
	Nature.QUIRKY:  [-1, -1],
}


## Kalikan stat_index (pakai enum Stat di atas) sesuai nature. 1.1 kalau
## naik, 0.9 kalau turun, 1.0 kalau netral/tidak berpengaruh.
static func get_multiplier(nature: int, stat_index: int) -> float:
	if not _TABLE.has(nature):
		return 1.0
	var pair: Array = _TABLE[nature]
	if pair[0] == stat_index:
		return 1.1
	if pair[1] == stat_index:
		return 0.9
	return 1.0


## Nama nature yang enak dibaca, misal Nature.ADAMANT -> "Adamant"
static func get_name(nature: int) -> String:
	if nature < 0 or nature >= Nature.size():
		return "-"
	return Nature.keys()[nature].capitalize()


## Nature acak, dipakai PokemonInstance.setup_default() buat Pokemon baru.
static func random_nature() -> int:
	return randi() % Nature.size()
