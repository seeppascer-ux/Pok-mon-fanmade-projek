class_name ItemData
extends Resource

## Data 1 jenis item Tas (Poke Ball, Potion, Antidote, dst). Ini data
## SPESIES item -- jumlah yang dipunya player disimpan terpisah di Bag
## (lihat data/bag.gd + data/items/bag_slot.gd), persis seperti PokemonSpecies
## (data) vs PokemonInstance (milik player).

enum Category {
	POKE_BALL,     ## dipakai buat nangkap Pokemon liar, lihat "catch_multiplier"
	HEAL_HP,       ## pulihin HP, lihat "heal_amount"
	CURE_STATUS,   ## sembuhin status condition, lihat "cures_status"/"cures_all_status"
	HEAL_AND_CURE, ## pulihin HP SEKALIGUS sembuhin status (misal Full Restore)
	REVIVE,        ## hidupin lagi Pokemon yang pingsan, lihat "heal_amount"
	OTHER,         ## item lain yang belum ada efek otomatisnya (TM, Batu evolusi, dll)
}

@export var item_name: String = "Item"
@export_multiline var description: String = ""
@export var category: Category = Category.OTHER
@export var icon: Texture2D

@export_group("Poke Ball (dipakai kalau category = POKE_BALL)")
## Pengali peluang tangkap resmi game Pokemon. Poke Ball = 1.0,
## Great Ball = 1.5, Ultra Ball = 2.0, Master Ball = selalu berhasil
## (isi angka besar seperti 255.0).
@export var catch_multiplier: float = 1.0

@export_group("Heal HP (dipakai kalau category = HEAL_HP / HEAL_AND_CURE / REVIVE)")
## Jumlah HP yang dipulihkan. -1 = pulihkan penuh (misal Full Restore/Max Potion,
## atau Revive versi penuh seperti Max Revive).
@export var heal_amount: int = 20

@export_group("Cure Status (dipakai kalau category = CURE_STATUS / HEAL_AND_CURE)")
## Status spesifik yang disembuhkan (lihat StatusCondition.Status), hanya
## dipakai kalau "cures_all_status" di bawah = false. Contoh: Antidote ->
## StatusCondition.Status.POISON.
@export var cures_status: int = StatusCondition.Status.NONE
## true kalau item ini menyembuhkan status APA PUN (misal Full Heal).
@export var cures_all_status: bool = false

@export_group("Battle")
## true kalau item ini boleh dipakai lewat menu Tas pas battle. Item kayak
## TM/Batu evolusi biasanya diisi false di sini (dipakai lewat menu lain,
## bukan pas battle).
@export var usable_in_battle: bool = true
