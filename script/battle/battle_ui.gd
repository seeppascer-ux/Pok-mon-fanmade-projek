class_name BattleUI
extends Control

## Dipancarkan begitu battle selesai (menang/kalah/kabur), supaya kode luar
## (misal world.gd) tahu kapan harus hapus scene battle ini & kembalikan
## kontrol ke player.
signal battle_ended(player_won: bool)
## Dipancarkan begitu Poke Ball berhasil nangkap Pokemon liar -- world.gd
## dengerin ini buat masukin Pokemon-nya ke player_party (atau ke PC kalau
## party sudah penuh).
signal pokemon_captured(instance: PokemonInstance)

## Root scene battle. Tinggal isi party & enemy (lewat Inspector atau lewat
## kode sebelum node ini _ready), scene ini yang urus sisanya: nyambungin
## BattleManager ke tombol-tombol, HP bar, sprite, dan semua animasi di layar.

@export var player_pokemon: PokemonInstance
@export var enemy_pokemon: PokemonInstance
## Seluruh party player (dipakai panel Ganti). player_pokemon selalu sinkron
## dengan anggota party yang sedang bertarung.
var party: Array[PokemonInstance] = []
## Tas item player. Boleh dikosongkan (tombol Tas cuma bakal bilang
## "Tas kosong") -- diisi lewat Inspector (drag res://data/starter_bag.tres
## atau Bag punya sendiri) atau lewat start() dari world.gd.
@export var bag: Bag

## State tombol/panel di area bawah layar. Cuma satu yang kelihatan tiap saat.
enum BottomState { MESSAGE, MAIN_MENU, MOVE_MENU, BAG_MENU, PARTY_MENU }

const HP_GREEN: Color = Color8(24, 192, 32)
const HP_YELLOW: Color = Color8(248, 176, 0)
const HP_RED: Color = Color8(248, 88, 40)
const HP_TWEEN_TIME: float = 0.45
const TEMP_MESSAGE_TIME: float = 1.1
const EXP_FILL: Color = Color8(64, 176, 248)
const EXP_TWEEN_TIME: float = 0.7

@onready var background: TextureRect = $Background
@onready var enemy_sprite: TextureRect = $EnemySprite
@onready var player_sprite: TextureRect = $PlayerSprite

@onready var enemy_name_label: Label = $EnemyPanel/Margin/VBox/HeaderRow/NameLabel
@onready var enemy_level_label: Label = $EnemyPanel/Margin/VBox/HeaderRow/LevelLabel
@onready var enemy_hp_bar: ProgressBar = $EnemyPanel/Margin/VBox/HPRow/HPBar
@onready var enemy_hp_number: Label = $EnemyPanel/Margin/VBox/HPNumberLabel

@onready var player_name_label: Label = $PlayerPanel/Margin/VBox/HeaderRow/NameLabel
@onready var player_level_label: Label = $PlayerPanel/Margin/VBox/HeaderRow/LevelLabel
@onready var player_hp_bar: ProgressBar = $PlayerPanel/Margin/VBox/HPRow/HPBar
@onready var player_hp_number: Label = $PlayerPanel/Margin/VBox/HPNumberLabel
@onready var player_panel: PanelContainer = $PlayerPanel
@onready var player_exp_bar: ProgressBar = $PlayerPanel/Margin/VBox/EXPRow/EXPBar

@onready var message_box: PanelContainer = $BottomArea/MessageBox
@onready var message_label: Label = $BottomArea/MessageBox/MessageMargin/MessageLabel

@onready var main_menu: PanelContainer = $BottomArea/MainMenu
@onready var main_menu_prompt: Label = $BottomArea/MainMenu/MainMenuMargin/MainMenuVBox/PromptLabel
@onready var fight_button: Button = $BottomArea/MainMenu/MainMenuMargin/MainMenuVBox/ActionGrid/FightButton
@onready var bag_button: Button = $BottomArea/MainMenu/MainMenuMargin/MainMenuVBox/ActionGrid/BagButton
@onready var pokemon_button: Button = $BottomArea/MainMenu/MainMenuMargin/MainMenuVBox/ActionGrid/PokemonButton
@onready var run_button: Button = $BottomArea/MainMenu/MainMenuMargin/MainMenuVBox/ActionGrid/RunButton

