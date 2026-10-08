class_name PartyMenu
extends Control

## Layar "PARTY" -- nampilin sampai 6 Pokemon di party pemain (icon, nama,
## gender, level, status condition, dan HP bar). Dibuka dari tombol PARTY
## di world.gd, seluruh isinya dibikin lewat kode (bukan hand-drawn di
## .tscn) supaya gampang di-refresh tiap kali dibuka.
##
## Cara pakai dari luar (lihat world.gd):
##   var menu := PARTY_MENU_SCENE.instantiate()
##   canvas_layer.add_child(menu)
##   menu.open(player_party)
##   menu.closed.connect(func(): menu.queue_free())

signal closed

var party: Array[PokemonInstance] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	mouse_filter = Control.MOUSE_FILTER_STOP


## Dipanggil dari luar tiap kali menu ini mau ditampilkan. Bisa dipanggil
## berkali-kali (misal buka-tutup-buka lagi) -- selalu di-refresh dari data
## party yang terbaru (HP/status/level saat ini).
func open(party_data: Array[PokemonInstance]) -> void:
	party = party_data
	_build_ui()
	show()


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.09, 0.94)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "PARTY"
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

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 70
	scroll.offset_left = 24
	scroll.offset_right = -24
	scroll.offset_bottom = -16
	add_child(scroll)

	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(360, 0)
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	if party.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Belum ada Pokemon di party."
		list.add_child(empty_label)
		return

	for mon in party:
		mon.setup_default()
		list.add_child(_build_row(mon))


func _on_close_pressed() -> void:
	closed.emit()
	hide()


func _build_row(mon: PokemonInstance) -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.16, 0.22, 0.95)
	style.set_corner_radius_all(10)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	if mon.is_fainted():
		panel.modulate = Color(1, 1, 1, 0.55)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)

	var icon_rect := TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(48, 48)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if mon.species != null:
		icon_rect.texture = mon.species.icon
	row.add_child(icon_rect)

	var info := VBoxContainer.new()
	info.custom_minimum_size = Vector2(280, 0)
	row.add_child(info)

	var name_row := HBoxContainer.new()
	info.add_child(name_row)

	var gender_symbol := ""
	if mon.gender == PokemonInstance.Gender.MALE:
		gender_symbol = " \u2642"
	elif mon.gender == PokemonInstance.Gender.FEMALE:
		gender_symbol = " \u2640"

	var name_label := Label.new()
	name_label.text = "%s%s" % [mon.get_display_name(), gender_symbol]
	name_label.add_theme_font_size_override("font_size", 18)
	name_row.add_child(name_label)

	var level_label := Label.new()
	level_label.text = "   Lv.%d" % mon.level
	name_row.add_child(level_label)

	if not mon.is_healthy():
		var status_label := Label.new()
		status_label.text = "   [%s]" % mon.get_status_name()
		status_label.modulate = Color(1, 0.55, 0.4)
		name_row.add_child(status_label)
	elif mon.is_fainted():
		var faint_label := Label.new()
		faint_label.text = "   [Pingsan]"
		faint_label.modulate = Color(0.8, 0.6, 0.6)
		name_row.add_child(faint_label)

	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 8)
	info.add_child(hp_row)

	var hp_bar := ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(180, 14)
	hp_bar.max_value = maxi(mon.max_hp(), 1)
	hp_bar.value = maxi(mon.current_hp, 0)
	hp_bar.show_percentage = false
	var hp_ratio := float(maxi(mon.current_hp, 0)) / float(maxi(mon.max_hp(), 1))
	var bar_style := StyleBoxFlat.new()
	if hp_ratio > 0.5:
		bar_style.bg_color = Color8(24, 192, 32)
	elif hp_ratio > 0.2:
		bar_style.bg_color = Color8(248, 176, 0)
	else:
		bar_style.bg_color = Color8(248, 88, 40)
	bar_style.set_corner_radius_all(4)
	hp_bar.add_theme_stylebox_override("fill", bar_style)
	hp_row.add_child(hp_bar)

	var hp_label := Label.new()
	hp_label.text = "%d/%d HP" % [maxi(mon.current_hp, 0), mon.max_hp()]
	hp_row.add_child(hp_label)

	return panel
