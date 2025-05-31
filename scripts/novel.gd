extends Page

@onready var http_request: HTTPRequest = %HTTPRequest
@onready var novel_name: Label = %NovelName
@onready var max_chapters: TextEdit = %max_chapters
@onready var from: TextEdit = %from
@onready var to: TextEdit = %to
@onready var body: VBoxContainer = %body
@onready var chapters: Label = %chapters
@onready var update: HBoxContainer = %update
@onready var chapterdownload: HBoxContainer = %chapterdownload
@onready var downloadtoggle: Button = %downloadtoggle
@onready var updatetoggle: Button = %updatetoggle
@onready var currently_reading: Label = %currently_reading

var download_queue: Array[int] = []
var download_list: Array = []
const close: Texture = preload("res://assets/svg/x.svg")
const CIRCLE_ELLIPSIS = preload("res://assets/svg/circle-ellipsis.svg")
const ARROW_DOWN_TO_LINE = preload("res://assets/svg/arrow-down-to-line.svg")
# Downloads
const DOWNLOAD = preload("res://assets/svg/download.svg")
const CHECK_LINE = preload("res://assets/svg/check-line.svg")
const CHECK = preload("res://assets/svg/check.svg")
const CHECK_CHECK = preload("res://assets/svg/check-check.svg")

func _ready():
	super._ready()
	Globals.novel_data.novels.get_or_add(Globals.selected_novel, NovelData.new())
	if Globals.selected_novel:
		novel_name.text = Globals.selected_novel
		chapters.text = "Chapters(%s)"% Globals.novel_data.novels[Globals.selected_novel].max_chapter_num
	http_request.request_completed.connect(_on_HTTPRequest_request_completed)
	for i in body.get_children(): body.remove_child(i)
	download_list = Globals.novel_data.novels[Globals.selected_novel].chapters.keys()
	for i in Globals.novel_data.novels[Globals.selected_novel].max_chapter_num:
		create_chapters(i)
	if Globals.novel_data.novels[Globals.selected_novel].current_chapter != 0:
		currently_reading.text = "currently reading Chapter %s"%(
			Globals.novel_data.novels[Globals.selected_novel].current_chapter)

func create_chapters(key):
	var button = Button.new()
	button.custom_minimum_size.y = 40
	button.text = "Chapter %s"%[key+1]
	button.icon = DOWNLOAD if key+1 not in download_list else CHECK_LINE
	button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(func(): Globals.selected_chapter = key+1; self.on_next_pressed())
	button.disabled = key+1 not in download_list
	body.add_child(button)

func update_chapters(index, disabled:bool = true):
	if index+1 not in download_list: # can be better
		var button = body.get_child(index) as Button
		button.disabled = disabled
		button.icon = DOWNLOAD if !disabled else CHECK_LINE
		Globals.save_info()

func update_max(new_max: int):
	var count:int = 0
	var old_max:int = body.get_child_count()
	if old_max > new_max:
		for i in body.get_children():
			if count >= new_max:
				body.remove_child(i)
			count += 1
	elif old_max == new_max: return
	else:
		for i in range(old_max, new_max):
			create_chapters(i)
	chapters.text = "Chapters(%s)"% new_max

func send_post_request(novel:String, num:int):
	var url = "https://novelextractor.vercel.app/extract_text"
	var json_data = {
		"novel": novel,
		"num": str(num)
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
	if response_code == 200:
		var json = JSON.parse_string(jsonbody.get_string_from_utf8())
		if json and "text" in json:
			var result_text = json["text"]
			var num = download_queue.pop_front()
			Globals.novel_data.novels[Globals.selected_novel].chapters[num] = result_text
			update_chapters(num-1, false)
			if !download_queue.is_empty():
				send_post_request(Globals.selected_novel, download_queue[0])
		else:
			push_error("Missing 'text' field in response.")
	else:
		push_error("HTTP Error %s" % response_code)

func _on_updatebutton_pressed() -> void:
	var new_max: int = max_chapters.text.to_int()
	if new_max > 0:
		Globals.novel_data.novels[Globals.selected_novel].max_chapter_num = new_max
		update_max(new_max)
		Globals.save_info()

func _on_download_pressed() -> void:
	var new_min: int = max(from.text.to_int(), 1)
	var new_max: int = min(max(to.text.to_int(), new_min+1), chapters.text.to_int())
	from.text = str(new_min)
	to.text = str(new_max)
	for i in range(new_min, new_max+1):
		if i not in download_queue:
			download_queue.append(i) 
			# add queues of a general que a processing linked to the various http requests
	send_post_request(Globals.selected_novel, download_queue[0])

func _on_play_pressed() -> void:
	if Globals.selected_novel and Globals.novel_data.novels[Globals.selected_novel].current_chapter != 0:
		Globals.selected_chapter = Globals.novel_data.novels[Globals.selected_novel].current_chapter
		self.on_next_pressed()

func _on_downloadtoggle_toggled(toggled_on: bool) -> void:
	chapterdownload.visible = toggled_on
	if toggled_on:
		downloadtoggle.icon = close
	else:
		downloadtoggle.icon = ARROW_DOWN_TO_LINE

func _on_updatetoggle_toggled(toggled_on: bool) -> void:
	update.visible = toggled_on
	if toggled_on:
		updatetoggle.icon = close
	else:
		updatetoggle.icon = CIRCLE_ELLIPSIS
