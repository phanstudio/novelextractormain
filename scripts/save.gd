extends Resource
class_name NovelSave

@export var novels: Dictionary[String, NovelData] = {} # novel name -> NovelData

func save_chapter_text(novel_data: NovelData, chapter: int, content: String) -> void:
	var folder_path = "user://novels/%s" % novel_data.name
	var dir = DirAccess.open("user://")
	if not dir.dir_exists(folder_path):
		dir.make_dir_recursive(folder_path)

	var file_path = "%s/chapter_%d.txt" % [folder_path, chapter]
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()
		novel_data.chapters[chapter] = file_path
	else:
		push_error("Failed to write chapter %d of %s" % [chapter, novel_data.name])

func load_chapter_text(novel_data: NovelData, chapter: int) -> String:
	if not novel_data.chapters.has(chapter):
		return ""

	var file_path = novel_data.chapters[chapter]
	if not FileAccess.file_exists(file_path):
		push_error("Chapter file missing: %s" % file_path)
		return ""

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		return content
	return ""
