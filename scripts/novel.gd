extends Page

@onready var http_request: HTTPRequest = %HTTPRequest
@onready var novel_name: Label = %NovelName
@onready var from: TextEdit = %from
@onready var to: TextEdit = %to
@onready var body: VBoxContainer = %body
@onready var chapters: Label = %chapters
@onready var updatetoggle: Button = %updatetoggle
@onready var currently_reading: Button = %currently_reading
@onready var filterbutton: MenuButton = %filterbutton
@onready var expand_button: Button = %ExpandButton
@onready var novel_desc: Label = %NovelDesc
@onready var novel_cover: TextureRect = %NovelCover
@onready var novel_author: Label = %NovelAuthor
@onready var novel_status: Label = %NovelStatus
@onready var save_button: Button = %saveButton
@onready var novel_data: NovelData= NovelData.new()
@onready var downloadbutton: MenuButton = %downloadbutton
@onready var customdownloadpopuup: PopupPanel = %customdownloadpopuup

@export var not_main:bool = false

var download_queue: Array[int] = []
var download_list: Array = []
var current_novel: String
var request_handeled: bool = false

const close: Texture = preload("res://assets/svg/x.svg")
const CIRCLE_ELLIPSIS = preload("res://assets/svg/circle-ellipsis.svg")
const ARROW_DOWN_TO_LINE = preload("res://assets/svg/arrow-down-to-line.svg")
# Downloads
const DOWNLOAD = preload("res://assets/svg/download.svg")
const CHECK_LINE = preload("res://assets/svg/check-line.svg")
const CHECK = preload("res://assets/svg/check.svg")
const CHECK_CHECK = preload("res://assets/svg/check-check.svg")
const CHEVRON_UP = preload("res://assets/svg/chevron-up.svg")
const CHEVRON_DOWN = preload("res://assets/svg/chevron-down.svg")
const CIRCLE_CHECK_BIG = preload("res://assets/svg/circle-check-big.svg")
const BOOK_OPEN = preload("res://assets/svg/book-open.svg")

func _ready():
	super._ready()
	http_request.request_completed.connect(_on_HTTPRequest_request_completed)
	current_novel = Globals.selected_novel
	if Globals.novel_data.novels.has(current_novel):
		genrate_from_novel_url(current_novel)
		save_button.icon = CIRCLE_CHECK_BIG
		novel_data = Globals.novel_data.novels[current_novel]
	if !not_main:
		save_button.pressed.connect(interact_with_lib)
	filterbutton.get_popup().index_pressed.connect(_update_filter)
	downloadbutton.get_popup().index_pressed.connect(_download_chapters)

## put things like name, url, cover and so on
func _set_novel_properties(propeties:Dictionary):
	for i in propeties.keys():
		novel_data.set(i, propeties[i])

func generate_content(nov_path:String, nov_name:String, chap_num:int, nov_desc:String =""):
	for i in body.get_children(): body.remove_child(i)
	if novel_name:
		novel_name.text = nov_name
		chapters.text = "Chapters(%s)"% chap_num
	if nov_desc:
		novel_desc.text = nov_desc
	if Globals.novel_data.novels.has(nov_path):
		download_list = Globals.novel_data.novels[nov_path].chapters.keys()
	else:
		download_list = []
	for i in chap_num:
		create_chapters(i)
	if Globals.novel_data.novels.has(nov_path):
		if Globals.novel_data.novels[nov_path].current_chapter != 0:
			currently_reading.text = "Currently reading Chapter %s"%(
				Globals.novel_data.novels[nov_path].current_chapter)

func set_cover(img:Texture):
	novel_cover.texture = img

func set_author_and_status(author:String="", status:String = ""): # the other one
	if author:
		novel_author.text = author
	if status:
		novel_status.text = status

