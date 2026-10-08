class_name Types
extends RefCounted

## Daftar semua tipe Pokemon. Tambah sendiri kalau perlu tipe lain.
enum Type {
	NONE,
	NORMAL,
	FIRE,
	WATER,
	GRASS,
	ELECTRIC,
	ICE,
	FIGHTING,
	POISON,
	GROUND,
	FLYING,
	PSYCHIC,
	BUG,
	ROCK,
	GHOST,
	DRAGON,
	DARK,
	STEEL,
	FAIRY,
}

## Ubah enum jadi teks yang enak dibaca, misal Type.FIRE -> "Fire"
static func type_name(t: Type) -> String:
	return Type.keys()[t].capitalize()


## Warna khas tiap tipe (dipakai buat kasih warna latar tombol move di battle UI,
## dan bisa dipakai juga di tempat lain kayak Pokedex/party screen kalau perlu).
static func type_color(t: Type) -> Color:
	match t:
		Type.NORMAL:
			return Color("A8A878")
		Type.FIRE:
			return Color("F08030")
		Type.WATER:
			return Color("6890F0")
		Type.GRASS:
			return Color("78C850")
		Type.ELECTRIC:
			return Color("F8D030")
		Type.ICE:
			return Color("98D8D8")
		Type.FIGHTING:
			return Color("C03028")
		Type.POISON:
			return Color("A040A0")
		Type.GROUND:
			return Color("E0C068")
		Type.FLYING:
			return Color("A890F0")
		Type.PSYCHIC:
			return Color("F85888")
		Type.BUG:
			return Color("A8B820")
		Type.ROCK:
			return Color("B8A038")
		Type.GHOST:
			return Color("705898")
		Type.DRAGON:
			return Color("7038F8")
		Type.DARK:
			return Color("705848")
		Type.STEEL:
			return Color("B8B8D0")
		Type.FAIRY:
			return Color("EE99AC")
		_:
			return Color("909090") ## NONE / tidak diketahui
