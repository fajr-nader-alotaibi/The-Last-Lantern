extends Control

const SETTINGS_MENU_SCENE := preload("res://scenes/ui/settings_menu.tscn")
const MENU_BACKGROUND := preload("res://assets/ui/menu_forest_background.png")
const FOREST_SCENE_PATH := "res://scenes/forest.tscn"
const AMBER := Color("e8a45b")
const PAPER := Color("e8e2d9")

var _home: Control
var _settings: Control
var _title: Label
var _subtitle: Label
var _play_button: Button
var _settings_button: Button
var _quit_button: Button
var _quit_dialog: ConfirmationDialog
var _fade: ColorRect
var _serif: SystemFont
var _ui_font: SystemFont

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_PASS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_serif = SystemFont.new()
	_serif.font_names = PackedStringArray(["Georgia", "Times New Roman"])
	_ui_font = SystemFont.new()
	_ui_font.font_names = PackedStringArray(["Segoe UI", "Arial"])
	_build_image_background()
	_build_home()
	_settings = SETTINGS_MENU_SCENE.instantiate()
	_settings.visible = false
	_settings.connect("back_requested", Callable(self, "_on_settings_back"))
	add_child(_settings)
	_create_quit_dialog()
	_create_fade_overlay()
	SettingsManager.settings_changed.connect(_sync_language)
	_sync_language(SettingsManager.get_values_copy())

func _build_image_background() -> void:
	var image := TextureRect.new()
	image.name = "ForestBackgroundImage"
	image.texture = MENU_BACKGROUND
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(image)
	var atmosphere := ColorRect.new()
	atmosphere.name = "AtmosphereTint"
	atmosphere.color = Color(0.012, 0.025, 0.045, 0.16)
	atmosphere.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(atmosphere)
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.27, 0.50, 0.72, 1.0])
	gradient.colors = PackedColorArray([
		Color(0.004, 0.008, 0.013, 0.80),
		Color(0.004, 0.008, 0.013, 0.68),
		Color(0.004, 0.008, 0.013, 0.38),
		Color(0.004, 0.008, 0.013, 0.08),
		Color(0.004, 0.008, 0.013, 0.0),
	])
	var gradient_texture := GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.width = 512
	gradient_texture.height = 4
	gradient_texture.fill_from = Vector2(0.0, 0.5)
	gradient_texture.fill_to = Vector2(1.0, 0.5)
	var left_scrim := TextureRect.new()
	left_scrim.name = "TitleScrim"
	left_scrim.texture = gradient_texture
	left_scrim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	left_scrim.stretch_mode = TextureRect.STRETCH_SCALE
	left_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	left_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(left_scrim)

func _build_home() -> void:
	_home = Control.new()
	_home.name = "MainMenuOverlay"
	_home.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_home.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_home)
	_title = Label.new()
	_title.name = "GameTitle"
	_title.text = "THE LAST\nLANTERN"
	_title.add_theme_font_override("font", _serif)
	_title.add_theme_font_size_override("font_size", 64)
	_title.add_theme_color_override("font_color", PAPER)
	_title.add_theme_constant_override("line_spacing", -8)
	_title.add_theme_constant_override("character_spacing", 3)
	_home.add_child(_title)
	_subtitle = Label.new()
	_subtitle.name = "GameSubtitle"
	_subtitle.add_theme_font_override("font", _serif)
	_subtitle.add_theme_font_size_override("font_size", 14)
	_subtitle.add_theme_color_override("font_color", Color("c8c4bd"))
	_subtitle.add_theme_constant_override("character_spacing", 3)
	_home.add_child(_subtitle)
	_play_button = _make_menu_button(0.46, _on_play_pressed)
	_settings_button = _make_menu_button(0.535, _on_settings_pressed)
	_quit_button = _make_menu_button(0.61, _on_quit_pressed)
	_home.add_child(_play_button)
	_home.add_child(_settings_button)
	_home.add_child(_quit_button)
	_play_button.focus_neighbor_top = _play_button.get_path_to(_quit_button)
	_play_button.focus_neighbor_bottom = _play_button.get_path_to(_settings_button)
	_settings_button.focus_neighbor_top = _settings_button.get_path_to(_play_button)
	_settings_button.focus_neighbor_bottom = _settings_button.get_path_to(_quit_button)
	_quit_button.focus_neighbor_top = _quit_button.get_path_to(_settings_button)
	_quit_button.focus_neighbor_bottom = _quit_button.get_path_to(_play_button)
	_play_button.grab_focus.call_deferred()

