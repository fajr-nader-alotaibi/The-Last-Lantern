extends Control

signal back_requested

const CATEGORIES := ["GAMEPLAY", "GRAPHICS", "AUDIO", "UI"]
const AMBER := Color("e6a254")
const PAPER := Color("e6e0d6")
const MUTED := Color("a1a5a5")
const SETTINGS_MANAGER := NodePath("/root/SettingsManager")

var _working: Dictionary = {}
var _active_category := "GAMEPLAY"
var _content: VBoxContainer
var _category_buttons: Dictionary = {}
var _apply_button: Button
var _serif: SystemFont

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_serif = SystemFont.new()
	_serif.font_names = PackedStringArray(["Georgia", "Times New Roman"])
	_build_shell()
	_build_category_content()
	resized.connect(_adjust_row_sizes)
	call_deferred("_adjust_row_sizes")

func open() -> void:
	_working = get_node(SETTINGS_MANAGER).call("get_values_copy")
	_active_category = "GAMEPLAY"
	visible = true
	_build_category_content()
	if _category_buttons.has(_active_category):
		_category_buttons[_active_category].grab_focus()

func close(discard_changes: bool = true) -> void:
	if discard_changes:
		_working = get_node(SETTINGS_MANAGER).call("get_values_copy")
	visible = false
	back_requested.emit()

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		close(true)
		get_viewport().set_input_as_handled()

