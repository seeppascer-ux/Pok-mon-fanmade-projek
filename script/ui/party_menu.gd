class_name PartyMenu
extends Control

## Layar "PARTY" -- nampilin sampai 6 Pokemon di party pemain (icon, nama,
## gender, level, status condition, dan HP bar). Dibuka dari tombol PARTY
## di world.gd, seluruh isinya dibikin lewat kode (bukan hand-drawn di
## .tscn) supaya gampang di-refresh tiap kali dibuka.
##
## Selain view-only, tiap baris Pokemon bisa DIKLIK untuk membuka panel aksi
## evolusi:
##   - "Pakai Batu": me-list HANYA batu evolusi di Tas yang cocok buat
##     spesies itu (PokemonInstance.can_evolve_with_stone). Setelah
##     konfirmasi, evolusi dijalankan lewat Bag.use_stone_on() supaya jumlah
##     batu di Tas ikut berkurang hanya kalau evolusinya sukses.
##   - "Trade (Simulasi Tukar)": untuk Pokemon dengan
##     can_evolve_by_trade() (misal Kadabra) -- konfirmasi lalu
##     PokemonInstance.evolve_by_trade().
## Setelah evolusi, tampilan party di-refresh (nama/sprite/level ikut berubah).
##
## Cara pakai dari luar (lihat world.gd):
##   var menu := PARTY_MENU_SCENE.instantiate()
##   canvas_layer.add_child(menu)
##   menu.open(player_party, bag)
##   menu.closed.connect(func(): menu.queue_free())

signal closed

var party: Array[PokemonInstance] = []
## Tas milik pemain (dibutuhkan untuk aksi "Pakai Batu"). Boleh null --
## kalau null, aksi batu disembunyikan tapi menu tetap bisa dibuka.
var bag: Bag = null

## Overlay panel aksi evolusi untuk Pokemon yang sedang dipilih. Dibangun
## ulang setiap kali dibuka/di-refresh, terpisah dari list utama supaya
## rebuild list tidak merusak alur dialog konfirmasi.
var _action_layer: Control = null
var _selected: PokemonInstance = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	mouse_filter = Control.MOUSE_FILTER_STOP


## Dipanggil dari luar tiap kali menu ini mau ditampilkan. Bisa dipanggil
## berkali-kali (misal buka-tutup-buka lagi) -- selalu di-refresh dari data
## party yang terbaru (HP/status/level saat ini).
func open(party_data: Array[PokemonInstance], bag_data: Bag = null) -> void:
	party = party_data
	bag = bag_data
	_selected = null
	_build_ui()
	show()


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()
	_action_layer = null

	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.09, 0.94)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "PARTY"
	title.position = Vector2(24, 14)
	title.add_theme_font_size_override("font_size", 28)
	add_child(title)

	var hint := Label.new()
	hint.text = "Klik seekor Pokemon untuk aksi evolusi."
	hint.position = Vector2(150, 24)
	hint.add_theme_font_size_override("font_size", 14)
	hint.modulate = Color(0.75, 0.75, 0.8)
	add_child(hint)

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
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

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

	# Penanda kecil kalau Pokemon ini punya aksi evolusi yang tersedia.
	if _has_any_evolution_action(mon):
		var evo_label := Label.new()
		evo_label.text = "   [Evolusi!]"
		evo_label.modulate = Color(0.55, 1.0, 0.55)
		name_row.add_child(evo_label)

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

	# Tombol tak-terlihat di lapisan paling atas baris: menangkap klik di
	# mana pun pada baris (Label/TextureRect/ProgressBar di bawahnya tetap
	# STOP secara default dan akan menelan klik kalau tanpa ini). Flat +
	# tanpa teks sehingga tak terlihat, tapi memberi highlight halus saat
	# hover sebagai penanda baris bisa diklik.
	var click := Button.new()
	click.flat = true
	click.text = ""
	click.focus_mode = Control.FOCUS_NONE
	click.set_anchors_preset(Control.PRESET_FULL_RECT)
	click.pressed.connect(_on_row_selected.bind(mon))
	panel.add_child(click)

	return panel


## ---------------------------------------------------------------------
## Panel aksi evolusi (overlay)
## ---------------------------------------------------------------------

func _on_row_selected(mon: PokemonInstance) -> void:
	_show_actions(mon)


## True kalau mon punya setidaknya satu aksi evolusi yang BISA dipakai
## sekarang (batu cocok tersedia di Tas, atau bisa trade).
func _has_any_evolution_action(mon: PokemonInstance) -> bool:
	if mon == null or mon.species == null:
		return false
	if not _compatible_stones(mon).is_empty():
		return true
	return mon.can_evolve_by_trade()


## Daftar slot Tas berisi batu evolusi yang COCOK untuk mon (kategori
## EVO_STONE, jumlah > 0, dan species-nya berevolusi dengan batu itu).
## Dipakai baik untuk membangun UI maupun untuk tes headless.
func _compatible_stones(mon: PokemonInstance) -> Array:
	var result: Array = []
	if bag == null or mon == null:
		return result
	for slot in bag.slots:
		if slot == null or slot.item == null:
			continue
		if slot.quantity <= 0:
			continue
		if slot.item.category != ItemData.Category.EVO_STONE:
			continue
		if mon.can_evolve_with_stone(slot.item.evolution_stone_id):
			result.append(slot)
	return result