func genrate_from_novel_url(novel_url):
	novel_data = Globals.novel_data.novels[novel_url]
	generate_content(novel_url, novel_data.name, novel_data.max_chapter_num, novel_data.desc)
	set_cover(Globals.novel_data.load_image(novel_data))
	set_author_and_status(novel_data.author, novel_data.status)

func _update_filter(id:int):
	var filters = filterbutton.get_popup().get_item_text(id)
	match filters:
		"None":
			pass # implement filter
		"Only download":
			pass

func create_chapters(key):
	var button = PassthroughButton.new()#Button.new()
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
		button.icon = DOWNLOAD if disabled else CHECK_LINE
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
	request_handeled = true
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
			Globals.novel_data.save_chapter_text(
				novel_data,
				num,
				result_text,
				current_novel
			)
			update_chapters(num-1, false)
			if !download_queue.is_empty():
				send_post_request(Globals.selected_novel, download_queue[0])
			else:
				request_handeled = false
			return
		else:
			push_error("Missing 'text' field in response.")
	else:
		push_error("HTTP Error %s" % response_code)
	request_handeled = false

func _on_download_pressed() -> void:
	var new_min: int = max(from.text.to_int(), 1)
	var new_max: int = min(max(to.text.to_int(), new_min+1), chapters.text.to_int())
	from.text = str(new_min)
	to.text = str(new_max)
	for i in range(new_min, new_max+1):
		if i not in download_queue:
			download_queue.append(i) 
			# add queues of a general que a processing linked to the various http requests
	if !request_handeled:
		send_post_request(Globals.selected_novel, download_queue[0])
	customdownloadpopuup.hide()

func _on_play_pressed() -> void:
	if Globals.selected_novel and Globals.novel_data.novels[Globals.selected_novel].current_chapter != 0:
		Globals.selected_chapter = Globals.novel_data.novels[Globals.selected_novel].current_chapter
		self.on_next_pressed()

func _on_updatetoggle_toggled(_toggled_on: bool) -> void: # call the update function instead and play animation for it
	pass

func _on_expand_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		expand_button.icon = CHEVRON_UP
		novel_desc.max_lines_visible = -1
	else:
		expand_button.icon = CHEVRON_DOWN
		novel_desc.max_lines_visible = 2
	novel_desc.text += " "
	novel_desc.text = novel_desc.text.rstrip(" ")

func interact_with_lib():
	if Globals.novel_data.novels.has(current_novel):
		Globals.novel_data.delete_info(current_novel)
		Globals.novel_data.novels.erase(current_novel)
		save_button.icon = BOOK_OPEN
	else:
		print(novel_data.name)
		print(novel_data.image_path)
		print(novel_data.max_chapter_num)
		Globals.novel_data.novels[current_novel] = novel_data
		save_button.icon = CIRCLE_CHECK_BIG

func check_lib():
	if Globals.novel_data.novels.has(current_novel):
		save_button.icon = CIRCLE_CHECK_BIG
	else:
		save_button.icon = BOOK_OPEN
	novel_data = NovelData.new()

func _download_chapters(id: int): # might have an error
	var filters = downloadbutton.get_popup().get_item_text(id)
	var download_amount = 0
	match filters:
		"Next Chapter":
			download_amount = 1
		"Next 5 Chapters":
			download_amount = 5
		"Next 10 Chapters":
			download_amount = 10
		"Custom Download":
			customdownloadpopuup.show()
			return
		"Delete Downloads":
			return
	var download_max = download_queue.max()
	var chapter_max = novel_data.chapters.keys().max()
	download_max = 0 if download_max == null else download_max
	var next = max(chapter_max, download_max)+1
	for i in range(next, min(next+download_amount, novel_data.max_chapter_num-1)):
		if i not in download_queue:
			download_queue.append(i)
	if !request_handeled:
		send_post_request(Globals.selected_novel, download_queue[0])

func on_prev_pressed():
	super.on_prev_pressed()
	Globals.selected_novel = ""
