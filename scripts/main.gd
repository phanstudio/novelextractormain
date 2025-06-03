extends Page

@onready var saved: HFlowContainer = %Saved

const NOVEL_CONTAINER = preload("res://scene/custom_components/novel_container.tscn")
const NOVEL = preload("res://scene/Novel.tscn")

var tween: Tween

func _ready():
	super._ready()
	_reload()

func _reload():
	for i in saved.get_children(): saved.remove_child(i)
	for i in Globals.novel_data.novels.keys():
		var novel_container:NovelContainer = NOVEL_CONTAINER.instantiate()
		saved.add_child(novel_container)
		novel_container.set_info(Globals.novel_data.novels[i].name)
		novel_container.get_image_from_url("", Globals.novel_data.load_image(Globals.novel_data.novels[i]))
		novel_container.pressed.connect(
			func(): 
				Globals.selected_novel = i
				self.on_next_pressed()
		)

func _on_tab_container_tab_changed(tab: int) -> void:
	if tab == 0:
		_reload()
