extends Page

@onready var novel_holder: HFlowContainer = %novel_holder
@onready var search_request: HTTPRequest = %searchRequest
@onready var search: TextEdit = %search
@onready var alert: Label = %alert
@onready var clear_button: Button = %clearButton
@onready var error_page: VBoxContainer = %error_page
@onready var error_label: Label = %error
@onready var error_alert: Control = $errorAlert
@onready var update_request: HTTPRequest = %UpdateRequest

var novel_texture: Image
var browesed_list:Array = []
var searching:bool = false
var tween: Tween
var error_tween: Tween

const NOVEL_CONTAINER = preload("res://scene/custom_components/novel_container.tscn")
# create a go to library feature

func _ready() -> void:
	update_request.request_completed.connect(process_browse_request)
	for i in novel_holder.get_children():
		novel_holder.remove_child(i)
	#print(Time.get_date_string_from_unix_time(Time.get_unix_time_from_system()))
	#var elapsed_minutes = elapsed_seconds / 60
	#var elapsed_hours = elapsed_seconds / 3600
	#var elapsed_days = elapsed_seconds / 86400
	#var elapsed_weeks = elapsed_seconds / (86400 * 7)

func send_post_request(path:String):
	var url = "https://novelextractor.vercel.app/update"
	var json_data = {
		"path": path,
	}

	var headers = ["Content-Type: application/json"]
	var jsonbody = JSON.stringify(json_data)

	var err = update_request.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		jsonbody
	)
	if err != OK:
		push_error("HTTP request failed to start: %s" % err)

func process_browse_request(_result, response_code, _headers, jsonbody):
	if response_code == 200:
		var json = JSON.parse_string(jsonbody.get_string_from_utf8())
		browesed_list = json["last_update"] # add advanced stuff like updating and pages later, also categories
		#if !searching:
			#_load_browsed_content()
			#return
	novel_holder.hide()
	show_error("No Network")

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
			#novel_container.image_loaded.connect(func(): error_page.hide(); loading_bar.hide(); novel_holder.show())
		#novel_container.pressed.connect(_open_novel.bind(i, novel_container.image))

func _on_tab_container_tab_changed(tab: int) -> void:
	if tab != 1: # should we load it when we are here
		pass

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