## Tampilkan panel aksi evolusi untuk mon yang dipilih (overlay di atas list).
func _show_actions(mon: PokemonInstance) -> void:
	if mon == null:
		return
	_selected = mon
	if _action_layer != null and is_instance_valid(_action_layer):
		_action_layer.queue_free()
	_action_layer = null

	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(layer)
	_action_layer = layer

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)

	var sheet := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.13, 0.18, 0.98)
	style.set_corner_radius_all(14)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	sheet.add_theme_stylebox_override("panel", style)
	# Strip bawah selebar layar: selalu terlihat utuh tanpa risiko terpotong,
	# berapa pun jumlah tombol batu di dalamnya.
	sheet.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	sheet.offset_left = 24
	sheet.offset_right = -24
	sheet.offset_top = -460
	sheet.offset_bottom = -16
	layer.add_child(sheet)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	sheet.add_child(vbox)

	var title := Label.new()
	title.text = "%s   Lv.%d" % [mon.get_display_name(), mon.level]
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	# --- Aksi: Pakai Batu ---
	var stone_header := Label.new()
	stone_header.text = "Pakai Batu Evolusi"
	stone_header.add_theme_font_size_override("font_size", 17)
	vbox.add_child(stone_header)

	var stones: Array = _compatible_stones(mon)
	if stones.is_empty():
		var no_stone := Label.new()
		if bag == null:
			no_stone.text = "(Tas tidak tersedia.)"
		else:
			no_stone.text = "(Tidak ada batu evolusi yang cocok di Tas.)"
		no_stone.modulate = Color(0.7, 0.7, 0.75)
		vbox.add_child(no_stone)
	else:
		for slot in stones:
			var stone_item: ItemData = slot.item
			var stone_btn := Button.new()
			stone_btn.text = "%s   (x%d)" % [stone_item.item_name, slot.quantity]
			stone_btn.custom_minimum_size = Vector2(0, 44)
			stone_btn.pressed.connect(_ask_use_stone.bind(mon, stone_item))
			vbox.add_child(stone_btn)

	# --- Aksi: Trade (simulasi) ---
	var trade_header := Label.new()
	trade_header.text = "Trade"
	trade_header.add_theme_font_size_override("font_size", 17)
	vbox.add_child(trade_header)

	if mon.can_evolve_by_trade():
		var trade_btn := Button.new()
		trade_btn.text = "Trade (Simulasi Tukar)"
		trade_btn.custom_minimum_size = Vector2(0, 44)
		trade_btn.pressed.connect(_ask_trade.bind(mon))
		vbox.add_child(trade_btn)
	else:
		var no_trade := Label.new()
		no_trade.text = "(Pokemon ini tidak berevolusi lewat trade.)"
		no_trade.modulate = Color(0.7, 0.7, 0.75)
		vbox.add_child(no_trade)

	var back_btn := Button.new()
	back_btn.text = "Kembali"
	back_btn.custom_minimum_size = Vector2(0, 44)
	back_btn.pressed.connect(_hide_actions)
	vbox.add_child(back_btn)


func _hide_actions() -> void:
	_selected = null
	if _action_layer != null and is_instance_valid(_action_layer):
		_action_layer.queue_free()
	_action_layer = null


## ---------------------------------------------------------------------
## Konfirmasi + eksekusi evolusi
## ---------------------------------------------------------------------

## Tanya konfirmasi sebelum memakai batu; setelah OK jalankan
## _do_use_stone(). Dipisah supaya skrip tes headless bisa memanggil
## _do_use_stone() langsung tanpa mensimulasikan klik dialog.
func _ask_use_stone(mon: PokemonInstance, stone: ItemData) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = "Pakai \"%s\" ke %s?\nPokemon akan berevolusi." % [stone.item_name, mon.get_display_name()]
	dialog.title = "Konfirmasi"
	dialog.get_ok_button().text = "Ya"
	dialog.get_cancel_button().text = "Batal"
	add_child(dialog)
	dialog.confirmed.connect(_do_use_stone.bind(mon, stone))
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()


## Eksekusi pemakaian batu lewat Bag.use_stone_on() (batu berkurang HANYA
## kalau evolusinya sukses), tampilkan hasilnya, lalu refresh tampilan.
func _do_use_stone(mon: PokemonInstance, stone: ItemData) -> void:
	if bag == null or mon == null or stone == null:
		_show_message("Tidak terjadi apa-apa...")
		return
	var messages: Array[String] = bag.use_stone_on(stone, mon)
	_refresh_after_evolution()
	if messages.is_empty():
		_show_message("Tidak terjadi apa-apa...")
	else:
		_show_message("\n".join(messages))


func _ask_trade(mon: PokemonInstance) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = "Simulasikan trade untuk %s?\n%s akan berevolusi setelah ditukar." % [mon.get_display_name(), mon.get_display_name()]
	dialog.title = "Konfirmasi Trade"
	dialog.get_ok_button().text = "Ya"
	dialog.get_cancel_button().text = "Batal"
	add_child(dialog)
	dialog.confirmed.connect(_do_trade.bind(mon))
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()


## Eksekusi evolusi trade; jalur ini tidak memakai Tas.
func _do_trade(mon: PokemonInstance) -> void:
	if mon == null:
		_show_message("Tidak terjadi apa-apa...")
		return
	var messages: Array[String] = mon.evolve_by_trade()
	_refresh_after_evolution()
	if messages.is_empty():
		_show_message("Tidak terjadi apa-apa...")
	else:
		_show_message("\n".join(messages))


## Rebuild list party + panel aksi (kalau sedang terbuka) supaya nama,
## sprite, level, dan jumlah batu yang tampil selalu yang terbaru.
func _refresh_after_evolution() -> void:
	_build_ui()
	var still_selected: PokemonInstance = _selected
	_selected = null
	if still_selected != null:
		_show_actions(still_selected)


func _show_message(text: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.dialog_text = text
	dialog.title = "Hasil"
	dialog.get_ok_button().text = "OK"
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.popup_centered()
