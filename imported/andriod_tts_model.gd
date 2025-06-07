extends BaseTTSModel
class_name AndriodTTSModel

var _plugin_name = "GodotAndroidPluginTemplate"
var media_notification_plugin
var play_pressed: bool = false
var current_title: String = ""
var current_chapter: String = ""
var chap_path_list:Array[String] = []
var chap_url: String = ""

func tts_load():
	setup_media_notification()

func setup_media_notification():
	if Engine.has_singleton(_plugin_name):
		media_notification_plugin = Engine.get_singleton(_plugin_name)
		print(media_notification_plugin)
		pos = chapter_list.find(selected_chapter)
		media_notification_plugin.setChapterQueue(
			chap_path_list, 
			chap_url,
			pos,
			chap_url+"/cover.jpg"
		)
		media_notification_plugin.media_button_pressed.connect(_on_media_button_pressed)
		media_notification_plugin.playback_state_changed.connect(_on_playback_state_changed)
		media_notification_plugin.reading_progress_updated.connect(_on_reading_progress_updated)
		media_notification_plugin.chapter_changed.connect(_on_change_chapter)
		update_media_notification()
	else:
		print("MediaStyle notification plugin not available")

func _on_reading_progress_updated(main_chapter: int, total_chapters: int, current_chunk: int, total_chunks: int, is_queue_mode: bool, chapter_title: String):
	if is_queue_mode:
		# Calculate overall progress across all chapters
		var chapter_progress = float(main_chapter) / float(total_chapters) if total_chapters > 0 else 0.0
		var chunk_progress = float(main_chapter) / float(total_chunks) if total_chunks > 0 else 0.0
		var current_chapter_contribution = chunk_progress / float(total_chapters) if total_chapters > 0 else 0.0
		var overall_progress = chapter_progress + current_chapter_contribution
		print("Reading progress: Chapter %d/%d, Chunk %d/%d (%.1f%%)" % [
			main_chapter + 1, total_chapters, 
			current_chunk + 1, total_chunks,
			overall_progress * 100.0
		])
		verse_changed.emit(current_chunk)
		
		# Check if reading is complete
		#if current_chapter == -1 and current_chunk == -1:
			#chapter_label.text = "Reading Complete

func update_media_notification():
	if media_notification_plugin:
		media_notification_plugin.setMediaMetadata(
			current_title,
			current_chapter,
			"TTS Novel Reader"
		)

func show_media_notification_if_playing():
	if play_pressed and media_notification_plugin:
		update_media_notification()

func _on_nextbutton_pressed() -> void:
	next()

func next():
	if pos < chapter_list.size() - 1:
		media_notification_plugin.stopTTSPlayback()
		selected_chapter = chapter_list[pos + 1]
		load_novel()

func _on_prevbutton_pressed() -> void:
	if pos > 0:
		media_notification_plugin.stopTTSPlayback()
		selected_chapter = chapter_list[pos - 1]
		load_novel()

func _on_pause_pressed() -> void:
	is_playing = !is_playing # add in update state
	if media_notification_plugin:
		media_notification_plugin.playPauseQueue()
		update_media_notification()

func _on_play_toggled(toggled_on: bool) -> void:
	play_pressed = toggled_on
	is_playing = toggled_on
	if media_notification_plugin:
		if toggled_on:
			media_notification_plugin.playChapterQueue()
			show_media_notification_if_playing()
		else:
			media_notification_plugin.stopQueue()
			media_notification_plugin.hideMediaNotification()

func seek():
	if media_notification_plugin:
		media_notification_plugin.seekToChunk(tts_index, true)

# === MEDIA NOTIFICATION HANDLERS ===

func _on_media_button_pressed(button_type: String):
	print("Media button pressed from notification: ", button_type)
	
	#match button_type:
		#"play_pause":
			#_on_play_toggled(!play_pressed)
			#
		#"previous":
			#_on_prevbutton_pressed()
			#
		#"next":
			#_on_nextbutton_pressed()

func _on_playback_state_changed(playing: bool):
	print(is_playing)
	is_playing = playing

func _on_change_chapter(chapterIndex: int, _chapterTitle: String, _totalChapters: int):
	change_chapter.emit(chapterIndex)
