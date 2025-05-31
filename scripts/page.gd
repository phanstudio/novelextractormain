extends Control
class_name Page

@export_file("*.tscn") var next_page: String
@export_file("*.tscn") var prev_page: String

@export var next_button: Button
@export var prev_button: Button

func _ready() -> void:
	if next_button:
		next_button.pressed.connect(on_next_pressed)
	if prev_button:
		prev_button.pressed.connect(on_prev_pressed)

func on_next_pressed():
	get_tree().change_scene_to_file(next_page)

func on_prev_pressed():
	get_tree().change_scene_to_file(prev_page)
