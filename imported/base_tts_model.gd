extends Node
class_name BaseTTSModel

var pos: int = 0
var chapter_list: Array = []
var voice_id
var tts_chunks: Array = []
var tts_index: int = 0
var selected_chapter = 1
var chapters: Array[String]
var is_playing: bool

signal change_chapter(current_chapter: int)
signal verse_changed(current_verse: int)

func _ready() -> void:
	tts_load()

func tts_load():
	pass

func load_novel():
	pass

func _on_nextbutton_pressed() -> void:
	pass

func next():
	pass

func seek():
	pass

func _on_prevbutton_pressed() -> void:
	pass

func _on_pause_pressed() -> void:
	pass

func _on_play_toggled(_toggled_on: bool) -> void:
	pass

func play_audio():
	pass

func _stopped(_v):
	pass
