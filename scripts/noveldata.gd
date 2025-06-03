extends Resource
class_name NovelData

@export var name: String
@export var max_chapter_num: int = 0
@export var chapters: Dictionary[int, String] = {} # chapter number -> file path
@export var current_chapter: int = 0
@export var desc: String =  ""
@export var image_path: String = ""
@export var author: String = ""
@export var genres: Array[String] = [] # can become genre enum
@export var status: String = "" # can become Status enum
# add from where later # website
