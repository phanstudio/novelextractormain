extends BaseTTSModel
class_name DefualtTTSModel

var play_pressed: bool = false

func tts_load():
	voice_id = DisplayServer.tts_get_voices_for_language("en")[0]
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, _stopped)
	load_novel()

func load_novel():# can be modularized
	pos = chapter_list.find(selected_chapter)
	var loaded_text: String = Globals.novel_data.load_chapter_text(Globals.novel_data.novels[Globals.selected_novel], selected_chapter)
	tts_chunks = TextFormater.format_text(loaded_text) # return as an array of sentences for the tts engine
	tts_index = 0

func _on_nextbutton_pressed() -> void:
	DisplayServer.tts_stop()
	next()

func next():
	if pos < chapter_list.size() - 1:
		selected_chapter = chapter_list[pos +1]
		load_novel()

func _on_prevbutton_pressed() -> void:
	if pos > 0:
		DisplayServer.tts_stop()
		selected_chapter = chapter_list[pos -1]
		load_novel()

func _on_pause_pressed() -> void:
	is_playing = !DisplayServer.tts_is_paused()
	if !is_playing:
		DisplayServer.tts_resume()
	else:
		DisplayServer.tts_pause()

func _on_play_toggled(toggled_on: bool) -> void:
	if toggled_on:
		tts_index = 0
		play_audio()
	else:
		DisplayServer.tts_stop()
	play_pressed = toggled_on

func play_audio():
	_speak_next_chunk()

func _stopped(_v):
	if play_pressed and tts_index < tts_chunks.size():
		_speak_next_chunk()
	else:
		_on_play_toggled(false)

func _speak_next_chunk():
	if tts_index < tts_chunks.size():
		DisplayServer.tts_speak(tts_chunks[tts_index], voice_id, 50, 1.0, 1.5)
		tts_index += 1
