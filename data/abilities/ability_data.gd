class_name AbilityData
extends Resource

## Data 1 Ability Pokemon. Belum ada efek otomatis di battle_manager --
## ability cuma "nempel" ke PokemonInstance dulu (ditampilkan di UI, dicek
## manual lewat kode kalau mau bikin efeknya, misal:
##   if my_mon.ability != null and my_mon.ability.ability_name == "Blaze": ...
## Efek otomatis (misal Blaze naikin power move Api pas HP < 1/3) bisa
## ditambah belakangan di battle_manager.gd kalau sudah butuh.

@export var ability_name: String = "-"
@export_multiline var description: String = ""
