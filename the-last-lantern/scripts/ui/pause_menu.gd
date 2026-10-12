extends Control

signal resume_requested
signal main_menu_requested

const SETTINGS_MENU_SCENE := preload("res://scenes/ui/settings_menu.tscn")

var _pause_home: Control
var _settings: Control
var _resume_button: Button
var _pause_heading: Label
var _pause_buttons: Dictionary = {}
var _ui_font: SystemFont

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_font = SystemFont.new()
	_ui_font.font_names = PackedStringArray(["Segoe UI", "Arial"])
	_build_pause_home()
	_settings = SETTINGS_MENU_SCENE.instantiate()
	_settings.visible = false
	_settings.connect("back_requested", Callable(self, "_on_settings_back"))
	add_child(_settings)
	SettingsManager.settings_changed.connect(_sync_language)
	_sync_language(SettingsManager.get_values_copy())

func open() -> void:
	visible = true
	_pause_home.visible = true
	_settings.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	_resume_button.grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and not _settings.visible and event.is_action_pressed("pause"):
		_resume()
		get_viewport().set_input_as_handled()

func _build_pause_home() -> void:
	_pause_home = Control.new()
	_pause_home.name = "PauseHome"
	_pause_home.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_pause_home)

	var dimmer := ColorRect.new()
	dimmer.name = "PauseDimming"
	dimmer.color = Color(0.0, 0.0, 0.0, 0.74)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_home.add_child(dimmer)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.anchor_left = 0.34
	panel.anchor_top = 0.2
	panel.anchor_right = 0.66
	panel.anchor_bottom = 0.8
	panel.offset_left = 0.0
	panel.offset_top = 0.0
	panel.offset_right = 0.0
	panel.offset_bottom = 0.0
	panel.add_theme_stylebox_override("panel", _panel_style())
	_pause_home.add_child(panel)
	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 12)
	panel.add_child(layout)
	_pause_heading = Label.new()
	_pause_heading.text = "PAUSED"
	_pause_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause_heading.add_theme_font_size_override("font_size", 29)
	_pause_heading.add_theme_color_override("font_color", Color("e9e2d8"))
	layout.add_child(_pause_heading)
	var line := ColorRect.new()
	line.color = Color(0.81, 0.53, 0.26, 0.45)
	line.custom_minimum_size.y = 1
	layout.add_child(line)
	_resume_button = _add_pause_button(layout, "resume", _resume)
	_add_pause_button(layout, "settings", _open_settings)
	_add_pause_button(layout, "main_menu", _return_to_menu)

func _add_pause_button(parent: VBoxContainer, text_key: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = SettingsManager.text_for(text_key)
	button.custom_minimum_size = Vector2(240, 42)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color("c6c2bb"))
	button.add_theme_color_override("font_hover_color", Color("efb36f"))
	button.add_theme_stylebox_override("normal", _button_style(Color(0.02, 0.03, 0.035, 0.5), Color(0.45, 0.49, 0.5, 0.25)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.2, 0.11, 0.045, 0.75), Color(0.82, 0.54, 0.25, 0.85)))
	button.add_theme_stylebox_override("focus", _button_style(Color(0.2, 0.11, 0.045, 0.75), Color(0.82, 0.54, 0.25, 0.85)))
	button.pressed.connect(callback)
	parent.add_child(button)
	_pause_buttons[text_key] = button
	return button

func _sync_language(_values: Dictionary) -> void:
	var arabic := String(SettingsManager.get_value("language", "English")) == "Arabic"
	var direction := Control.LAYOUT_DIRECTION_RTL if arabic else Control.LAYOUT_DIRECTION_LTR
	if is_instance_valid(_pause_home):
		_pause_home.layout_direction = direction
	if is_instance_valid(_pause_heading):
		_pause_heading.text = SettingsManager.text_for("paused")
		_pause_heading.add_theme_font_override("font", _ui_font)
	for key in _pause_buttons:
		var button: Button = _pause_buttons[key]
		button.text = SettingsManager.text_for(String(key))
		button.add_theme_font_override("font", _ui_font)

func _open_settings() -> void:
	_pause_home.visible = false
	_settings.call("open")

func _on_settings_back() -> void:
	_settings.visible = false
	_pause_home.visible = true
	_resume_button.grab_focus()

func _resume() -> void:
	visible = false
	get_tree().paused = false
	resume_requested.emit()

func _return_to_menu() -> void:
	visible = false
	get_tree().paused = false
	main_menu_requested.emit()

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.007, 0.015, 0.021, 0.94)
	style.border_color = Color(0.7, 0.53, 0.35, 0.48)
	style.set_border_width_all(1)
	style.content_margin_left = 34.0
	style.content_margin_right = 34.0
	style.content_margin_top = 28.0
	style.content_margin_bottom = 28.0
	return style

func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	return style