@onready var move_menu: PanelContainer = $BottomArea/MoveMenu
@onready var move_grid: GridContainer = $BottomArea/MoveMenu/MoveMenuMargin/MoveMenuVBox/MoveGrid
@onready var move_back_button: Button = $BottomArea/MoveMenu/MoveMenuMargin/MoveMenuVBox/BackButton

@onready var bottom_area: Control = $BottomArea

## Panel Tas -- dibikin lewat kode (bukan dari .tscn) supaya patch ini
## tidak perlu edit scene, sama seperti move_grid yang tombolnya juga
## dibikin dinamis lewat _build_move_buttons().
var bag_menu: PanelContainer
var bag_list_vbox: VBoxContainer

## Panel Ganti Pokemon -- juga dibikin lewat kode dengan pola yang sama
## seperti bag_menu di atas (tidak perlu edit .tscn).
var party_menu: PanelContainer
var party_prompt: Label
var party_list_vbox: VBoxContainer
var party_back_button: Button

var battle_manager: BattleManager
var _move_buttons: Array[Button] = []
var _message_tween: Tween
var _enemy_hp_fill_style: StyleBoxFlat
var _player_hp_fill_style: StyleBoxFlat
var _busy_with_temp_message: bool = false


func _ready() -> void:
	battle_manager = BattleManager.new()
	add_child(battle_manager)
	battle_manager.message.connect(_on_message)
	battle_manager.hp_updated.connect(_on_hp_updated)
	battle_manager.request_player_move.connect(_on_request_player_move)
	battle_manager.battle_ended.connect(_on_battle_ended)
	battle_manager.fled.connect(_on_fled)
	battle_manager.move_used.connect(_on_move_used)
	battle_manager.captured.connect(_on_captured)
	battle_manager.exp_gained.connect(_on_exp_gained)
	battle_manager.request_player_switch.connect(_on_request_player_switch)
	battle_manager.pokemon_switched.connect(_on_pokemon_switched)

	fight_button.pressed.connect(_on_fight_pressed)
	bag_button.pressed.connect(_on_bag_pressed)
	pokemon_button.pressed.connect(_on_pokemon_pressed)
	run_button.pressed.connect(_on_run_pressed)
	move_back_button.pressed.connect(_on_move_back_pressed)

	_build_bag_menu()
	_build_party_menu()
	_setup_hp_bar_styles()
	_setup_exp_bar_styles()
	_style_main_menu_buttons()
	_set_bottom_state(BottomState.MESSAGE)
	message_label.text = "..."

	if player_pokemon != null and enemy_pokemon != null:
		var init_party: Array[PokemonInstance] = [player_pokemon]
		start(init_party, enemy_pokemon)


## Panggil ini dari luar (misal dari world.gd saat encounter) kalau tidak
## di-set lewat Inspector, contoh:
##   var battle_scene = preload("res://scene/battle_ui.tscn").instantiate()
##   add_child(battle_scene)
##   battle_scene.start(my_party, wild_pokemon, my_bag)
func start(p_party: Array[PokemonInstance], p_enemy: PokemonInstance, p_bag: Bag = null) -> void:
	party = p_party
	enemy_pokemon = p_enemy
	if p_bag != null:
		bag = p_bag

	for mon in party:
		mon.setup_default()
	p_enemy.setup_default()

	# BattleManager yang memilih siapa dikirim pertama (yang pertama hidup).
	battle_manager.start_battle(party, p_enemy)
	player_pokemon = battle_manager.player_mon.instance
	_setup_player_side()

	enemy_name_label.text = p_enemy.get_display_name()
	enemy_level_label.text = "Lv.%d" % p_enemy.level
	_set_hp_immediate(false, p_enemy.current_hp, p_enemy.max_hp())
	_setup_sprite(enemy_sprite, p_enemy.species.get_front_display_texture(p_enemy.is_female()) if p_enemy.species != null else null)

	# Tunggu 1 frame supaya Godot selesai hitung ukuran/posisi sprite (layout
	# anchor) dulu sebelum animasi masuk dimainkan -- kalau langsung main
	# tanpa nunggu, pivot_offset buat animasi scale bisa salah hitung.
	await get_tree().process_frame
	_play_entrance_animation()



