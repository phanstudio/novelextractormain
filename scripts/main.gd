extends Page

@onready var downloadcontainer: VBoxContainer = %downloadcontainer
@onready var downloadmore: Button = %downloadmore
@onready var novel_name: TextEdit = %NovelName
@onready var novel_num: TextEdit = %NovelNum
@onready var alert: Label = %alert
@onready var saved: VBoxContainer = %Saved
const NOVEL = preload("res://scene/Novel.tscn")
var tween: Tween

func _ready():
	super._ready()
	for i in saved.get_children(): saved.remove_child(i)
	for i in Globals.novel_data.novels.keys():
		create_novel(i, Globals.novel_data.novels[i].max_chapter_num)

func create_novel(key, value): # create custom button later
	var button = Button.new()
	button.custom_minimum_size.y = 40
	button.text = ("%s (%s)"%[key, value]).capitalize().replace("-", " ")
	#button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.pressed.connect(
		func(): 
			Globals.selected_novel = key
			self.on_next_pressed()
	)
	saved.add_child(button)

func _on_downloadmore_toggled(toggled_on: bool) -> void:
	if toggled_on:
		downloadcontainer.show()
		downloadmore.text = "Close Download"
	else:
		downloadcontainer.hide()
		downloadmore.text = "Download More"

func _on_download_pressed() -> void:
	var error:Array = []
	var nnum:int = novel_num.text.to_int()
	var nname:String = novel_name.text.replace(" ", "_")
	if nname.length() <= 3: error.append("'Name' too small at least 4 letters")
	if nnum <= 0: error.append("'Number' too small at least 1")
	if error.size() > 0:
		alert.show()
		alert.text = "Error: "+", ".join(error)
		if tween:
			tween.kill()
		tween = create_tween()
		tween.tween_property(alert, "modulate:a", 1, 0.2)
		tween.tween_property(alert, "modulate:a", 0, 0.2).set_delay(2)
		tween.tween_callback(func()->void: alert.text = ""; alert.hide())
		return
	var novel: NovelData
	if nname not in Globals.novel_data.novels.keys():
		create_novel(nname, nnum)
		novel = NovelData.new()
		novel.name = nname
		novel.max_chapter_num = nnum
	else:
		var button = saved.get_child(Globals.novel_data.Novels.keys().find(nname)) as Button
		button.text = "%s (%s)"%[nname, nnum]
		novel = Globals.novel_data.novels[nname]
		novel.max_chapter_num = nnum
	Globals.novel_data.novels[nname] = novel
	Globals.save_info()
