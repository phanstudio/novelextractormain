extends Resource
class_name NovelSave

@export var novels: Dictionary[String, NovelData] = {} # novel path to the website -> NovelData
@export var settings: Dictionary[String, Variant] = {}

# if this breakes 
func save_chapter_text(novel_data: NovelData, chapter: int, content: String, filename: String) -> void:
	var folder_path = "user://novels/%s" % filename
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

func save_image(novel_data: NovelData, content: Image, filename: String) -> void:
	var folder_path = "user://novels/%s" % filename
	var dir = DirAccess.open("user://")
	if not dir.dir_exists(folder_path):
		dir.make_dir_recursive(folder_path)

	var file_path = "%s/cover.jpg" % [folder_path]
	var error = content.save_jpg(file_path)
	if error != OK:
		printerr("Failed! to save image")
		return
	novel_data.image_path = file_path

func load_image(novel_data: NovelData) -> ImageTexture:
	if novel_data.image_path.is_empty():
		return
	var img:Image = Image.load_from_file(novel_data.image_path)
	if !img:
		return 
	return ImageTexture.create_from_image(img)

func delete_info(filename:String):
	var folder_path = "user://novels/%s" % filename
	delete_directory(folder_path)

func delete_directory(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir:
		var files := dir.get_files()
		for file in files:
			var file_path := path.path_join(file)
			DirAccess.remove_absolute(file_path)
		
		var subdirs := dir.get_directories()
		for subdir in subdirs:
			delete_directory(path.path_join(subdir))  # Recursively delete subdirectories
		
		DirAccess.remove_absolute(path)  # Finally remove the empty directory
		print("Deleted:", path)
	else:
		print("Directory not found:", path)
