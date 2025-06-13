extends Page

@onready var novel_name: Label = %NovelName
@onready var chapter_num: Label = %ChapterNum
@onready var play: Button = %play
@onready var pause: Button = %pause
@onready var nextbutton: Button = %nextbutton
@onready var prevbutton: Button = %prevbutton
@onready var autoplay: Button = %autoplay
@onready var chapbody: VBoxContainer = %chapbody
@onready var readsettings: Control = %readsettings

var pos: int = 0
var chapter_list: Array = []
var voice_id
var tts_chunks: Array = []
var tts_index: int = 0
var auto:bool = false
var stopped_pressed:bool = false
var b_group
var skip_chapters = 0
var tts_model: BaseTTSModel

const AUDIO_LINES = preload("res://assets/svg/audio-lines.svg")
const AUDIO_WAVEFORM = preload("res://assets/svg/audio-waveform.svg")
const CIRCLE_PLAY = preload("res://assets/svg/circle-play.svg")
const CIRCLE_STOP = preload("res://assets/svg/circle-stop.svg")
const PLAY = preload("res://assets/svg/play.svg")
const STEP_BACK = preload("res://assets/svg/step-back.svg")
const PAUSE = preload("res://assets/svg/pause.svg")
const STEP_FORWARD = preload("res://assets/svg/step-forward.svg")
const X = preload("res://assets/svg/x.svg")
const READTHEME = preload("res://assets/themes/readtheme.tres")
# review code
# check if the _ready has been called

func _ready() -> void:
	super._ready()
	b_group = ButtonGroup.new()
	b_group.allow_unpress = true
	if Globals.selected_novel:
		novel_name.text = Globals.selected_novel
		chapter_list = Globals.novel_data.novels[Globals.selected_novel].chapters.keys()
		if OS.has_feature("android"):
			tts_model = AndriodTTSModel.new()
			tts_model.chap_path_list = Array(chapter_list.map(func(element): return "chapter_%s.txt"%element), TYPE_STRING, "", null)
			tts_model.chap_url = Globals.novel_data.novels[
				Globals.selected_novel].chapters.values()[0].split("/chapter_")[0]
		else:
			tts_model = DefualtTTSModel.new()
		tts_model.selected_chapter = Globals.selected_chapter
		tts_model.chapter_list = chapter_list
		tts_model.change_chapter.connect(_on_change_chapter)
		tts_model.verse_changed.connect(_on_verse_changed)
		tts_model.playing_changed.connect(_on_playbuttton_changed)
		add_child(tts_model)
		load_novel()
	tts_model.stop() # change this
	voice_id = Globals.voice_id

func load_novel():
	if Globals.selected_novel:
		chapter_num.text = "Chapter %s"%(Globals.selected_chapter)
		pos = chapter_list.find(Globals.selected_chapter)
		nextbutton.disabled = false if pos < chapter_list.size() - 1 else true
		prevbutton.disabled = false if pos > 0 else true
		Globals.novel_data.novels[Globals.selected_novel].current_chapter = Globals.selected_chapter
		Globals.save_info()
		var loaded_text:String = Globals.novel_data.load_chapter_text(Globals.novel_data.novels[Globals.selected_novel], Globals.selected_chapter)
		tts_chunks = TextFormater.format_text(loaded_text)
		tts_index = 0
		update_max(tts_chunks.size())

func update_max(new_max:int):
	var old_max:int = chapbody.get_child_count()
	if old_max > new_max:
		var to_remove = chapbody.get_children().slice(new_max, old_max)
		for node in to_remove:
			chapbody.remove_child(node)
			node.queue_free()
	elif old_max == new_max: pass
	else:
		for i in range(old_max, new_max):
			create_verses(i)
	for i in new_max:
		var button = chapbody.get_child(i) as Button
		button.text = tts_chunks[i]

func create_verses(num:int):
	var button = PassthroughButton.new()
	button.theme = READTHEME
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.button_group = b_group
	button.toggle_mode = true
	button.pressed.connect(func(): tts_index = num; _seek()) # use bind instead
	chapbody.add_child(button)

func _seek(): # can add a check for if playing
	tts_model.tts_index = tts_index
	tts_model.seek()

func remove_filler(text: String) -> String:
	text = text.replace("--", "")
	text = text.replace("__", "")
	#text = text.replace("__", "")
	return text

func _on_nextbutton_pressed() -> void:
	stopped_pressed = true
	next()

func next():
	tts_model.next()

func _on_change_chapter(new_chapter): # don't forget about +1 pos
	pos = max(min(new_chapter, chapter_list.size() - 1), 0)
	print("Chapter changed: ", pos)
	if pos < chapter_list.size() - 1:
		Globals.selected_chapter = chapter_list[pos]
		load_novel()

func _on_verse_changed(new_verse):
	update_verse(new_verse, true)

func _on_prevbutton_pressed() -> void:
	stopped_pressed = true
	tts_model.prev()

func _on_pause_pressed() -> void:
	tts_model._on_pause_pressed()
	if tts_model.is_playing:
		pause.icon = PAUSE
	else:
		pause.icon = STEP_FORWARD

func _on_play_toggled(toggled_on: bool) -> void:
	print(toggled_on, ": tooge in play button")
	tts_model._on_play_toggled(toggled_on)
	stopped_pressed = !toggled_on

func stop_audio(): # change to a ui thing
	play.icon = AUDIO_LINES
	pause.hide()
	update_verse(tts_index, false)

func play_audio(): # change to a ui thing
	play.icon = CIRCLE_STOP
	pause.show()
	pause.icon = PAUSE

func _on_playbuttton_changed(isplaying: bool) -> void:
	if isplaying:
		play_audio()
	else:
		stop_audio()

func update_verse(index:int, value:bool = false):
	if index < chapbody.get_child_count():
		var update_button = chapbody.get_child(index) as Button
		if update_button.button_pressed != value:
			update_button.button_pressed = value
			if value: update_button.grab_focus()

func _on_autoplay_toggled(toggled_on: bool) -> void:
	auto = toggled_on
	if toggled_on:
		autoplay.icon = X
	else:
		autoplay.icon = AUDIO_WAVEFORM

func on_prev_pressed():
	#tts_model.stop()
	super.on_prev_pressed()

func _on_settings_pressed() -> void:
	readsettings.show()
