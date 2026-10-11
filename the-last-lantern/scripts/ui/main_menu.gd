extends Control

const SETTINGS_MENU_SCENE := preload("res://scenes/ui/settings_menu.tscn")
const MENU_ENVIRONMENT_SCENE := preload("res://scenes/environment/menu_environment.tscn")
const FOREST_SCENE_PATH := "res://scenes/forest.tscn"
const AMBER := Color("e8a45b")
const PAPER := Color("e8e2d9")

var _home: Control
var _settings: Control
var _play_button: Button
var _fade: ColorRect
var _serif: SystemFont

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_PASS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_serif = SystemFont.new()
	_serif.font_names = PackedStringArray(["Georgia", "Times New Roman"])
	var environment := MENU_ENVIRONMENT_SCENE.instantiate()
	add_child(environment)
	environment.call("build_menu")
	_build_home()
	_settings = SETTINGS_MENU_SCENE.instantiate()
	_settings.visible = false
	_settings.connect("back_requested", Callable(self, "_on_settings_back"))
	add_child(_settings)
	_create_fade_overlay()

func _build_home() -> void:
	_home = Control.new()
	_home.name = "MainMenuOverlay"
	_home.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_home.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_home)

	var dimmer := ColorRect.new()
	dimmer.color = Color(0.01, 0.02, 0.027, 0.18)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_home.add_child(dimmer)

	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.27, 0.48, 0.65, 1.0])
	gradient.colors = PackedColorArray([
		Color(0.005, 0.009, 0.012, 0.84),
		Color(0.005, 0.009, 0.012, 0.68),
		Color(0.005, 0.009, 0.012, 0.28),
		Color(0.005, 0.009, 0.012, 0.0),
		Color(0.005, 0.009, 0.012, 0.0),
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
	_home.add_child(left_scrim)

	var title_top := Label.new()
	title_top.text = "THE LAST"
	title_top.set_anchors_preset(Control.PRESET_TOP_LEFT)
	title_top.anchor_left = 0.075
	title_top.anchor_top = 0.17
	title_top.offset_right = 465.0
	title_top.offset_bottom = 61.0
	title_top.add_theme_font_override("font", _serif)
	title_top.add_theme_font_size_override("font_size", 42)
	title_top.add_theme_color_override("font_color", PAPER)
	title_top.add_theme_constant_override("character_spacing", 5)
	_home.add_child(title_top)

	var title_bottom := Label.new()
	title_bottom.text = "LANTERN"
	title_bottom.set_anchors_preset(Control.PRESET_TOP_LEFT)
	title_bottom.anchor_left = 0.07
	title_bottom.anchor_top = 0.225
	title_bottom.offset_right = 540.0
	title_bottom.offset_bottom = 91.0
	title_bottom.add_theme_font_override("font", _serif)
	title_bottom.add_theme_font_size_override("font_size", 66)
	title_bottom.add_theme_color_override("font_color", PAPER)
	title_bottom.add_theme_constant_override("character_spacing", 3)
	_home.add_child(title_bottom)

	var subtitle := Label.new()
	subtitle.text = "FOUR LANTERNS. ONE WAY OUT."
	subtitle.set_anchors_preset(Control.PRESET_TOP_LEFT)
	subtitle.anchor_left = 0.08
	subtitle.anchor_top = 0.345
	subtitle.offset_right = 470.0
	subtitle.offset_bottom = 26.0
	subtitle.add_theme_font_override("font", _serif)
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color("c8c4bd"))
	subtitle.add_theme_constant_override("character_spacing", 4)
	_home.add_child(subtitle)

	var menu_buttons: Array[Button] = []
	_play_button = _make_menu_button("◇      PLAY", 0.46, _on_play_pressed)
	menu_buttons.append(_play_button)
	menu_buttons.append(_make_menu_button("◇      SETTINGS", 0.535, _on_settings_pressed))
	menu_buttons.append(_make_menu_button("◇      QUIT", 0.61, _on_quit_pressed))
	for button in menu_buttons:
		_home.add_child(button)
	for index in menu_buttons.size():
		var button := menu_buttons[index]
		button.focus_neighbor_top = button.get_path_to(menu_buttons[(index - 1 + menu_buttons.size()) % menu_buttons.size()])
		button.focus_neighbor_bottom = button.get_path_to(menu_buttons[(index + 1) % menu_buttons.size()])
	_play_button.grab_focus.call_deferred()

func _make_menu_button(text: String, top_anchor: float, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	button.anchor_left = 0.075
	button.anchor_top = top_anchor
	button.anchor_right = 0.34
	button.anchor_bottom = top_anchor + 0.065
	button.offset_left = 0.0
	button.offset_top = 0.0
	button.offset_right = 0.0
	button.offset_bottom = 0.0
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", _serif)
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_constant_override("h_separation", 12)
	button.add_theme_color_override("font_color", Color("b6b4b0"))
	button.add_theme_color_override("font_hover_color", AMBER)
	button.add_theme_color_override("font_focus_color", Color("ffd39b"))
	button.add_theme_color_override("font_pressed_color", Color("fff1dc"))
	button.add_theme_stylebox_override("normal", _menu_button_style(Color(0.01, 0.018, 0.022, 0.1), Color(0.77, 0.55, 0.31, 0.18)))
	button.add_theme_stylebox_override("hover", _menu_button_style(Color(0.22, 0.115, 0.04, 0.48), Color(0.9, 0.56, 0.25, 0.75)))
	button.add_theme_stylebox_override("focus", _menu_button_style(Color(0.22, 0.115, 0.04, 0.48), Color(0.9, 0.56, 0.25, 0.85)))
	button.add_theme_stylebox_override("pressed", _menu_button_style(Color(0.3, 0.15, 0.05, 0.65), Color(1.0, 0.65, 0.31, 0.95)))
	button.modulate = Color(0.9, 0.9, 0.88, 1.0)
	button.mouse_entered.connect(button.grab_focus)
	button.focus_entered.connect(_animate_menu_button.bind(button, true))
	button.focus_exited.connect(_animate_menu_button.bind(button, false))
	button.pressed.connect(callback)
	return button

func _animate_menu_button(button: Button, highlighted: bool) -> void:
	var target := Color(1.08, 0.86, 0.66, 1.0) if highlighted else Color(0.9, 0.9, 0.88, 1.0)
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate", target, 0.16)

func _create_fade_overlay() -> void:
	_fade = ColorRect.new()
	_fade.name = "FadeToBlack"
	_fade.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)

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
	get_tree().quit()

func _menu_button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width(SIDE_BOTTOM, 1)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	return style