## Refresh seluruh sisi player (nama, level, HP, EXP, sprite, tombol move)
## dari player_pokemon saat ini. Dipakai saat battle mulai & tiap ganti Pokemon.
func _setup_player_side() -> void:
	if player_pokemon == null:
		return
	player_name_label.text = player_pokemon.get_display_name()
	player_level_label.text = "Lv.%d" % player_pokemon.level
	_set_hp_immediate(true, player_pokemon.current_hp, player_pokemon.max_hp())
	_set_exp_immediate()
	_setup_sprite(player_sprite, player_pokemon.species.get_back_display_texture(player_pokemon.is_female()) if player_pokemon.species != null else null)
	_build_move_buttons(player_pokemon)


func _setup_sprite(sprite: TextureRect, texture: Texture2D) -> void:
	sprite.texture = texture
	# Kalau belum ada gambar sprite buat spesies ini, sembunyikan TextureRect-nya
	# saja (drpd nampilin ikon "gambar rusak") -- panel nama/level/HP tetap
	# kelihatan normal. Tinggal isi field "Sprite Front"/"Sprite Back" di
	# resource PokemonSpecies begitu ada gambarnya, otomatis muncul di sini.
	sprite.visible = texture != null
	sprite.modulate = Color(1, 1, 1, 1)
	sprite.scale = Vector2.ONE


func _build_move_buttons(instance: PokemonInstance) -> void:
	for child in move_grid.get_children():
		child.queue_free()
	_move_buttons.clear()

	for i in instance.moves.size():
		var move: MoveData = instance.moves[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 64)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.clip_text = false
		btn.pressed.connect(_on_move_button_pressed.bind(i))
		_style_move_button(btn, move.type)
		move_grid.add_child(btn)
		_move_buttons.append(btn)

	_refresh_move_button_labels()


## Bikin panel "BagMenu" 1x lewat kode di _ready(), ditambahkan sebagai anak
## $BottomArea persis seperti MessageBox/MainMenu/MoveMenu di .tscn (anchor
## full-rect, cuma 1 panel yang visible tiap saat lewat _set_bottom_state()).
func _build_bag_menu() -> void:
	bag_menu = PanelContainer.new()
	bag_menu.name = "BagMenu"
	bag_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	bottom_area.add_child(bag_menu)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	bag_menu.add_child(margin)

	var vbox := VBoxContainer.new()
	margin.add_child(vbox)

	var prompt := Label.new()
	prompt.text = "Pilih item:"
	prompt.add_theme_font_size_override("font_size", 16)
	vbox.add_child(prompt)

	bag_list_vbox = VBoxContainer.new()
	bag_list_vbox.add_theme_constant_override("separation", 4)
	vbox.add_child(bag_list_vbox)

	var back_btn := Button.new()
	back_btn.text = "Kembali"
	back_btn.custom_minimum_size = Vector2(0, 40)
	back_btn.pressed.connect(_on_bag_back_pressed)
	_apply_solid_button_style(back_btn, Color8(120, 120, 130))
	vbox.add_child(back_btn)


