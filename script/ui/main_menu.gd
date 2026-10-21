extends Control

## Menu utama: "Petualangan Baru" dan "Lanjutkan" (cuma muncul kalau ada
## file save). Mulai baru padahal save ada -> minta konfirmasi dulu supaya
## data lama tidak ketimpa diam-diam.

const WORLD_SCENE := "res://scene/world.tscn"

@onready var new_button: Button = $VBox/NewButton
@onready var continue_button: Button = $VBox/ContinueButton
@onready var confirm_dialog: ConfirmationDialog = $ConfirmDialog
@onready var error_dialog: AcceptDialog = $ErrorDialog


func _ready() -> void:
	continue_button.visible = SaveSystem.has_save()
	new_button.pressed.connect(_on_new_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	confirm_dialog.confirmed.connect(_on_new_confirmed)


func _on_new_pressed() -> void:
	if SaveSystem.has_save():
		confirm_dialog.popup_centered()
	else:
		_start_new_game()


func _on_new_confirmed() -> void:
	SaveSystem.delete_save()
	_start_new_game()


func _start_new_game() -> void:
	get_tree().change_scene_to_file(WORLD_SCENE)


func _on_continue_pressed() -> void:
	if SaveSystem.load_game():
		get_tree().change_scene_to_file(WORLD_SCENE)
	else:
		error_dialog.dialog_text = "Save tidak bisa dimuat: %s" % SaveSystem.get_last_error()
		error_dialog.popup_centered()
