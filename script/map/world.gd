extends Node2D

## Script ini yang jadi "jembatan" antara jalan-jalan di peta dan battle
## system. Tempel di node root "world" (sudah otomatis kalau kamu extract
## project ini apa adanya).
##
## Cara kerja:
## 1. Setiap kali Player selesai berpindah 1 kotak (signal "moved" dari
##    player.gd), world.gd cek apakah player sedang berdiri di dalam salah
##    satu TallGrassZone.
## 2. Kalau iya, roll peluang encounter zona itu. Kalau kena, ambil 1
##    Pokemon liar acak dari tabel zona itu dan mulai battle.
## 3. Selama battle, kontrol jalan player dimatikan. Begitu battle selesai,
##    battle_ui dihapus dan kontrol player dikembalikan.

## Party pemain. Isi minimal 1 di Inspector (drag file .tres dari
## res://data/party/, misalnya starter_charmander.tres).
@export var player_party: Array[PokemonInstance] = []
## Party maksimal 6 ekor (persis game asli) -- Pokemon yang ditangkap pas
## party sudah penuh otomatis masuk ke "pc_box" di bawah, bukan hilang.
const PARTY_MAX_SIZE: int = 6

## Tas item player, dipakai lewat menu Tas pas battle (Poke Ball, Potion,
## dst). Kosongkan atau drag res://data/starter_bag.tres buat contoh isi
## awal -- kalau dikosongkan, otomatis dibikin Tas kosong di _ready().
@export var bag: Bag
## Penyimpanan Pokemon di luar party. Belum ada UI buat lihat isinya,
## baru sistem datanya (lihat data/pc_box.gd).
@export var pc_box: PCBox

## Data Pokedex player (spesies mana yang pernah dilihat/ditangkap).
## Dikosongkan = otomatis dibikin baru & kosong di _ready(). Diisi
## otomatis oleh world.gd tiap ada encounter liar (mark_seen) atau
## penangkapan berhasil (mark_caught) -- lihat data/pokedex.gd.
@export var pokedex: Pokedex

## ID map aktif, disimpan di file save. Sekarang cuma ada 1 map ("world") --
## begitu ada map baru, pindah map WAJIB lewat notify_map_changed() supaya
## auto-save ikut jalan.
const MAP_ID := "world"

const BATTLE_UI_SCENE: PackedScene = preload("res://scene/battle_ui.tscn")
const PARTY_MENU_SCENE: PackedScene = preload("res://scene/party_menu.tscn")
const POKEDEX_UI_SCENE: PackedScene = preload("res://scene/pokedex_ui.tscn")

@onready var player: CharacterBody2D = $Player
@onready var canvas_layer: CanvasLayer = $CanvasLayer

var _battle_active: bool = false
## Total detik bermain run ini. Di-reset tiap run baru, dimuat dari save
## kalau "Lanjutkan", dan ikut tersimpan di file save.
var _playtime: float = 0.0


func _process(delta: float) -> void:
	_playtime += delta


func _ready() -> void:
	if bag == null:
		bag = Bag.new()
	if pc_box == null:
		pc_box = PCBox.new()
	if pokedex == null:
		pokedex = Pokedex.new()

	# Kalau menu utama tadi memilih "Lanjutkan", SaveSystem sudah memegang
	# data hasil load -- pakai itu dan lewati inisialisasi run baru.
	var loaded := SaveSystem.take_pending_load()
	if not loaded.is_empty():
		_apply_save(loaded)
	else:
		# Pokemon yang sudah dipunya dari awal (starter, dst) otomatis dianggap
		# "sudah ditangkap" di Pokedex, tanpa perlu ketemu liar dulu.
		for mon in player_party:
			if mon.species != null:
				pokedex.mark_caught(mon.species)

	if player.has_signal("moved"):
		player.moved.connect(_on_player_moved)
	else:
		push_warning("player.gd belum punya signal 'moved' -- encounter tidak akan jalan.")

	_setup_menu_buttons()


## Tombol "PARTY" dan "DEX" on-screen, ditaruh di CanvasLayer yang sama
## dengan tombol arah U/D/L/R -- otomatis ikut disembunyikan/dimunculkan
## oleh _set_movement_buttons_visible() karena sama-sama BaseButton.
func _setup_menu_buttons() -> void:
	var party_button := Button.new()
	party_button.text = "PARTY"
	party_button.custom_minimum_size = Vector2(90, 50)
	party_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	party_button.position = Vector2(-200, 12)
	party_button.pressed.connect(_open_party_menu)
	canvas_layer.add_child(party_button)

	var dex_button := Button.new()
	dex_button.text = "DEX"
	dex_button.custom_minimum_size = Vector2(90, 50)
	dex_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	dex_button.position = Vector2(-100, 12)
	dex_button.pressed.connect(_open_pokedex)
	canvas_layer.add_child(dex_button)


func _open_party_menu() -> void:
	if _battle_active:
		return
	var menu: Control = PARTY_MENU_SCENE.instantiate()
	canvas_layer.add_child(menu)
	menu.open(player_party)
	_set_movement_buttons_visible(false)
	menu.closed.connect(func() -> void:
		menu.queue_free()
		_set_movement_buttons_visible(true)
	)