func _refresh_bag_list() -> void:
	for child in bag_list_vbox.get_children():
		child.queue_free()

	if bag == null or bag.slots.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Tas kosong."
		bag_list_vbox.add_child(empty_label)
		return

	for slot in bag.slots:
		if slot.item == null or slot.quantity <= 0 or not slot.item.usable_in_battle:
			continue
		var btn := Button.new()
		btn.text = "%s  x%d" % [slot.item.item_name, slot.quantity]
		btn.custom_minimum_size = Vector2(0, 44)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if slot.item.description != "":
			btn.tooltip_text = slot.item.description
		btn.pressed.connect(_on_bag_item_pressed.bind(slot.item))
		_apply_solid_button_style(btn, Color8(70, 150, 214))
		bag_list_vbox.add_child(btn)


## ---------------------------------------------------------------------
## PANEL GANTI POKEMON
## ---------------------------------------------------------------------

## Bikin panel "PartyMenu" 1x lewat kode di _ready(), pola persis seperti
## _build_bag_menu() di atas (tidak perlu edit .tscn).
func _build_party_menu() -> void:
	party_menu = PanelContainer.new()
	party_menu.name = "PartyMenu"
	party_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	bottom_area.add_child(party_menu)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	party_menu.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	party_prompt = Label.new()
	party_prompt.text = "Pilih Pokemon:"
	party_prompt.add_theme_font_size_override("font_size", 16)
	vbox.add_child(party_prompt)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	party_list_vbox = VBoxContainer.new()
	party_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	party_list_vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(party_list_vbox)

	party_back_button = Button.new()
	party_back_button.text = "Kembali"
	party_back_button.custom_minimum_size = Vector2(0, 40)
	party_back_button.pressed.connect(_on_party_back_pressed)
	_apply_solid_button_style(party_back_button, Color8(120, 120, 130))
	vbox.add_child(party_back_button)


## Isi ulang daftar party. forced=true (habis pingsan): wajib pilih pengganti,
## tombol Kembali disembunyikan. Yang pingsan & yang sedang bertarung tidak
## bisa dipilih (tombol disabled + label status).
func _refresh_party_list(forced: bool) -> void:
	for child in party_list_vbox.get_children():
		child.queue_free()

	party_prompt.text = "Pilih Pokemon pengganti!" if forced else "Pilih Pokemon:"
	party_back_button.visible = not forced

	if party.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Party kosong."
		party_list_vbox.add_child(empty_label)
		return

	var active_index: int = battle_manager.player_party_index if battle_manager != null else 0
	for i in party.size():
		party_list_vbox.add_child(_build_party_row(party[i], i, i == active_index))


func _build_party_row(mon: PokemonInstance, index: int, is_current: bool) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 64)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(_on_party_member_pressed.bind(index))

	var row := VBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(row)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(top)

	var name_label := Label.new()
	name_label.text = "%s   Lv.%d" % [mon.get_display_name(), mon.level]
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(name_label)

	var tag_label := Label.new()
	tag_label.add_theme_font_size_override("font_size", 14)
	tag_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_current:
		tag_label.text = "[Sedang bertarung]"
		tag_label.modulate = Color(0.6, 0.9, 1.0)
	elif mon.is_fainted():
		tag_label.text = "[Pingsan]"
		tag_label.modulate = Color(1.0, 0.55, 0.5)
	elif not mon.is_healthy():
		tag_label.text = "[%s]" % mon.get_status_name()
		tag_label.modulate = Color(1.0, 0.75, 0.4)
	top.add_child(tag_label)

	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 8)
	hp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(hp_row)

	var hp_bar := ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(160, 12)
	hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_bar.max_value = maxi(mon.max_hp(), 1)
	hp_bar.value = maxi(mon.current_hp, 0)
	hp_bar.show_percentage = false
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = _hp_color_for_ratio(float(maxi(mon.current_hp, 0)) / float(maxi(mon.max_hp(), 1)))
	fill.set_corner_radius_all(4)
	hp_bar.add_theme_stylebox_override("fill", fill)
	hp_row.add_child(hp_bar)

	var hp_label := Label.new()
	hp_label.text = "%d/%d" % [maxi(mon.current_hp, 0), mon.max_hp()]
	hp_label.add_theme_font_size_override("font_size", 14)
	hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_row.add_child(hp_label)

	var selectable: bool = not is_current and not mon.is_fainted()
	btn.disabled = not selectable
	if not selectable:
		btn.modulate = Color(1, 1, 1, 0.55)
	_apply_solid_button_style(btn, Color8(84, 180, 108) if selectable else Color8(110, 110, 120))

	return btn


