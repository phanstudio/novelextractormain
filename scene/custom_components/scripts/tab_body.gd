@tool
extends HBoxContainer
class_name TabBody

@export var tab_container: TabContainer
var current_tab:int = 0
# add custom scene here

func _ready() -> void:
	var count = 0
	var b_group = ButtonGroup.new()
	for i in tab_container.get_children():
		var tab:Button = Button.new() # change this to a custom scene # create a custom pressed
		tab.name = i.name
		tab.text = i.name
		tab.toggle_mode = true
		tab.button_group = b_group
		tab.focus_mode = Control.FOCUS_NONE
		tab.pressed.connect(set_current_tab.bind(count))
		add_child(tab)
		if count == current_tab:
			tab.button_pressed = true
		count += 1

func set_current_tab(index:int):
	tab_container.current_tab = index
	current_tab = index
