extends Control
@onready var text_align: OptionDropdown = %text_align
@onready var voices: OptionDropdown = %voices
@onready var skiplastfew: OptionDropdown = %skiplastfew

@export var text_parent: BoxContainer
@export var voice_parent: Control

var text_aligns = {
	"left": HORIZONTAL_ALIGNMENT_LEFT,
	"center": HORIZONTAL_ALIGNMENT_CENTER,
	"right": HORIZONTAL_ALIGNMENT_RIGHT,
	"fill": HORIZONTAL_ALIGNMENT_FILL
}

func _ready() -> void:
	var count:int = 0
	for i in DisplayServer.tts_get_voices_for_language("en"):
		voices.option_button.add_item(i.split("-")[-1], count)
		count += 1

func _on_button_pressed() -> void:
	hide()

func _on_text_align_item_selected(index: int) -> void:
	if text_parent:
		var new_alignment:HorizontalAlignment = text_aligns[text_align.get_text_from_index(index)]
		for i in text_parent.get_children():
			i = i as Button
			i.alignment = new_alignment

func _on_voices_item_selected(index: int) -> void:
	if index != -1:
		Globals.voice_id = DisplayServer.tts_get_voices_for_language("en")[index]
		if voice_parent:
			voice_parent.voice_id = Globals.voice_id
			DisplayServer.tts_stop()
			voice_parent.tts_index -= 1
			voice_parent.play_audio()

func _on_skiplastfew_item_selected(index: int) -> void:
	voice_parent.skip_chapters = skiplastfew.get_text_from_index(index).to_int()
