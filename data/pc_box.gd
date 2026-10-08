class_name PCBox
extends Resource

## Penyimpanan Pokemon di luar party (mirip PC Box di game asli). Party
## pemain maksimal PARTY_MAX_SIZE ekor (lihat world.gd) -- begitu nangkap
## Pokemon lagi padahal party sudah penuh, otomatis dikirim ke sini lewat
## world.gd, bukan hilang begitu saja.
##
## Belum ada UI buat lihat/keluarin isi PC secara visual -- baru sistem
## penyimpanan data dulu (deposit/withdraw). Tinggal panggil lewat kode,
## atau dibikinkan menu-nya sendiri kalau perlu.

@export var stored: Array[PokemonInstance] = []


func deposit(instance: PokemonInstance) -> void:
	if instance != null:
		stored.append(instance)


## Keluarkan 1 Pokemon dari PC (misal buat ditukar ke party). Return true
## kalau berhasil ditemukan & dikeluarkan.
func withdraw(instance: PokemonInstance) -> bool:
	var idx: int = stored.find(instance)
	if idx == -1:
		return false
	stored.remove_at(idx)
	return true


func is_empty() -> bool:
	return stored.is_empty()