func _build_shell() -> void:
	var dimmer := ColorRect.new()
	dimmer.color = Color(0.012, 0.019, 0.024, 0.64)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	var title := Label.new()
	title.text = "THE LAST\nLANTERN"
	title.set_anchors_preset(Control.PRESET_TOP_LEFT)
	title.anchor_left = 0.042
	title.anchor_top = 0.045
	title.offset_right = 310.0
	title.offset_bottom = 104.0
	title.add_theme_font_override("font", _serif)
	title.add_theme_font_size_override("font_size", 39)
	title.add_theme_color_override("font_color", PAPER)
	title.add_theme_constant_override("line_spacing", -5)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "FOUR LANTERNS. ONE WAY OUT."
	subtitle.set_anchors_preset(Control.PRESET_TOP_LEFT)
	subtitle.anchor_left = 0.043
	subtitle.anchor_top = 0.194
	subtitle.offset_right = 330.0
	subtitle.offset_bottom = 24.0
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", Color("bdb9b1"))
	subtitle.add_theme_constant_override("character_spacing", 3)
	add_child(subtitle)

	var navigation := VBoxContainer.new()
	navigation.name = "SettingsCategories"
	navigation.set_anchors_preset(Control.PRESET_TOP_LEFT)
	navigation.anchor_left = 0.025
	navigation.anchor_top = 0.285
	navigation.anchor_right = 0.225
	navigation.anchor_bottom = 0.75
	navigation.offset_right = 0.0
	navigation.offset_bottom = 0.0
	navigation.add_theme_constant_override("separation", 9)
	add_child(navigation)
	for category in CATEGORIES:
		var button := Button.new()
		button.name = category.capitalize() + "Category"
		button.text = category
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(190, 42)
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_font_size_override("font_size", 15)
		button.add_theme_color_override("font_color", MUTED)
		button.add_theme_color_override("font_hover_color", PAPER)
		button.add_theme_color_override("font_focus_color", PAPER)
		button.add_theme_stylebox_override("normal", _flat_style(Color(0.015, 0.025, 0.032, 0.05), Color(0.65, 0.69, 0.72, 0.12), 0, 1))
		button.add_theme_stylebox_override("hover", _flat_style(Color(0.13, 0.08, 0.035, 0.38), Color(0.76, 0.48, 0.22, 0.45), 0, 1))
		button.add_theme_stylebox_override("focus", _flat_style(Color(0.13, 0.08, 0.035, 0.45), AMBER, 0, 1))
		button.pressed.connect(_select_category.bind(category))
		navigation.add_child(button)
		_category_buttons[category] = button

	var back := Button.new()
	back.text = "←   BACK"
	back.custom_minimum_size = Vector2(190, 42)
	back.alignment = HORIZONTAL_ALIGNMENT_LEFT
	back.focus_mode = Control.FOCUS_ALL
	back.add_theme_font_size_override("font_size", 15)
	back.add_theme_color_override("font_color", PAPER)
	back.add_theme_stylebox_override("normal", _flat_style(Color(0.015, 0.025, 0.032, 0.05), Color(0.65, 0.69, 0.72, 0.12), 0, 1))
	back.add_theme_stylebox_override("hover", _flat_style(Color(0.13, 0.08, 0.035, 0.38), AMBER, 0, 1))
	back.pressed.connect(close.bind(true))
	navigation.add_child(back)

	var main_panel := PanelContainer.new()
	main_panel.name = "OptionsPanel"
	main_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	main_panel.anchor_left = 0.263
	main_panel.anchor_top = 0.145
	main_panel.anchor_right = 0.645
	main_panel.anchor_bottom = 0.867
	main_panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(main_panel)
	var main_margin := MarginContainer.new()
	main_margin.add_theme_constant_override("margin_left", 20)
	main_margin.add_theme_constant_override("margin_right", 20)
	main_margin.add_theme_constant_override("margin_top", 16)
	main_margin.add_theme_constant_override("margin_bottom", 15)
	main_panel.add_child(main_margin)
	var main_column := VBoxContainer.new()
	main_column.add_theme_constant_override("separation", 8)
	main_margin.add_child(main_column)
	var page_heading := Label.new()
	page_heading.name = "CategoryHeading"
	page_heading.add_theme_font_override("font", _serif)
	page_heading.add_theme_font_size_override("font_size", 18)
	page_heading.add_theme_color_override("font_color", PAPER)
	main_column.add_child(page_heading)
	var rule := ColorRect.new()
	rule.color = Color(0.76, 0.71, 0.63, 0.22)
	rule.custom_minimum_size.y = 1
	main_column.add_child(rule)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_column.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 4)
	scroll.add_child(_content)

	var guide_panel := PanelContainer.new()
	guide_panel.name = "ControlsGuide"
	guide_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	guide_panel.anchor_left = 0.665
	guide_panel.anchor_top = 0.19
	guide_panel.anchor_right = 0.96
	guide_panel.anchor_bottom = 0.805
	guide_panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(guide_panel)
	var guide_margin := MarginContainer.new()
	guide_margin.add_theme_constant_override("margin_left", 20)
	guide_margin.add_theme_constant_override("margin_right", 20)
	guide_margin.add_theme_constant_override("margin_top", 16)
	guide_margin.add_theme_constant_override("margin_bottom", 16)
	guide_panel.add_child(guide_margin)
	var guide := VBoxContainer.new()
	guide.add_theme_constant_override("separation", 10)
	guide_margin.add_child(guide)
	var guide_heading := Label.new()
	guide_heading.text = "CONTROLS OVERVIEW"
	guide_heading.add_theme_font_override("font", _serif)
	guide_heading.add_theme_font_size_override("font_size", 17)
	guide_heading.add_theme_color_override("font_color", PAPER)
	guide.add_child(guide_heading)
	var guide_rule := ColorRect.new()
	guide_rule.color = Color(0.76, 0.71, 0.63, 0.18)
	guide_rule.custom_minimum_size.y = 1
	guide.add_child(guide_rule)
	_add_guide_section(guide, "CAMERA", "Q / E     Orbit around the explorer\nEach press turns by the selected step.")
	_add_guide_section(guide, "MOVEMENT", "W  A  S  D     Move through the forest")
	_add_guide_section(guide, "INTERACTION", "F     Light or use the object in view")
	_add_guide_section(guide, "MENUS", "Esc     Pause, go back, or resume")
	var note := Label.new()
	note.text = "Camera rotation follows fixed steps.\nMouse look stays off unless enabled."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", MUTED)
	note.size_flags_vertical = Control.SIZE_EXPAND_FILL
	guide.add_child(note)

	var footer := HBoxContainer.new()
	footer.set_anchors_preset(Control.PRESET_TOP_LEFT)
	footer.anchor_left = 0.665
	footer.anchor_top = 0.84
	footer.anchor_right = 0.96
	footer.anchor_bottom = 0.925
	footer.add_theme_constant_override("separation", 16)
	add_child(footer)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	_apply_button = _make_action_button("APPLY", true)
	_apply_button.pressed.connect(_apply_changes)
	footer.add_child(_apply_button)
	var footer_back := _make_action_button("BACK", false)
	footer_back.pressed.connect(close.bind(true))
	footer.add_child(footer_back)