func _refresh_move_button_labels() -> void:
	for i in _move_buttons.size():
		var move: MoveData = player_pokemon.moves[i]
		var pp: int = player_pokemon.move_pp[i]
		_move_buttons[i].text = "%s\n%s   PP %d/%d" % [move.move_name, Types.type_name(move.type), pp, move.max_pp]
		_move_buttons[i].disabled = pp <= 0
		if move.description != "":
			_move_buttons[i].tooltip_text = move.description


func _style_move_button(btn: Button, move_type: Types.Type) -> void:
	var base_color: Color = Types.type_color(move_type)

	var normal := StyleBoxFlat.new()
	normal.bg_color = base_color
	normal.border_width_left = 3
	normal.border_width_top = 3
	normal.border_width_right = 3
	normal.border_width_bottom = 3
	normal.border_color = base_color.darkened(0.4)
	normal.corner_radius_top_left = 10
	normal.corner_radius_top_right = 10
	normal.corner_radius_bottom_left = 10
	normal.corner_radius_bottom_right = 10
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = base_color.lightened(0.15)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = base_color.darkened(0.2)

	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = base_color.darkened(0.35)
	disabled.bg_color.a = 0.6
	disabled.border_color = disabled.bg_color.darkened(0.3)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.6))
	btn.add_theme_font_size_override("font_size", 16)


func _style_main_menu_buttons() -> void:
	_apply_solid_button_style(fight_button, Color8(224, 76, 58))
	_apply_solid_button_style(bag_button, Color8(70, 150, 214))
	_apply_solid_button_style(pokemon_button, Color8(84, 180, 108))
	_apply_solid_button_style(run_button, Color8(230, 178, 46))
	_apply_solid_button_style(move_back_button, Color8(120, 120, 130))


func _apply_solid_button_style(btn: Button, base_color: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = base_color
	normal.border_width_left = 3
	normal.border_width_top = 3
	normal.border_width_right = 3
	normal.border_width_bottom = 3
	normal.border_color = base_color.darkened(0.35)
	normal.corner_radius_top_left = 10
	normal.corner_radius_top_right = 10
	normal.corner_radius_bottom_left = 10
	normal.corner_radius_bottom_right = 10

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = base_color.lightened(0.15)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = base_color.darkened(0.2)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 18)


func _setup_hp_bar_styles() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.12, 0.14)
	bg.corner_radius_top_left = 6
	bg.corner_radius_top_right = 6
	bg.corner_radius_bottom_left = 6
	bg.corner_radius_bottom_right = 6

	_enemy_hp_fill_style = StyleBoxFlat.new()
	_enemy_hp_fill_style.bg_color = HP_GREEN
	_enemy_hp_fill_style.corner_radius_top_left = 6
	_enemy_hp_fill_style.corner_radius_top_right = 6
	_enemy_hp_fill_style.corner_radius_bottom_left = 6
	_enemy_hp_fill_style.corner_radius_bottom_right = 6

	_player_hp_fill_style = _enemy_hp_fill_style.duplicate()

	enemy_hp_bar.add_theme_stylebox_override("background", bg.duplicate())
	enemy_hp_bar.add_theme_stylebox_override("fill", _enemy_hp_fill_style)
	player_hp_bar.add_theme_stylebox_override("background", bg.duplicate())
	player_hp_bar.add_theme_stylebox_override("fill", _player_hp_fill_style)


func _hp_color_for_ratio(ratio: float) -> Color:
	if ratio > 0.5:
		return HP_GREEN
	elif ratio > 0.2:
		return HP_YELLOW
	return HP_RED


