extends Button
class_name PassthroughButton

@export var hold_threshold := 0.1  # seconds

var _is_pressed := false
var _hold_timer := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	set_process(true)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_on_press()
		elif event.is_released():
			_on_release()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_on_press()
		elif event.is_released():
			_on_release()

func _on_press() -> void:
	_is_pressed = true
	_hold_timer = 0.0

func _on_release() -> void:
	if _is_pressed:
		if _hold_timer >= hold_threshold:
			print("Held!")
			_on_hold()
		else:
			print("Tapped!")
			_on_tap()
	_is_pressed = false

func _process(delta: float) -> void:
	if _is_pressed:
		_hold_timer += delta

func _on_tap() -> void:
	if not disabled:
		print("Tap action triggered!")
		pressed.emit()

func _on_hold() -> void:
	#print("Hold action triggered!")
	# Optional: emit a custom signal or handle differently
	pass