func _select_category(category: String) -> void:
	_active_category = category
	_build_category_content()

func _build_category_content() -> void:
	if _content == null:
		return
	for child in _content.get_children():
		child.queue_free()
	var heading := get_node_or_null("OptionsPanel/MarginContainer/VBoxContainer/CategoryHeading") as Label
	if heading != null:
		heading.text = _active_category
	for category in _category_buttons:
		var button: Button = _category_buttons[category]
		button.add_theme_color_override("font_color", AMBER if category == _active_category else MUTED)
	match _active_category:
		"GAMEPLAY":
			_build_gameplay_options()
		"GRAPHICS":
			_build_graphics_options()
		"AUDIO":
			_build_audio_options()
		"UI":
			_build_ui_options()
	call_deferred("_adjust_row_sizes")

func _build_gameplay_options() -> void:
	_add_section_header("MOVEMENT & CAMERA")
	_add_static_row("Movement Type", "WASD")
	_add_static_row("Camera Mode", "Third Person")
	_add_static_row("Camera Rotation", "Q / E · 360°")
	_add_slider_row("Rotation Step", "camera_rotation_step", 10.0, 45.0, 1.0, "°")
	_add_toggle_row("Mouse Camera Control", "mouse_camera_control")
	_add_slider_row("Mouse Sensitivity", "mouse_sensitivity", 0.1, 1.5, 0.05, "", "%.2f", not bool(_working.get("mouse_camera_control", false)))
	_add_toggle_row("Invert Y Axis", "invert_y", not bool(_working.get("mouse_camera_control", false)))
	_add_slider_row("Field of View", "field_of_view", 55.0, 95.0, 1.0, "°")
	_add_slider_row("Camera Follow Speed", "camera_follow_speed", 0.2, 1.0, 0.05, "", "%.2f")
	_add_slider_row("Camera Height", "camera_height", 1.0, 2.6, 0.1, " m", "%.1f")
	_add_slider_row("Camera Distance", "camera_distance", 2.5, 7.0, 0.1, " m", "%.1f")
	_add_toggle_row("Collision Avoidance", "camera_collision")
	_add_section_header("INTERACTION")
	_add_static_row("Interact / Use", "F")
	_add_slider_row("Interaction Range", "interaction_range", 1.0, 4.0, 0.1, " m", "%.1f")
	_add_toggle_row("Show Interaction Prompts", "show_interaction_prompts")

func _build_graphics_options() -> void:
	_add_section_header("DISPLAY")
	_add_option_row("Display Mode", "display_mode", ["Fullscreen", "Maximized", "Windowed"])
	_add_option_row("Resolution", "resolution", _available_resolutions(), String(_working.get("display_mode", "Maximized")) != "Windowed")
	_add_toggle_row("VSync", "vsync")
	_add_option_row("Graphics Quality", "graphics_quality", ["Low", "Medium", "High"])
	_add_static_row("Quality setting", "Controls 3D anti-aliasing")