func _set_bottom_state(state: BottomState) -> void:
	message_box.visible = state == BottomState.MESSAGE
	main_menu.visible = state == BottomState.MAIN_MENU
	move_menu.visible = state == BottomState.MOVE_MENU
	if bag_menu != null:
		bag_menu.visible = state == BottomState.BAG_MENU
	if party_menu != null:
		party_menu.visible = state == BottomState.PARTY_MENU


func _set_hp_immediate(is_player: bool, current: int, max_hp: int) -> void:
	var bar: ProgressBar = player_hp_bar if is_player else enemy_hp_bar
	var label: Label = player_hp_number if is_player else enemy_hp_number
	var style: StyleBoxFlat = _player_hp_fill_style if is_player else _enemy_hp_fill_style

	bar.max_value = max_hp
	bar.value = current
	label.text = "%d / %d" % [current, max_hp]
	if style != null:
		style.bg_color = _hp_color_for_ratio(float(current) / maxf(float(max_hp), 1.0))


## ---------------------------------------------------------------------
## EXP BAR + LEVEL UP
## ---------------------------------------------------------------------

func _setup_exp_bar_styles() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.12, 0.14)
	bg.corner_radius_top_left = 4
	bg.corner_radius_top_right = 4
	bg.corner_radius_bottom_left = 4
	bg.corner_radius_bottom_right = 4

	var fill := StyleBoxFlat.new()
	fill.bg_color = EXP_FILL
	fill.corner_radius_top_left = 4
	fill.corner_radius_top_right = 4
	fill.corner_radius_bottom_left = 4
	fill.corner_radius_bottom_right = 4

	player_exp_bar.add_theme_stylebox_override("background", bg)
	player_exp_bar.add_theme_stylebox_override("fill", fill)


## Rasio 0..1 progres EXP di level tertentu (1.0 kalau sudah level 100).
func _exp_ratio_for(instance: PokemonInstance, exp_value: int, level_value: int) -> float:
	if instance == null or instance.species == null or level_value >= 100:
		return 1.0
	var base: int = instance.species.total_exp_for_level(level_value)
	var next: int = instance.species.total_exp_for_level(level_value + 1)
	if next <= base:
		return 1.0
	return clampf(float(exp_value - base) / float(next - base), 0.0, 1.0)


func _set_exp_immediate() -> void:
	if player_pokemon == null or player_exp_bar == null:
		return
	player_exp_bar.value = _exp_ratio_for(player_pokemon, player_pokemon.exp, player_pokemon.level) * player_exp_bar.max_value


## Dipanggil saat BattleManager selesai menghitung EXP (sinyal exp_gained).
## EXP-nya sendiri sudah di-apply ke instance; tugas fungsi ini cuma
## menganimasikan bar dari posisi LAMA ke posisi BARU, level per level.
func _on_exp_gained(_amount: int, old_exp: int, old_level: int, new_level: int) -> void:
	if player_pokemon == null or player_pokemon.species == null:
		return
	_animate_exp_gain(old_exp, old_level, new_level)


func _animate_exp_gain(old_exp: int, old_level: int, new_level: int) -> void:
	var bar_max: float = player_exp_bar.max_value
	var cur_level: int = old_level
	# Mulai dari posisi lama (instance.exp sudah berisi nilai baru).
	player_exp_bar.value = _exp_ratio_for(player_pokemon, old_exp, old_level) * bar_max

	while cur_level < new_level:
		var threshold: int = player_pokemon.species.total_exp_for_level(cur_level + 1)
		var fill_tween: Tween = create_tween()
		fill_tween.tween_property(player_exp_bar, "value", bar_max, EXP_TWEEN_TIME)
		await fill_tween.finished
		cur_level += 1
		_play_level_up_fx()
		player_level_label.text = "Lv.%d" % cur_level
		player_exp_bar.value = 0.0
		await get_tree().create_timer(0.35).timeout

	var final_ratio: float = _exp_ratio_for(player_pokemon, player_pokemon.exp, new_level)
	var rest_tween: Tween = create_tween()
	rest_tween.tween_property(player_exp_bar, "value", final_ratio * bar_max, EXP_TWEEN_TIME)
	await rest_tween.finished


