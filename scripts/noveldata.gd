extends Resource
class_name NovelData

@export var name: String
@export var max_chapter_num: int = 0
@export var chapters: Dictionary[int, String] = {} # chapter number -> file path
@export var current_chapter: int = 0