func _build_audio_options() -> void:
	_add_section_header("AUDIO LEVELS")
	_add_slider_row("Master Volume", "master_volume", 0.0, 1.0, 0.01, "%", "%.0f", false, true)
	_add_slider_row("Music Volume", "music_volume", 0.0, 1.0, 0.01, "%", "%.0f", false, true)
	_add_slider_row("Sound Effects", "sfx_volume", 0.0, 1.0, 0.01, "%", "%.0f", false, true)
	_add_note("Volume levels are applied to the Master, Music, and SFX buses when you press APPLY. The project currently has no music or sound files assigned.")

func _build_ui_options() -> void:
	_add_section_header("INTERFACE")
	_add_toggle_row("Show Interaction Prompts", "show_interaction_prompts")
	_add_slider_row("UI Scale", "ui_scale", 0.8, 1.2, 0.05, "×", "%.2f")
	_add_static_row("Language", "English")
	_add_note("Arabic is not available yet. The interface remains in English until Arabic text and right-to-left layout are added.")

func _add_section_header(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.y = 29
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", _serif)
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color("f4bd78"))
	_content.add_child(label)
	var divider := ColorRect.new()
	divider.color = Color(0.76, 0.71, 0.63, 0.16)
	divider.custom_minimum_size.y = 1
	_content.add_child(divider)

func _add_static_row(label_text: String, value_text: String) -> void:
	var row := _new_row(label_text)
	var value := Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.custom_minimum_size.x = 148
	value.add_theme_color_override("font_color", PAPER)
	value.add_theme_font_size_override("font_size", 13)
	row.add_child(value)
	_content.add_child(row)

func _add_slider_row(label_text: String, key: String, minimum: float, maximum: float, step: float, suffix: String, number_format: String = "%.1f", disabled: bool = false, percent: bool = false) -> void:
	var row := _new_row(label_text)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = float(_working.get(key, minimum))
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.x = clampf(get_viewport_rect().size.x * 0.082, 76.0, 105.0)
	slider.focus_mode = Control.FOCUS_ALL
	slider.editable = not disabled
	var value_label := Label.new()
	value_label.custom_minimum_size.x = clampf(get_viewport_rect().size.x * 0.032, 32.0, 42.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 12)
	value_label.add_theme_color_override("font_color", PAPER)
	value_label.text = _format_slider(slider.value, suffix, number_format, percent)
	slider.value_changed.connect(func(value: float) -> void:
		_working[key] = value
		value_label.text = _format_slider(value, suffix, number_format, percent)
	)
	row.add_child(slider)
	row.add_child(value_label)
	_content.add_child(row)

func _add_toggle_row(label_text: String, key: String, disabled: bool = false) -> void:
	var row := _new_row(label_text)
	var toggle := CheckButton.new()
	toggle.button_pressed = bool(_working.get(key, false))
	toggle.text = "ON" if toggle.button_pressed else "OFF"
	toggle.custom_minimum_size.x = 74
	toggle.focus_mode = Control.FOCUS_ALL
	toggle.disabled = disabled
	toggle.toggled.connect(func(enabled: bool) -> void:
		_working[key] = enabled
		toggle.text = "ON" if enabled else "OFF"
		if key == "mouse_camera_control":
			_build_category_content()
	)
	row.add_child(toggle)
	_content.add_child(row)

func _add_option_row(label_text: String, key: String, choices: Array, disabled: bool = false) -> void:
	var row := _new_row(label_text)
	var option := OptionButton.new()
	option.custom_minimum_size.x = clampf(get_viewport_rect().size.x * 0.115, 112.0, 148.0)
	option.size_flags_horizontal = Control.SIZE_SHRINK_END
	option.focus_mode = Control.FOCUS_ALL
	option.disabled = disabled
	for choice in choices:
		option.add_item(String(choice))
		if String(choice) == String(_working.get(key, "")):
			option.select(option.item_count - 1)
	if option.selected < 0 and option.item_count > 0:
		option.select(0)
	option.item_selected.connect(func(index: int) -> void:
		_working[key] = option.get_item_text(index)
		if key == "display_mode":
			_build_category_content()
	)
	row.add_child(option)
	_content.add_child(row)

