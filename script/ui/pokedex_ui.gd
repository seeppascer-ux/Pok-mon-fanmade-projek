class_name PokedexUI
extends Control

## Layar Pokedex -- daftar semua spesies (diambil OTOMATIS dari semua file
## .tres di res://data/species/, tidak perlu didaftar manual satu-satu) +
## panel detail buat spesies yang lagi dipilih.
##
## Aturan tampilan (persis konsep Pokedex game asli):
## - Belum pernah dilihat sama sekali -> nama "???", tidak ada data lain.
## - Pernah dilihat (ketemu liar) tapi belum ditangkap -> nama & tipe
##   kelihatan, tapi deskripsi & base stat masih disembunyikan.
## - Pernah ditangkap -> semua data kelihatan.
##
## Cara pakai dari luar (lihat world.gd):
##   var dex := POKEDEX_UI_SCENE.instantiate()
##   canvas_layer.add_child(dex)
##   dex.open(pokedex)
##   dex.closed.connect(func(): dex.queue_free())

signal closed

const SPECIES_DIR := "res://data/species/"

var pokedex: Pokedex
var _all_species: Array[PokemonSpecies] = []
var _detail_panel: PanelContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	mouse_filter = Control.MOUSE_FILTER_STOP


func open(pokedex_data: Pokedex) -> void:
	pokedex = pokedex_data
	_load_all_species()
	_build_ui()
	show()


## Scan folder data/species/ dan load tiap file .tres sebagai PokemonSpecies.
## Otomatis -- kalau kamu nambah spesies baru lewat New Resource di
## Inspector, dia bakal muncul sendiri di Pokedex tanpa perlu edit kode.
func _load_all_species() -> void:
	_all_species.clear()
	var dir := DirAccess.open(SPECIES_DIR)
	if dir == null:
		push_warning("PokedexUI: tidak bisa membuka folder %s" % SPECIES_DIR)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res := load(SPECIES_DIR + file_name)
			if res is PokemonSpecies:
				_all_species.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()

	_all_species.sort_custom(func(a: PokemonSpecies, b: PokemonSpecies) -> bool:
		return a.species_id < b.species_id
	)


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.09, 0.96)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "POKEDEX"
	title.position = Vector2(24, 14)
	title.add_theme_font_size_override("font_size", 28)
	add_child(title)

	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(48, 44)
	close_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close_btn.position = Vector2(-64, 12)
	close_btn.pressed.connect(_on_close_pressed)
	add_child(close_btn)

	var seen_count := 0
	var caught_count := 0
	if pokedex != null:
		seen_count = pokedex.seen_ids.size()
		caught_count = pokedex.caught_ids.size()
	var progress_label := Label.new()
	progress_label.text = "Dilihat: %d / %d   Ditangkap: %d / %d" % [
		seen_count, _all_species.size(), caught_count, _all_species.size()
	]
	progress_label.position = Vector2(24, 54)
	add_child(progress_label)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 90
	scroll.offset_left = 24
	scroll.offset_right = -400
	scroll.offset_bottom = -16
	add_child(scroll)

	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(320, 0)
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)

	_detail_panel = PanelContainer.new()
	_detail_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_detail_panel.offset_top = 90
	_detail_panel.offset_left = -370
	_detail_panel.offset_right = -24
	_detail_panel.offset_bottom = -16
	var detail_style := StyleBoxFlat.new()
	detail_style.bg_color = Color(0.16, 0.16, 0.22, 0.96)
	detail_style.set_corner_radius_all(10)
	detail_style.content_margin_left = 18
	detail_style.content_margin_right = 18
	detail_style.content_margin_top = 16
	detail_style.content_margin_bottom = 16
	_detail_panel.add_theme_stylebox_override("panel", detail_style)
	add_child(_detail_panel)

	if _all_species.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Tidak ada data spesies (folder data/species/ kosong?)."
		list.add_child(empty_label)
		return

	for species in _all_species:
		list.add_child(_build_list_entry(species))

	_show_detail(_all_species[0])


func _on_close_pressed() -> void:
	closed.emit()
	hide()


func _build_list_entry(species: PokemonSpecies) -> Button:
	var seen := pokedex != null and pokedex.is_seen(species.species_id)
	var caught := pokedex != null and pokedex.is_caught(species.species_id)

	var btn := Button.new()
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 36)
	var number_text := "#%03d" % species.species_id
	if not seen:
		btn.text = "%s   ???" % number_text
	else:
		var mark := "  \u25CF" if caught else ""
		btn.text = "%s   %s%s" % [number_text, species.species_name, mark]
	btn.pressed.connect(_show_detail.bind(species))
	return btn


func _show_detail(species: PokemonSpecies) -> void:
	for child in _detail_panel.get_children():
		child.queue_free()

	var seen := pokedex != null and pokedex.is_seen(species.species_id)
	var caught := pokedex != null and pokedex.is_caught(species.species_id)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_detail_panel.add_child(box)

	var icon_rect := TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(96, 96)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if seen:
		icon_rect.texture = species.icon
	box.add_child(icon_rect)

	var name_label := Label.new()
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.text = "#%03d  %s" % [species.species_id, species.species_name if seen else "???"]
	box.add_child(name_label)

	if not seen:
		var hint := Label.new()
		hint.text = "Belum pernah ditemui."
		hint.modulate = Color(0.8, 0.8, 0.8)
		box.add_child(hint)
		return

	var type_label := Label.new()
	var type_text := Types.type_name(species.type1)
	if species.type2 != Types.Type.NONE:
		type_text += " / %s" % Types.type_name(species.type2)
	type_label.text = "Tipe: %s" % type_text
	box.add_child(type_label)

	if not caught:
		var hint := Label.new()
		hint.text = "\nBelum pernah ditangkap -- deskripsi dan\nbase stat belum terbuka."
		hint.modulate = Color(0.8, 0.8, 0.8)
		box.add_child(hint)
		return

	if species.pokedex_description != "":
		var desc_label := Label.new()
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_label.text = species.pokedex_description
		box.add_child(desc_label)

	var stats_title := Label.new()
	stats_title.text = "\nBase Stats"
	stats_title.add_theme_font_size_override("font_size", 16)
	box.add_child(stats_title)

	var stats: Array = [
		["HP", species.base_hp],
		["Attack", species.base_attack],
		["Defense", species.base_defense],
		["Sp.Atk", species.base_sp_attack],
		["Sp.Def", species.base_sp_defense],
		["Speed", species.base_speed],
	]
	for stat_pair in stats:
		var stat_label := Label.new()
		stat_label.text = "%s: %d" % [stat_pair[0], stat_pair[1]]
		box.add_child(stat_label)
