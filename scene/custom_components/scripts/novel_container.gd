extends Control
class_name NovelContainer

@onready var texture_rect: TextureRect = %TextureRect
@onready var label: Label = %Label
@onready var http_request: HTTPRequest = %HTTPRequest
@onready var novel_container: Button = %NovelContainer

var image = Image.new()

signal image_loaded
signal pressed

func _ready() -> void:
	http_request.request_completed.connect(_on_http_request_request_completed)
	novel_container.pressed.connect(func()->void: pressed.emit())

func set_info(label_text: String):
	label.text = label_text

func get_image_from_url(url:String, image_object:ImageTexture=null):
	if !url.is_empty():
		http_request.request(url)
	if image_object:
		texture_rect.texture = image_object
		image_loaded.emit()

func _on_http_request_request_completed(result, _response_code, _headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		print("Failed to fetch image:", result)
		return
	 # Use load_jpg_from_buffer for JPG check for png of jpg
	var err = image.load_jpg_from_buffer(body) 

	if err != OK:
		print("Error loading image from buffer:", err)
		return

	var texture = ImageTexture.create_from_image(image)
	texture_rect.texture = texture
	image_loaded.emit()