func _add_note(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(0, 64)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", MUTED)
	_content.add_child(label)

func _new_row(label_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 29
	row.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size.x = clampf(get_viewport_rect().size.x * 0.137, 118.0, 175.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", PAPER)
	row.add_child(label)
	return row

func _adjust_row_sizes() -> void:
	if _content == null:
		return
	var screen_width := get_viewport_rect().size.x
	for row in _content.get_children():
		if not row is HBoxContainer:
			continue
		for child in row.get_children():
			if child is Label and child == row.get_child(0):
				child.custom_minimum_size.x = clampf(screen_width * 0.137, 118.0, 175.0)
			elif child is HSlider:
				child.custom_minimum_size.x = clampf(screen_width * 0.082, 76.0, 105.0)
			elif child is OptionButton:
				child.custom_minimum_size.x = clampf(screen_width * 0.115, 112.0, 148.0)

func _add_guide_section(parent: VBoxContainer, title: String, content_text: String) -> void:
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_override("font", _serif)
	title_label.add_theme_font_size_override("font_size", 13)
	title_label.add_theme_color_override("font_color", Color("d3ba9a"))
	parent.add_child(title_label)
	var content := Label.new()
	content.text = content_text
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.custom_minimum_size.y = 42
	content.add_theme_font_size_override("font_size", 13)
	content.add_theme_color_override("font_color", PAPER)
	parent.add_child(content)
	var divider := ColorRect.new()
	divider.color = Color(0.76, 0.71, 0.63, 0.13)
	divider.custom_minimum_size.y = 1
	parent.add_child(divider)

func _apply_changes() -> void:
	get_node(SETTINGS_MANAGER).call("apply_values", _working, true)
	_apply_button.text = "APPLIED"
	_apply_button.grab_focus()
	var timer := get_tree().create_timer(1.2)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(_apply_button):
			_apply_button.text = "APPLY"
	)

func _available_resolutions() -> Array:
	var available: Array = []
	var screen_size := DisplayServer.screen_get_size()
	for resolution in ["1280x720", "1440x810", "1600x900", "1920x1080"]:
		var parts := String(resolution).split("x")
		if int(parts[0]) <= screen_size.x - 80 and int(parts[1]) <= screen_size.y - 120:
			available.append(resolution)
	if available.is_empty():
		available.append("%dx%d" % [maxi(screen_size.x - 100, 800), maxi(screen_size.y - 140, 600)])
	if not available.has(String(_working.get("resolution", "1440x810"))):
		available.append(String(_working.get("resolution", "1440x810")))
	return available

func _format_slider(value: float, suffix: String, number_format: String, percent: bool) -> String:
	var shown := value * 100.0 if percent else value
	return (number_format % shown) + suffix

func _make_action_button(text: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(130, 42)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override("font", _serif)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", AMBER if primary else PAPER)
	button.add_theme_color_override("font_hover_color", Color("fff3df"))
	var fill := Color(0.21, 0.11, 0.035, 0.74) if primary else Color(0.025, 0.033, 0.04, 0.76)
	button.add_theme_stylebox_override("normal", _flat_style(fill, Color(0.76, 0.48, 0.22, 0.75) if primary else Color(0.68, 0.71, 0.72, 0.3), 2, 1))
	button.add_theme_stylebox_override("hover", _flat_style(fill.lightened(0.2), AMBER, 2, 1))
	button.add_theme_stylebox_override("focus", _flat_style(fill, AMBER, 2, 2))
	button.add_theme_stylebox_override("pressed", _flat_style(fill.lightened(0.3), AMBER, 2, 1))
	return button

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.006, 0.012, 0.017, 0.91)
	style.border_color = Color(0.56, 0.58, 0.58, 0.36)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 4)
	return style

func _flat_style(color: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	return style