func _open_pokedex() -> void:
	if _battle_active:
		return
	var dex_ui: Control = POKEDEX_UI_SCENE.instantiate()
	canvas_layer.add_child(dex_ui)
	dex_ui.open(pokedex)
	_set_movement_buttons_visible(false)
	dex_ui.closed.connect(func() -> void:
		dex_ui.queue_free()
		_set_movement_buttons_visible(true)
	)


func _on_player_moved() -> void:
	if _battle_active:
		return

	for zone in get_tree().get_nodes_in_group("tall_grass"):
		if zone.player_inside and zone.roll_encounter():
			_start_wild_encounter(zone.pick_wild_pokemon())
			return


func _start_wild_encounter(wild_instance: PokemonInstance) -> void:
	if player_party.is_empty():
		push_warning("player_party kosong! Isi dulu lewat Inspector pada node 'world'.")
		return

	pokedex.mark_seen(wild_instance.species)

	_battle_active = true
	player.input_direction = Vector2.ZERO
	player.set_physics_process(false)
	_set_movement_buttons_visible(false)

	var battle_scene: BattleUI = BATTLE_UI_SCENE.instantiate()
	# PENTING: battle_scene harus masuk ke CanvasLayer, BUKAN langsung ke
	# node "world". Kalau ditaruh langsung di "world" (Node2D), Control
	# full-rect-nya ikut kena transform Camera2D milik Player (posisi &
	# zoom kamera), jadi battle_ui muncul geser/kepotong alih-alih
	# menutupi layar dengan bersih -- kelihatan kayak encounter "tidak
	# pisah" ke battle scene.
	canvas_layer.add_child(battle_scene)
	battle_scene.battle_ended.connect(_on_battle_ended.bind(battle_scene))
	battle_scene.pokemon_captured.connect(_on_pokemon_captured)
	battle_scene.start(_first_alive_party_member(), wild_instance, bag)


func _first_alive_party_member() -> PokemonInstance:
	for mon in player_party:
		mon.setup_default()
		if not mon.is_fainted():
			return mon
	return player_party[0]


func _on_battle_ended(_player_won: bool, battle_scene: Node) -> void:
	battle_scene.queue_free()
	_battle_active = false
	player.set_physics_process(true)
	_set_movement_buttons_visible(true)
	_autosave_now()


## Dipanggil begitu battle_ui.gd memancarkan "pokemon_captured" (Poke Ball
## berhasil). Masuk ke party kalau masih ada slot kosong (maks
## PARTY_MAX_SIZE), kalau party sudah penuh otomatis dikirim ke pc_box.
func _on_pokemon_captured(instance: PokemonInstance) -> void:
	pokedex.mark_caught(instance.species)
	if player_party.size() < PARTY_MAX_SIZE:
		player_party.append(instance)
	else:
		pc_box.deposit(instance)
	_autosave_now()


## Auto-save ke user://savegame.json. Dipanggil otomatis tiap battle
## selesai, tiap menangkap Pokemon, dan tiap pindah map.
func _autosave_now() -> void:
	if player_party.is_empty():
		return
	if not SaveSystem.autosave(player_party, bag, pokedex, pc_box, MAP_ID,
			player.position, _playtime):
		push_warning("Auto-save gagal: %s" % SaveSystem.get_last_error())


## Terapkan data hasil SaveSystem.load_game() (dipanggil dari _ready saat
## "Lanjutkan"). Mercy rule: kalau semua Pokemon party pingsan (misal save
## tepat setelah kalah battle), sembuhkan semua biar tidak soft-lock.
func _apply_save(data: Dictionary) -> void:
	player_party.clear()
	var party: Array = data.get("party", [])
	for mon in party:
		player_party.append(mon)
	bag = data.get("bag", bag)
	pokedex = data.get("pokedex", pokedex)
	pc_box = data.get("pc_box", pc_box)
	_playtime = float(data.get("playtime", 0.0))
	player.position = data.get("player_pos", player.position)
	var all_fainted := true
	for mon in player_party:
		if not mon.is_fainted():
			all_fainted = false
			break
	if all_fainted:
		for mon in player_party:
			mon.heal_full()


## Hook PINDAH MAP (dipakai begitu ada map kedua, dst). Panggil fungsi ini
## -- JANGAN set posisi manual -- supaya map & posisi tercatat dan
## auto-save otomatis jalan sebelum transisi.
func notify_map_changed(map_id: String, spawn_pos: Vector2) -> void:
	player.position = spawn_pos
	if not SaveSystem.notify_map_changed(map_id, spawn_pos, player_party,
			bag, pokedex, pc_box, _playtime):
		push_warning("Auto-save pindah map gagal: %s" % SaveSystem.get_last_error())


## Sembunyikan/tampilkan tombol arah on-screen (U/D/L/R) yang ada di
## CanvasLayer, supaya tidak numpuk sama tombol move pas battle aktif.
func _set_movement_buttons_visible(is_visible: bool) -> void:
	for child in canvas_layer.get_children():
		if child is BaseButton:
			child.visible = is_visible
