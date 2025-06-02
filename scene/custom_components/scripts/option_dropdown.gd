extends HBoxContainer
class_name OptionDropdown

@onready var label: Label = %Label
@onready var option_button: OptionButton = %OptionButton
var currently_selected: int = 0

signal item_selected(index:int)

func set_selected(index:int, init:bool= false) -> void:
	if !init and index == currently_selected: return
	option_button.select(index)
	emit_item_selected(index)

func _ready() -> void:
	option_button.item_selected.connect(emit_item_selected)

func emit_item_selected(index:int) -> void:
	deselect_previous(index)
	item_selected.emit(index)
	option_button.set_item_disabled(index, true)

func deselect_previous(index:int) -> void:
	option_button.set_item_disabled(currently_selected, false)
	currently_selected = index

func get_text_from_index(index:int) -> String:
	return option_button.get_item_text(index)

func get_selected() -> int:
	return option_button.selected
