extends Control

signal play_requested
signal settings_requested

const MENU_ART := preload("res://assets/ui/main_menu_reference.png")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_menu()

func _build_menu() -> void:
	var background := TextureRect.new()
	background.name = "ReferenceMenuArt"
	background.texture = MENU_ART
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	# The labels and their selected PLAY treatment are part of the provided art.
	# Transparent hit areas preserve the reference exactly while keeping each row clickable.
	_add_hit_area("PlayHitArea", Rect2(0.115, 0.455, 0.30, 0.078), _on_play_pressed)
	_add_hit_area("SettingsHitArea", Rect2(0.115, 0.532, 0.33, 0.079), _on_settings_pressed)
	_add_hit_area("QuitHitArea", Rect2(0.115, 0.612, 0.30, 0.078), _on_quit_pressed)

func _add_hit_area(node_name: String, normalized_rect: Rect2, callback: Callable) -> void:
	var button := Button.new()
	button.name = node_name
	button.text = ""
	button.flat = true
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.anchor_left = normalized_rect.position.x
	button.anchor_top = normalized_rect.position.y
	button.anchor_right = normalized_rect.position.x + normalized_rect.size.x
	button.anchor_bottom = normalized_rect.position.y + normalized_rect.size.y
	button.offset_left = 0.0
	button.offset_top = 0.0
	button.offset_right = 0.0
	button.offset_bottom = 0.0
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.pressed.connect(callback)
	add_child(button)

func _on_play_pressed() -> void:
	# Hook this signal to the forest scene once the user-created level is ready.
	play_requested.emit()

func _on_settings_pressed() -> void:
	# The settings layout will be added after its reference image is provided.
	settings_requested.emit()

func _on_quit_pressed() -> void:
	get_tree().quit()
