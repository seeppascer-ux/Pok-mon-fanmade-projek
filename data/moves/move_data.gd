class_name MoveData
extends Resource

enum Category { PHYSICAL, SPECIAL, STATUS }

## Efek tambahan di luar damage. NONE = murni damage/tidak ada efek lain.
enum Effect { NONE, STAT_CHANGE, HEAL, STATUS_CONDITION }
enum StatTarget { SELF, ENEMY }
enum Stat { ATTACK, DEFENSE, SP_ATTACK, SP_DEFENSE, SPEED, ACCURACY, EVASION }

@export var move_name: String = "Tackle"
@export var type: Types.Type = Types.Type.NORMAL
@export var category: Category = Category.PHYSICAL
@export var power: int = 40
@export var accuracy: int = 100 ## 0-100. Pakai -1 kalau mau selalu kena.
@export var max_pp: int = 35
@export_multiline var description: String = ""

@export_group("Efek Tambahan (opsional)")
## Contoh: Growl = STAT_CHANGE, target ENEMY, stat ATTACK, amount -1
@export var effect: Effect = Effect.NONE
@export var effect_chance: int = 100 ## 0-100, persen kemungkinan efek ini terjadi
@export var effect_target: StatTarget = StatTarget.ENEMY
@export var effect_stat: Stat = Stat.ATTACK ## dipakai kalau effect = STAT_CHANGE
@export var effect_amount: int = -1 ## STAT_CHANGE: +/- jumlah stage (maks 6). HEAL: persen max HP dipulihkan.
## Status yang diberikan kalau effect = STATUS_CONDITION (lihat StatusCondition.Status).
## Contoh: Ember = STATUS_CONDITION, effect_chance 10, effect_status BURN.
@export var effect_status: int = StatusCondition.Status.NONE
