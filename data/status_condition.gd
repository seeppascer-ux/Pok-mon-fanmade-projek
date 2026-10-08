class_name StatusCondition
extends RefCounted

## Status non-volatile ala game Pokemon asli: Poison, Burn, Paralysis, Sleep,
## Freeze. Maksimal 1 status aktif per Pokemon dalam satu waktu, dan status
## ini nempel di PokemonInstance (bukan BattleMon) supaya tetap kebawa
## walau battle-nya sudah selesai -- persis kayak game asli.
##
## Efeknya sendiri (damage tiap giliran, gagal bergerak, dst) ditangani di
## script/battle/battle_manager.gd. File ini cuma nyimpen enum + teks.

enum Status { NONE, POISON, BURN, PARALYSIS, SLEEP, FREEZE }


## Nama lengkap buat pesan battle, misal "Charmander jadi keracunan!"
## PENTING: sengaja TIDAK dinamai "get_name" -- itu nabrak method bawaan
## Object/Script (Godot bakal salah manggil versi 0-argumen punya Script,
## bukan fungsi static ini, dan errornya cuma "Expected 0 argument(s)"
## tanpa penjelasan lebih jauh). Selalu hindari nama method bawaan Godot
## (get_name, get_class, duplicate, dst) buat static func custom.
static func status_name(status: int) -> String:
	match status:
		Status.POISON:
			return "keracunan"
		Status.BURN:
			return "kebakaran"
		Status.PARALYSIS:
			return "lumpuh"
		Status.SLEEP:
			return "tertidur"
		Status.FREEZE:
			return "membeku"
		_:
			return "-"


## Singkatan 3 huruf buat label kecil di HP bar (mirip "PSN"/"BRN" di game
## asli), kosong kalau sehat.
static func status_abbreviation(status: int) -> String:
	match status:
		Status.POISON:
			return "PSN"
		Status.BURN:
			return "BRN"
		Status.PARALYSIS:
			return "PAR"
		Status.SLEEP:
			return "SLP"
		Status.FREEZE:
			return "FRZ"
		_:
			return ""
