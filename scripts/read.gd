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

func _ready() -> void:
	super._ready()
	b_group = ButtonGroup.new()
	b_group.allow_unpress = true
	if Globals.selected_novel:
		novel_name.text = Globals.selected_novel
		chapter_list = Globals.novel_data.novels[Globals.selected_novel].chapters.keys()
		load_novel()
	voice_id = Globals.voice_id
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, _stopped)

func load_novel():
	if Globals.selected_novel:
		chapter_num.text = "Chapter %s"%(Globals.selected_chapter)
		pos = chapter_list.find(chapter_num.text.to_int())
		nextbutton.disabled = false if pos < chapter_list.size() - 1 else true
		prevbutton.disabled = false if pos > 0 else true
		Globals.novel_data.novels[Globals.selected_novel].current_chapter = Globals.selected_chapter
		Globals.save_info()
		var loaded_text:String = Globals.novel_data.load_chapter_text(Globals.novel_data.novels[Globals.selected_novel], Globals.selected_chapter)
		tts_chunks = split_text(remove_filler(loaded_text))
		tts_index = 0
		update_max(tts_chunks.size())
		if auto:
			play.toggled.emit(true)
			play.set_pressed_no_signal(true)

func update_max(new_max:int):
	var old_max:int = chapbody.get_child_count()
	if old_max > new_max:
		var count:int = 0
		for i in chapbody.get_children().slice(new_max, old_max):
			if count >= new_max:
				chapbody.remove_child(i)
			count += 1
	elif old_max == new_max: pass
	else:
		for i in range(old_max, new_max):
			create_verses(i)
	for i in new_max:
		var button = chapbody.get_child(i) as Button
		button.text = tts_chunks[i]

func create_verses(num:int):
	var button = Button.new()
	button.theme = READTHEME
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.button_group = b_group
	button.toggle_mode = true
	button.pressed.connect(func(): tts_index = num; _seek()) # use bind instead
	chapbody.add_child(button)

func _seek(): # can add a check for if playing
	DisplayServer.tts_stop()
	play_audio()
	play.set_pressed_no_signal(true)

func remove_filler(text: String) -> String:
	text = text.replace("--", "")
	text = text.replace("__", "")
	#text = text.replace("__", "")
	return text

func _on_nextbutton_pressed() -> void:
	stopped_pressed = true
	DisplayServer.tts_stop()
	update_verse(tts_index, false)
	next()

func next():
	if pos < chapter_list.size() - 1:
		Globals.selected_chapter = chapter_list[pos +1]
		load_novel()

func _on_prevbutton_pressed() -> void:
	if pos > 0:
		DisplayServer.tts_stop()
		Globals.selected_chapter = chapter_list[pos -1]
		load_novel()

func _on_pause_pressed() -> void:
	if DisplayServer.tts_is_paused():
		DisplayServer.tts_resume()
		pause.icon = PAUSE
	else:
		DisplayServer.tts_pause()
		pause.icon = STEP_FORWARD

func _on_play_toggled(toggled_on: bool) -> void:
	if toggled_on:
		stopped_pressed = false
		tts_index = 0
		play_audio()
	else:
		stopped_pressed = true
		play.icon = AUDIO_LINES
		pause.hide()
		update_verse(tts_index, false)
		DisplayServer.tts_stop()

func play_audio():
	_speak_next_chunk()
	play.icon = CIRCLE_STOP
	pause.show()
	pause.icon = PAUSE

func _stopped(_v):
	if play.button_pressed and tts_index < (tts_chunks.size() + skip_chapters):
		_speak_next_chunk()
	else:
		play.set_pressed_no_signal(false)
		update_verse(tts_index, false)
		if auto and !stopped_pressed:
			next()
		else:
			play.toggled.emit(false)
		stopped_pressed = false

func _speak_next_chunk():
	if tts_index < tts_chunks.size():
		update_verse(tts_index, true)
		DisplayServer.tts_speak(tts_chunks[tts_index], voice_id, 50, 1.0, 1.5)
		tts_index += 1

func update_verse(index:int, value:bool = false):
	if index < chapbody.get_child_count():
		var update_button = chapbody.get_child(index) as Button
		update_button.button_pressed = value
		#update_button.set_pressed_no_signal(value)
		update_button.grab_focus()

func split_text(text: String, max_length: int = 300) -> Array:
	var regex := RegEx.new()
	regex.compile("[.!?]\\s+")
	var matches := regex.search_all(text)

	var chunks: Array = []
	var start := 0

	for match in matches:
		var end := match.get_end()
		var sentence := text.substr(start, end - start)
		start = end

		sentence = sentence.strip_edges()
		if chunks.size() > 0 and (chunks[-1].length() + sentence.length()) < max_length:
			chunks[-1] += " " + sentence
		else:
			chunks.append(sentence)

	# Add any remaining text after last punctuation
	if start < text.length():
		var last_part := text.substr(start, text.length() - start).strip_edges()
		if last_part != "":
			if chunks.size() > 0 and (chunks[-1].length() + last_part.length()) < max_length:
				chunks[-1] += " " + last_part
			else:
				chunks.append(last_part)
	return chunks

func _on_autoplay_toggled(toggled_on: bool) -> void:
	auto = toggled_on
	if toggled_on:
		autoplay.icon = X
	else:
		autoplay.icon = AUDIO_WAVEFORM

func on_prev_pressed():
	DisplayServer.tts_stop()
	super.on_prev_pressed()

func _on_settings_pressed() -> void:
	readsettings.show()
