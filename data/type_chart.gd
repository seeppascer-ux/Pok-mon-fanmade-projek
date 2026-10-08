class_name TypeChart
extends RefCounted

## Tabel keefektifan tipe (mirip game Pokemon asli, disederhanakan ke Gen 6+
## di mana Ghost vs Dark tidak immune dan Steel resist Dark dihapus, dst
## tidak semuanya included -- cukup buat kebutuhan battle dasar).
## 2.0 = sangat efektif, 0.5 = kurang efektif, 0.0 = tidak berpengaruh sama sekali.

## Pokemon bisa punya 2 tipe, jadi hasil akhirnya dikali dari kedua tipe defender.
static func get_multiplier(attack_type: Types.Type, defend_type1: Types.Type, defend_type2: Types.Type) -> float:
	var m: float = _single(attack_type, defend_type1)
	if defend_type2 != Types.Type.NONE and defend_type2 != defend_type1:
		m *= _single(attack_type, defend_type2)
	return m


static func _single(atk: Types.Type, defend: Types.Type) -> float:
	match atk:
		Types.Type.NORMAL:
			match defend:
				Types.Type.ROCK, Types.Type.STEEL:
					return 0.5
				Types.Type.GHOST:
					return 0.0
		Types.Type.FIRE:
			match defend:
				Types.Type.GRASS, Types.Type.ICE, Types.Type.BUG, Types.Type.STEEL:
					return 2.0
				Types.Type.FIRE, Types.Type.WATER, Types.Type.ROCK, Types.Type.DRAGON:
					return 0.5
		Types.Type.WATER:
			match defend:
				Types.Type.FIRE, Types.Type.GROUND, Types.Type.ROCK:
					return 2.0
				Types.Type.WATER, Types.Type.GRASS, Types.Type.DRAGON:
					return 0.5
		Types.Type.ELECTRIC:
			match defend:
				Types.Type.WATER, Types.Type.FLYING:
					return 2.0
				Types.Type.ELECTRIC, Types.Type.GRASS, Types.Type.DRAGON:
					return 0.5
				Types.Type.GROUND:
					return 0.0
		Types.Type.GRASS:
			match defend:
				Types.Type.WATER, Types.Type.GROUND, Types.Type.ROCK:
					return 2.0
				Types.Type.FIRE, Types.Type.GRASS, Types.Type.POISON, Types.Type.FLYING, \
				Types.Type.BUG, Types.Type.DRAGON, Types.Type.STEEL:
					return 0.5
		Types.Type.ICE:
			match defend:
				Types.Type.GRASS, Types.Type.GROUND, Types.Type.FLYING, Types.Type.DRAGON:
					return 2.0
				Types.Type.FIRE, Types.Type.WATER, Types.Type.ICE, Types.Type.STEEL:
					return 0.5
		Types.Type.FIGHTING:
			match defend:
				Types.Type.NORMAL, Types.Type.ICE, Types.Type.ROCK, Types.Type.DARK, Types.Type.STEEL:
					return 2.0
				Types.Type.POISON, Types.Type.FLYING, Types.Type.PSYCHIC, Types.Type.BUG, Types.Type.FAIRY:
					return 0.5
				Types.Type.GHOST:
					return 0.0
		Types.Type.POISON:
			match defend:
				Types.Type.GRASS, Types.Type.FAIRY:
					return 2.0
				Types.Type.POISON, Types.Type.GROUND, Types.Type.ROCK, Types.Type.GHOST:
					return 0.5
				Types.Type.STEEL:
					return 0.0
		Types.Type.GROUND:
			match defend:
				Types.Type.FIRE, Types.Type.ELECTRIC, Types.Type.POISON, Types.Type.ROCK, Types.Type.STEEL:
					return 2.0
				Types.Type.GRASS, Types.Type.BUG:
					return 0.5
				Types.Type.FLYING:
					return 0.0
		Types.Type.FLYING:
			match defend:
				Types.Type.GRASS, Types.Type.FIGHTING, Types.Type.BUG:
					return 2.0
				Types.Type.ELECTRIC, Types.Type.ROCK, Types.Type.STEEL:
					return 0.5
		Types.Type.PSYCHIC:
			match defend:
				Types.Type.FIGHTING, Types.Type.POISON:
					return 2.0
				Types.Type.PSYCHIC, Types.Type.STEEL:
					return 0.5
				Types.Type.DARK:
					return 0.0
		Types.Type.BUG:
			match defend:
				Types.Type.GRASS, Types.Type.PSYCHIC, Types.Type.DARK:
					return 2.0
				Types.Type.FIRE, Types.Type.FIGHTING, Types.Type.POISON, Types.Type.FLYING, \
				Types.Type.GHOST, Types.Type.STEEL, Types.Type.FAIRY:
					return 0.5
		Types.Type.ROCK:
			match defend:
				Types.Type.FIRE, Types.Type.ICE, Types.Type.FLYING, Types.Type.BUG:
					return 2.0
				Types.Type.FIGHTING, Types.Type.GROUND, Types.Type.STEEL:
					return 0.5
		Types.Type.GHOST:
			match defend:
				Types.Type.PSYCHIC, Types.Type.GHOST:
					return 2.0
				Types.Type.DARK:
					return 0.5
				Types.Type.NORMAL:
					return 0.0
		Types.Type.DRAGON:
			match defend:
				Types.Type.DRAGON:
					return 2.0
				Types.Type.STEEL:
					return 0.5
				Types.Type.FAIRY:
					return 0.0
		Types.Type.DARK:
			match defend:
				Types.Type.PSYCHIC, Types.Type.GHOST:
					return 2.0
				Types.Type.FIGHTING, Types.Type.DARK, Types.Type.FAIRY:
					return 0.5
		Types.Type.STEEL:
			match defend:
				Types.Type.ICE, Types.Type.ROCK, Types.Type.FAIRY:
					return 2.0
				Types.Type.FIRE, Types.Type.WATER, Types.Type.ELECTRIC, Types.Type.STEEL:
					return 0.5
		Types.Type.FAIRY:
			match defend:
				Types.Type.FIGHTING, Types.Type.DRAGON, Types.Type.DARK:
					return 2.0
				Types.Type.FIRE, Types.Type.POISON, Types.Type.STEEL:
					return 0.5
	return 1.0
