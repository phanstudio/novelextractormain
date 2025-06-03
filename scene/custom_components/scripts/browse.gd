extends Page

@onready var novel_holder: HFlowContainer = %novel_holder
@onready var http_request: HTTPRequest = $HTTPRequest
@onready var loading_bar: Control = %loading_bar
@onready var control: Control = %Control
@onready var http_request_2: HTTPRequest = %HTTPRequest2

var current_request: request = request.Browse
enum request{
	Browse,
	Info
}
var novel_texture: Image

const NOVEL_CONTAINER = preload("res://scene/custom_components/novel_container.tscn")

func _ready() -> void:
	current_request = request.Browse
	send_post_request("Fantasy")
	http_request.request_completed.connect(_on_HTTPRequest_request_completed)
	http_request_2.request_completed.connect(_on_HTTPRequest_request_completed) # add a complete
	for i in novel_holder.get_children():
		novel_holder.remove_child(i)

func send_post_request(genre:String):
	var url = "https://novelextractor.vercel.app/browse"
	var json_data = {
		"genre": genre,
	}

	var headers = ["Content-Type: application/json"]
	var jsonbody = JSON.stringify(json_data)

	var err = http_request.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		jsonbody
	)
	if err != OK:
		push_error("HTTP request failed to start: %s" % err)

func _on_HTTPRequest_request_completed(_result, response_code, _headers, jsonbody):
	match current_request:
		request.Browse:
			process_browse_request(response_code, jsonbody)
		request.Info:
			process_novel_info_request(response_code, jsonbody)

func process_browse_request(response_code, jsonbody):
	if response_code == 200:
		var json = JSON.parse_string(jsonbody.get_string_from_utf8())
		var count = 0
		for i in json["novels"]:
			var novel_container:NovelContainer = NOVEL_CONTAINER.instantiate()
			novel_holder.add_child(novel_container)
			novel_container.set_info(i["name"])
			novel_container.get_image_from_url(i["cover"])
			if count == 0:
				count += 1
				novel_container.image_loaded.connect(func(): loading_bar.hide(); novel_holder.show())
			novel_container.pressed.connect(_open_novel.bind(i, novel_container.image))
	else:
		print("show reload button and error screen")

func process_novel_info_request(response_code, jsonbody):
	if response_code == 200:
		var json = JSON.parse_string(jsonbody.get_string_from_utf8())
		var info = json["novel"]
		control.show()
		control.generate_content(
			info["title"], info["last_chapter"].to_int()+1, info["summary"]
		)
		#info["author"]
		#info["genres"]
		#info["last_chapter"]
		#info["status"]
	else:
		var json = JSON.parse_string(jsonbody.get_string_from_utf8())
		print(json)
		print("show reload button and error screen")

func _open_novel(info, img):
	current_request = request.Info
	var url = "https://novelextractor.vercel.app/novel_info"
	var json_data = {
		"path": info["path"],
	}
	novel_texture = img
	var headers = ["Content-Type: application/json"]
	var jsonbody = JSON.stringify(json_data)

	var err = http_request.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		jsonbody
	)
	if err != OK:
		push_error("HTTP request failed to start: %s" % err)
	control.show() # or loading view
	control.generate_content(info["name"], 10)
	var texture = ImageTexture.create_from_image(novel_texture)
	control.set_cover(texture)

func _on_close_pressed() -> void:
	control.hide()