## Efek tiap naik level: panel pemain berkedip cerah + label level membesar sesaat.
func _play_level_up_fx() -> void:
	var flash: Tween = create_tween()
	flash.set_parallel(true)
	flash.tween_property(player_panel, "modulate", Color(1.35, 1.35, 1.1), 0.15)
	flash.chain().tween_property(player_panel, "modulate", Color.WHITE, 0.3)

	player_level_label.pivot_offset = player_level_label.size / 2.0
	var pop: Tween = create_tween()
	pop.tween_property(player_level_label, "scale", Vector2(1.4, 1.4), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(player_level_label, "scale", Vector2.ONE, 0.2)


func _on_move_button_pressed(index: int) -> void:
	_set_bottom_state(BottomState.MESSAGE)
	battle_manager.player_use_move(index)


func _on_fight_pressed() -> void:
	_refresh_move_button_labels()
	_set_bottom_state(BottomState.MOVE_MENU)


func _on_move_back_pressed() -> void:
	_set_bottom_state(BottomState.MAIN_MENU)


func _on_bag_pressed() -> void:
	_refresh_bag_list()
	_set_bottom_state(BottomState.BAG_MENU)


func _on_bag_back_pressed() -> void:
	_set_bottom_state(BottomState.MAIN_MENU)


func _on_bag_item_pressed(item: ItemData) -> void:
	if item == null or bag == null:
		return

	if item.category == ItemData.Category.POKE_BALL:
		_set_bottom_state(BottomState.MESSAGE)
		bag.remove_item(item, 1) # dipakai walau gagal nangkap, sama seperti melempar bola beneran
		battle_manager.player_use_poke_ball(item)
		return

	_set_bottom_state(BottomState.MESSAGE)
	battle_manager.player_use_item(item, player_pokemon, bag)


func _on_pokemon_pressed() -> void:
	# Ganti sukarela dari menu utama (boleh batal via tombol Kembali).
	_refresh_party_list(false)
	_set_bottom_state(BottomState.PARTY_MENU)


func _on_party_back_pressed() -> void:
	_set_bottom_state(BottomState.MAIN_MENU)


func _on_party_member_pressed(index: int) -> void:
	_set_bottom_state(BottomState.MESSAGE)
	battle_manager.player_switch_to(index)


## Dipanggil BattleManager saat Pokemon player pingsan tapi masih ada
## cadangan yang hidup: WAJIB pilih pengganti (tanpa tombol batal).
func _on_request_player_switch(_forced: bool) -> void:
	_refresh_party_list(true)
	_set_bottom_state(BottomState.PARTY_MENU)


## Dipanggil BattleManager begitu Pokemon berhasil bertukar: sinkronkan
## player_pokemon lalu refresh seluruh sisi player (nama/level/HP/sprite/move).
func _on_pokemon_switched() -> void:
	if battle_manager != null:
		player_pokemon = battle_manager.player_mon.instance
	_setup_player_side()


func _on_run_pressed() -> void:
	_set_bottom_state(BottomState.MESSAGE)
	battle_manager.player_attempt_flee()


func _show_temp_message_then_menu(text: String) -> void:
	if _busy_with_temp_message:
		return
	_busy_with_temp_message = true
	_set_bottom_state(BottomState.MESSAGE)
	_set_message_text(text)
	await get_tree().create_timer(TEMP_MESSAGE_TIME).timeout
	_busy_with_temp_message = false
	_set_bottom_state(BottomState.MAIN_MENU)


func _set_message_text(text: String) -> void:
	message_label.text = text
	if _message_tween != null and _message_tween.is_valid():
		_message_tween.kill()
	message_label.modulate.a = 0.0
	_message_tween = create_tween()
	_message_tween.tween_property(message_label, "modulate:a", 1.0, 0.18)


func _on_message(text: String) -> void:
	_set_bottom_state(BottomState.MESSAGE)
	_set_message_text(text)


func _on_hp_updated(is_player: bool, current: int, max_hp: int) -> void:
	var bar: ProgressBar = player_hp_bar if is_player else enemy_hp_bar
	var label: Label = player_hp_number if is_player else enemy_hp_number
	var style: StyleBoxFlat = _player_hp_fill_style if is_player else _enemy_hp_fill_style
	var sprite: TextureRect = player_sprite if is_player else enemy_sprite

	var previous_value: float = bar.value
	bar.max_value = max_hp

	var update_step: Callable = func(v: float) -> void:
		bar.value = v
		label.text = "%d / %d" % [int(round(v)), max_hp]
		if style != null:
			style.bg_color = _hp_color_for_ratio(v / maxf(float(max_hp), 1.0))

	var tween: Tween = create_tween()
	tween.tween_method(update_step, previous_value, float(current), HP_TWEEN_TIME)

	if current < previous_value:
		_play_hit_animation(sprite)
	elif current > previous_value:
		_play_heal_animation(sprite)

	if current <= 0:
		await tween.finished
		_play_faint_animation(sprite)


func _on_request_player_move() -> void:
	main_menu_prompt.text = "Apa yang akan dilakukan\n%s?" % player_pokemon.get_display_name()
	_refresh_move_button_labels()
	_set_bottom_state(BottomState.MAIN_MENU)


func _on_move_used(is_player: bool) -> void:
	var sprite: TextureRect = player_sprite if is_player else enemy_sprite
	_play_attack_animation(sprite)


func _on_fled() -> void:
	_set_bottom_state(BottomState.MESSAGE)
	print("Battle selesai. Player kabur.")
	battle_ended.emit(false)


func _on_battle_ended(player_won: bool) -> void:
	_set_bottom_state(BottomState.MESSAGE)
	# EXP setelah menang sudah ditangani otomatis di BattleManager._grant_exp()
	# (dipanggil dari _end_battle() sebelum sinyal battle_ended ini dipancarkan).
	print("Battle selesai. Player menang: ", player_won)
	battle_ended.emit(player_won)


func _on_captured(instance: PokemonInstance) -> void:
	pokemon_captured.emit(instance)


## ---------------------------------------------------------------------
## ANIMASI
## ---------------------------------------------------------------------

func _play_entrance_animation() -> void:
	for sprite in [enemy_sprite, player_sprite]:
		sprite.pivot_offset = sprite.size / 2.0
		sprite.scale = Vector2(0.6, 0.6)
		sprite.modulate.a = 0.0

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(enemy_sprite, "modulate:a", 1.0, 0.35)
	tween.tween_property(enemy_sprite, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().set_parallel(true)
	tween.tween_property(player_sprite, "modulate:a", 1.0, 0.35)
	tween.tween_property(player_sprite, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _play_attack_animation(sprite: TextureRect) -> void:
	if not sprite.visible:
		return
	var direction: float = -1.0 if sprite == enemy_sprite else 1.0
	var base_pos: Vector2 = sprite.position
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "position", base_pos + Vector2(18 * direction, 0), 0.09)
	tween.tween_property(sprite, "position", base_pos, 0.12)


func _play_hit_animation(sprite: TextureRect) -> void:
	if not sprite.visible:
		return
	var original_modulate: Color = sprite.modulate
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(0.92, 0.92), 0.06)
	tween.parallel().tween_property(sprite, "modulate", Color(1.0, 0.45, 0.45), 0.06)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.12)
	tween.parallel().tween_property(sprite, "modulate", original_modulate, 0.12)


func _play_heal_animation(sprite: TextureRect) -> void:
	if not sprite.visible:
		return
	var original_modulate: Color = sprite.modulate
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(0.55, 1.0, 0.6), 0.12)
	tween.tween_property(sprite, "modulate", original_modulate, 0.2)


func _play_faint_animation(sprite: TextureRect) -> void:
	if not sprite.visible:
		return
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "position:y", sprite.position.y + 40, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.4)
