extends Page

@onready var novel_holder: HFlowContainer = %novel_holder
@onready var loading_bar: Control = %loading_bar
@onready var control: Control = %Control
@onready var novel_loading: Control = %NovelLoading
@onready var search_request: HTTPRequest = %searchRequest
@onready var search: TextEdit = %search
@onready var alert: Label = %alert
@onready var novel_request: HTTPRequest = %NovelRequest
@onready var browse_request: HTTPRequest = $BrowseRequest
@onready var clear_button: Button = %clearButton
@onready var error_page: VBoxContainer = %error_page
@onready var error_label: Label = %error
@onready var error_alert: Control = $errorAlert

var novel_texture: Image
var browesed_list:Array = []
var searching:bool = false
var tween: Tween
var error_tween: Tween

const NOVEL_CONTAINER = preload("res://scene/custom_components/novel_container.tscn")

func _ready() -> void:
	send_post_request("Fantasy")
	browse_request.request_completed.connect(process_browse_request)
	novel_request.request_completed.connect(process_novel_info_request)
	search_request.request_completed.connect(process_search_request)
	for i in novel_holder.get_children():
		novel_holder.remove_child(i)

func send_post_request(genre:String):
	var url = "https://novelextractor.vercel.app/browse"
	var json_data = {
		"genre": genre,
	}

	var headers = ["Content-Type: application/json"]
	var jsonbody = JSON.stringify(json_data)

	var err = browse_request.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		jsonbody
	)
	if err != OK:
		push_error("HTTP request failed to start: %s" % err)

func process_search_request(_result, response_code, _headers, jsonbody):
	var search_error: String = ""
	if response_code == 200:
		var json = JSON.parse_string(jsonbody.get_string_from_utf8())
		for i in novel_holder.get_children():
			novel_holder.remove_child(i)
		var count:int = json["count"]
		if count > 1 and json["results"][0]["name"] != null:
			load_item(json["results"])
			return
		else:
			search_error = "zero result for '%s' keyword"% json["query"]
	loading_bar.hide()
	novel_holder.hide()
	if search_error:
		show_error(search_error)
	else:
		show_error()

func process_browse_request(_result, response_code, _headers, jsonbody):
	if response_code == 200:
		var json = JSON.parse_string(jsonbody.get_string_from_utf8())
		browesed_list = json["novels"] # add advanced stuff like updating and pages later, also categories
		if !searching:
			_load_browsed_content()
			return
	#else:
		#print("show reload button and error screen")
	loading_bar.hide()
	novel_holder.hide()
	show_error("No Network")

func process_novel_info_request(_result, response_code, _headers, jsonbody):
	if response_code == 200:
		var json = JSON.parse_string(jsonbody.get_string_from_utf8())
		var info = json["novel"]
		control.generate_content(
			control.current_novel, info["title"], info["last_chapter"].to_int()+1, info["summary"]
		)
		control.set_author_and_status(info["author"], info["status"])
		control._set_novel_properties({
			"max_chapter_num": info["last_chapter"].to_int()+1,
			"desc": info["summary"],
			"genres": info["genres"],
			"status": info["status"],
			"author": info["author"],
		})
		novel_loading.hide()
		control.show() # or loading view
		return
	
	novel_loading.hide()
	control.hide()
	play_alert()

func _load_browsed_content(clear:bool= true):
	if clear:
		for i in novel_holder.get_children():
			novel_holder.remove_child(i)
	load_item(browesed_list)

func load_item(list:Array):
	var count = 0
	for i in list:
		if !i["name"]: continue
		var novel_container:NovelContainer = NOVEL_CONTAINER.instantiate()
		novel_holder.add_child(novel_container)
		novel_container.set_info(i["name"])
		novel_container.get_image_from_url(i["cover"])
		if count == 0:
			count += 1
			novel_container.image_loaded.connect(func(): error_page.hide(); loading_bar.hide(); novel_holder.show())
		novel_container.pressed.connect(_open_novel.bind(i, novel_container.image))

