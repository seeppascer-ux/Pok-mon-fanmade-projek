class_name ExpCurve
extends RefCounted

## Rumus kurva EXP resmi game Pokemon buat 4 growth rate yang dipakai di
## PokemonSpecies.GrowthRate (Fast, Medium Fast, Medium Slow, Slow).
## Dipanggil lewat PokemonSpecies.total_exp_for_level(), yang dipakai
## PokemonInstance.gain_exp() buat nentuin kapan Pokemon naik level.
##
## PENTING: sengaja TIDAK referensi "PokemonSpecies.GrowthRate.FAST" dkk
## langsung di sini. 2 class_name yang saling rujuk (PokemonSpecies manggil
## ExpCurve.total_exp(), dan kalau ExpCurve balik manggil enum di dalam
## PokemonSpecies) bisa bikin Godot gagal compile salah satunya pas project
## pertama kali dibuka/reload -- muncul sebagai error runtime aneh kayak
## "Nonexistent function 'total_exp_for_level'" padahal fungsinya ada di
## kode. Makanya "growth_rate" di bawah cuma int polos, urutannya HARUS
## SAMA dengan PokemonSpecies.GrowthRate: 0=Fast, 1=Medium Fast,
## 2=Medium Slow, 3=Slow (dikirim otomatis karena enum GDScript = int).

const FAST: int = 0
const MEDIUM_FAST: int = 1
const MEDIUM_SLOW: int = 2
const SLOW: int = 3


## Total EXP kumulatif (dari Level 1) yang dibutuhkan buat sampai "level".
static func total_exp(growth_rate: int, level: int) -> int:
	var n: float = float(maxi(level, 0))
	match growth_rate:
		FAST:
			return int(floor(0.8 * pow(n, 3)))
		MEDIUM_FAST:
			return int(floor(pow(n, 3)))
		MEDIUM_SLOW:
			var value: float = (1.2 * pow(n, 3)) - (15.0 * pow(n, 2)) + (100.0 * n) - 140.0
			return maxi(0, int(floor(value))) # rumus ini bisa negatif di level rendah, clamp ke 0
		SLOW:
			return int(floor(1.25 * pow(n, 3)))
		_:
			return int(floor(pow(n, 3)))