func _make_menu_button(top_anchor: float, callback: Callable) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(390, 54)
	button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	button.anchor_top = top_anchor
	button.anchor_bottom = top_anchor + 0.065
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", _serif)
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", Color("b6b4b0"))
	button.add_theme_color_override("font_hover_color", AMBER)
	button.add_theme_color_override("font_focus_color", Color("ffd39b"))
	button.add_theme_color_override("font_pressed_color", Color("fff1dc"))
	button.add_theme_stylebox_override("normal", _menu_button_style(Color(0.01, 0.018, 0.022, 0.10), Color(0.77, 0.55, 0.31, 0.18)))
	button.add_theme_stylebox_override("hover", _menu_button_style(Color(0.22, 0.115, 0.04, 0.48), Color(0.9, 0.56, 0.25, 0.75)))
	button.add_theme_stylebox_override("focus", _menu_button_style(Color(0.22, 0.115, 0.04, 0.48), Color(0.9, 0.56, 0.25, 0.85)))
	button.add_theme_stylebox_override("pressed", _menu_button_style(Color(0.3, 0.15, 0.05, 0.65), Color(1.0, 0.65, 0.31, 0.95)))
	button.mouse_entered.connect(button.grab_focus)
	button.focus_entered.connect(_animate_menu_button.bind(button, true))
	button.focus_exited.connect(_animate_menu_button.bind(button, false))
	button.pressed.connect(callback)
	return button

func _animate_menu_button(button: Button, highlighted: bool) -> void:
	var target := Color(1.08, 0.86, 0.66, 1.0) if highlighted else Color(0.9, 0.9, 0.88, 1.0)
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate", target, 0.16)

func _sync_language(_values: Dictionary) -> void:
	if not is_instance_valid(_home):
		return
	var arabic := String(SettingsManager.get_value("language", "English")) == "Arabic"
	var left := 0.07 if not arabic else 0.53
	_title.anchor_left = left
	_title.anchor_top = 0.17
	_title.anchor_right = left + 0.42
	_title.anchor_bottom = 0.34
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if arabic else HORIZONTAL_ALIGNMENT_LEFT
	_subtitle.text = SettingsManager.text_for("subtitle")
	_subtitle.anchor_left = left + 0.005
	_subtitle.anchor_top = 0.35
	_subtitle.anchor_right = left + 0.44
	_subtitle.anchor_bottom = 0.395
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if arabic else HORIZONTAL_ALIGNMENT_LEFT
	_home.layout_direction = Control.LAYOUT_DIRECTION_RTL if arabic else Control.LAYOUT_DIRECTION_LTR
	var buttons := [_play_button, _settings_button, _quit_button]
	var keys := ["play", "settings", "quit"]
	for index in buttons.size():
		var button: Button = buttons[index]
		button.text = "◇      " + SettingsManager.text_for(keys[index])
		button.anchor_left = left
		button.anchor_right = left + 0.34
		button.alignment = HORIZONTAL_ALIGNMENT_RIGHT if arabic else HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_override("font", _ui_font if arabic else _serif)
	if is_instance_valid(_quit_dialog):
		_quit_dialog.title = SettingsManager.text_for("quit_title")
		_quit_dialog.dialog_text = SettingsManager.text_for("quit_question")
		_quit_dialog.ok_button_text = SettingsManager.text_for("quit")
		_quit_dialog.cancel_button_text = SettingsManager.text_for("cancel")

func _create_quit_dialog() -> void:
	_quit_dialog = ConfirmationDialog.new()
	_quit_dialog.title = SettingsManager.text_for("quit_title")
	_quit_dialog.dialog_text = SettingsManager.text_for("quit_question")
	_quit_dialog.confirmed.connect(_on_quit_confirmed)
	add_child(_quit_dialog)

func _create_fade_overlay() -> void:
	_fade = ColorRect.new()
	_fade.name = "FadeToBlack"
	_fade.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)

func _input(event: InputEvent) -> void:
	if _home.visible and not _settings.visible and event.is_action_pressed("pause"):
		_quit_dialog.popup_centered()
		get_viewport().set_input_as_handled()

func _on_play_pressed() -> void:
	_home.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.55)
	await tween.finished
	var error := get_tree().change_scene_to_file(FOREST_SCENE_PATH)
	if error != OK:
		push_error("Could not open the forest scene. Error: %s" % error_string(error))

func _on_settings_pressed() -> void:
	_home.visible = false
	_settings.call("open")

func _on_settings_back() -> void:
	_settings.visible = false
	_home.visible = true
	_play_button.grab_focus()

func _on_quit_pressed() -> void:
	_quit_dialog.popup_centered()

func _on_quit_confirmed() -> void:
	get_tree().quit()

func _menu_button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width(SIDE_BOTTOM, 1)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	return style