func _open_novel(info, img):
	control.current_novel = info["path"].replace("novel/", "")
	control.check_lib()
	novel_loading.show()
	if !Globals.novel_data.novels.has(control.current_novel):
		var url = "https://novelextractor.vercel.app/novel_info"
		var json_data = {
			"path": info["path"],
		}
		novel_texture = img
		var headers = ["Content-Type: application/json"]
		var jsonbody = JSON.stringify(json_data)

		var err = novel_request.request(
			url,
			headers,
			HTTPClient.METHOD_POST,
			jsonbody
		)
		if err != OK:
			push_error("HTTP request failed to start: %s" % err)
		control.generate_content(control.current_novel, info["name"], 10)
		var texture = ImageTexture.create_from_image(novel_texture)
		control.set_cover(texture)
		control._set_novel_properties({
			"name": info["name"],
		})
	else: # load and store approriately
		control.genrate_from_novel_url(control.current_novel)
		novel_texture = img
		novel_texture = control.novel_cover.texture.get_image()
		novel_loading.hide()
		control.show() # or loading view

func _on_close_pressed() -> void:
	control.current_novel = ""
	control.hide()
	control.check_lib()

func _on_save_button_pressed() -> void: # we need to delete the image at this point when we are remove the save
	if !Globals.novel_data.novels.has(control.current_novel):
		Globals.novel_data.save_image(
			control.novel_data,
			novel_texture,
			control.current_novel
		)
	control.interact_with_lib()

func _on_tab_container_tab_changed(tab: int) -> void:
	if tab != 1: # should we load it when we are here
		control.current_novel = ""

func show_error(value:String= "Something went wrong"):
	error_label.text = value
	error_page.show()

func _on_clear_pressed() -> void:
	if searching:
		searching = false
		_load_browsed_content()
	search.text = ""
	clear_button.hide()
	error_page.hide()

func _on_searchbutton_pressed() -> void:
	var error:Array = []
	var nname:String = search.text
	if nname.length() <= 3: error.append("'Search' too small at least 4 letters")
	if error.size() > 0:
		alert.modulate.a = 0
		alert.show()
		alert.text = "Error: "+", ".join(error)
		if tween:
			tween.kill()
		tween = create_tween()
		tween.tween_property(alert, "modulate:a", 1, 0.2)
		tween.tween_property(alert, "modulate:a", 0, 0.2).set_delay(2)
		tween.tween_callback(func()->void: alert.text = ""; alert.hide())
		return
	searching = true
	var url = "https://novelextractor.vercel.app/search"
	var json_data = {
		"query": search.text,
	}
	var headers = ["Content-Type: application/json"]
	var jsonbody = JSON.stringify(json_data)

	var err = search_request.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		jsonbody
	)
	if err != OK:
		push_error("HTTP request failed to start: %s" % err)
	novel_holder.hide()
	loading_bar.show()

func _on_search_text_changed() -> void:
	if "\n" in search.text:
		search.text = search.text.replace("\n", "")
		_on_searchbutton_pressed()
		search.set_caret_column(search.text.length())
		
	if search.text.length() > 0:
		clear_button.show()
	else:
		clear_button.hide()

func _on_reload_button_2_pressed() -> void:
	if searching:
		searching = false
	search.text = ""
	clear_button.hide()
	novel_holder.hide()
	loading_bar.show()
	error_page.hide()
	send_post_request("Fantasy")

func play_alert():
	if error_tween:
		error_tween.kill()
	error_alert.modulate.a = 0
	error_alert.show()
	error_tween = create_tween()
	error_tween.tween_property(error_alert, "modulate:a", 1, 0.2)
	error_tween.tween_property(error_alert, "modulate:a", 0, 0.2).set_delay(2)
	error_tween.tween_callback(func()->void: error_alert.hide())
