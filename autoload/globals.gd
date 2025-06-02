extends Node
const save_path: String = "user://save.tres"
var novel_data: NovelSave
var selected_novel: String
var selected_chapter: int
var max_chapters: int
var voice_id

func _ready() -> void:
	var voices = DisplayServer.tts_get_voices_for_language("en")
	voice_id = voices[0]

func _enter_tree() -> void:
	novel_data = load_novel_save(save_path)
	#novel_data = NovelSave.new()

func save_info() -> void:
	save_novel_save(novel_data, save_path)

func save_novel_save(save: NovelSave, path := "user://novelsave.tres"):
	var err = ResourceSaver.save(save, path)
	if err != OK:
		push_error("Failed to save novel data: %s" % err)

func load_novel_save(path := "user://novelsave.tres") -> NovelSave:
	var loaded: NovelSave
	if ResourceLoader.exists(path, "NovelSave"):
		loaded = ResourceLoader.load(path, "NovelSave") as NovelSave
	else:
		loaded = NovelSave.new()
	return loaded

func _exit_tree() -> void:
	save_info()
