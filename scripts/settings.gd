extends Page

@onready var window_expand: OptionDropdown = %WindowExpand

func _ready() -> void:
	window_expand.set_selected(Globals.novel_data.settings.get_or_add("window_expand", 0), true)

func _on_window_expand_item_selected(index: int) -> void: # change later
	get_window().content_scale_factor = window_expand.get_text_from_index(index).to_float()
	Globals.novel_data.settings.set("window_expand", index)

func _on_button_pressed() -> void:
	Globals.save_info()
