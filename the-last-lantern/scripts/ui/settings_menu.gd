extends Control

signal back_requested

const CATEGORIES := ["GAMEPLAY", "GRAPHICS", "AUDIO", "UI"]
const CATEGORY_KEYS := {"GAMEPLAY": "gameplay", "GRAPHICS": "graphics", "AUDIO": "audio", "UI": "ui"}
const BINDING_KEYS := {
	"move_forward": "move_forward", "move_left": "move_left", "move_backward": "move_backward", "move_right": "move_right",
	"camera_orbit_left": "orbit_left", "camera_orbit_right": "orbit_right", "interact": "interact_use",
}
const AMBER := Color("e6a254")
const PAPER := Color("e6e0d6")
const MUTED := Color("a1a5a5")

var _working: Dictionary = {}
var _active_category := "GAMEPLAY"
var _content: VBoxContainer
var _category_buttons: Dictionary = {}
var _apply_button: Button
var _status_label: Label
var _guide: VBoxContainer
var _serif: SystemFont
var _sans: SystemFont
var _rebinding_action := ""
var _rebinding_button: Button
var _restore_dialog: ConfirmationDialog
var _main_panel: Control
var _guide_panel: Control
var _navigation: Control
var _footer: Control
var _restore_button: Button
var _footer_back_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_serif = SystemFont.new()
	_serif.font_names = PackedStringArray(["Georgia", "Times New Roman"])
	_sans = SystemFont.new()
	_sans.font_names = PackedStringArray(["Segoe UI", "Arial"])
	_build_shell()
	_build_category_content()
	_apply_language_layout()
	resized.connect(_adjust_row_sizes)
	call_deferred("_adjust_row_sizes")

func open() -> void:
	_working = SettingsManager.get_values_copy()
	_active_category = "GAMEPLAY"
	visible = true
	_build_category_content()
	_apply_language_layout()
	if _category_buttons.has(_active_category):
		_category_buttons[_active_category].grab_focus()

func close(discard_changes: bool = true) -> void:
	if _rebinding_action != "":
		_cancel_rebind()
	if discard_changes:
		SettingsManager.reset_to_saved()
		_working = SettingsManager.get_values_copy()
	visible = false
	back_requested.emit()

func _input(event: InputEvent) -> void:
	if not visible or _rebinding_action.is_empty():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		if event.physical_keycode == KEY_ESCAPE or event.keycode == KEY_ESCAPE:
			_cancel_rebind()
			return
		var code := int(event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode)
		if code <= 0:
			return
		var existing := _find_binding_conflict(code, _rebinding_action)
		if not existing.is_empty():
			_status_label.text = SettingsManager.text_for("key_conflict") % SettingsManager.text_for(BINDING_KEYS.get(existing, existing))
			_status_label.add_theme_color_override("font_color", AMBER)
			return
		var bindings: Dictionary = _working.get("key_bindings", {}).duplicate(true)
		bindings[_rebinding_action] = code
		_working["key_bindings"] = bindings
		_rebinding_action = ""
		_rebinding_button = null
		_preview_working()
		_build_category_content()
		_set_status(SettingsManager.text_for("binding_saved"), false)

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause") and _rebinding_action.is_empty():
		close(true)
		get_viewport().set_input_as_handled()

func _build_shell() -> void:
	var dimmer := ColorRect.new()
	dimmer.color = Color(0.012, 0.019, 0.024, 0.68)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	var title := Label.new()
	title.name = "GameTitle"
	title.text = "THE LAST\nLANTERN"
	title.anchor_left = 0.042
	title.anchor_top = 0.035
	title.anchor_right = 0.25
	title.anchor_bottom = 0.16
	title.add_theme_font_override("font", _serif)
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", PAPER)
	title.add_theme_constant_override("line_spacing", -5)
	add_child(title)

	var subtitle := Label.new()
	subtitle.name = "GameSubtitle"
	subtitle.anchor_left = 0.043
	subtitle.anchor_top = 0.17
	subtitle.anchor_right = 0.25
	subtitle.anchor_bottom = 0.205
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", Color("bdb9b1"))
	subtitle.add_theme_constant_override("character_spacing", 2)
	add_child(subtitle)

	_navigation = VBoxContainer.new()
	_navigation.name = "SettingsCategories"
	_navigation.anchor_left = 0.025
	_navigation.anchor_top = 0.285
	_navigation.anchor_right = 0.225
	_navigation.anchor_bottom = 0.75
	_navigation.add_theme_constant_override("separation", 9)
	add_child(_navigation)
	for category in CATEGORIES:
		var button := Button.new()
		button.name = category.capitalize() + "Category"
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.custom_minimum_size = Vector2(190, 44)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 15)
		button.add_theme_color_override("font_color", MUTED)
		button.add_theme_color_override("font_hover_color", PAPER)
		button.add_theme_color_override("font_focus_color", PAPER)
		button.add_theme_stylebox_override("normal", _flat_style(Color(0.015, 0.025, 0.032, 0.05), Color(0.65, 0.69, 0.72, 0.12), 0, 1))
		button.add_theme_stylebox_override("hover", _flat_style(Color(0.13, 0.08, 0.035, 0.38), Color(0.76, 0.48, 0.22, 0.45), 0, 1))
		button.add_theme_stylebox_override("focus", _flat_style(Color(0.13, 0.08, 0.035, 0.45), AMBER, 0, 1))
		button.pressed.connect(_select_category.bind(category))
		_navigation.add_child(button)
		_category_buttons[category] = button
	var nav_back := Button.new()
	nav_back.name = "NavBack"
	nav_back.focus_mode = Control.FOCUS_ALL
	nav_back.custom_minimum_size = Vector2(190, 44)
	nav_back.add_theme_font_size_override("font_size", 15)
	nav_back.add_theme_color_override("font_color", PAPER)
	nav_back.add_theme_stylebox_override("normal", _flat_style(Color(0.015, 0.025, 0.032, 0.05), Color(0.65, 0.69, 0.72, 0.12), 0, 1))
	nav_back.add_theme_stylebox_override("hover", _flat_style(Color(0.13, 0.08, 0.035, 0.38), AMBER, 0, 1))
	nav_back.pressed.connect(close.bind(true))
	_navigation.add_child(nav_back)

	_main_panel = PanelContainer.new()
	_main_panel.name = "OptionsPanel"
	_main_panel.anchor_left = 0.263
	_main_panel.anchor_top = 0.145
	_main_panel.anchor_right = 0.645
	_main_panel.anchor_bottom = 0.84
	_main_panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(_main_panel)
	var main_margin := MarginContainer.new()
	main_margin.add_theme_constant_override("margin_left", 18)
	main_margin.add_theme_constant_override("margin_right", 18)
	main_margin.add_theme_constant_override("margin_top", 14)
	main_margin.add_theme_constant_override("margin_bottom", 12)
	_main_panel.add_child(main_margin)
	var main_column := VBoxContainer.new()
	main_column.add_theme_constant_override("separation", 7)
	main_margin.add_child(main_column)
	var page_heading := Label.new()
	page_heading.name = "CategoryHeading"
	page_heading.add_theme_font_override("font", _serif)
	page_heading.add_theme_font_size_override("font_size", 19)
	page_heading.add_theme_color_override("font_color", PAPER)
	main_column.add_child(page_heading)
	var rule := ColorRect.new()
	rule.color = Color(0.76, 0.71, 0.63, 0.22)
	rule.custom_minimum_size.y = 1
	main_column.add_child(rule)
	var scroll := ScrollContainer.new()
	scroll.name = "OptionsScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_column.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 4)
	scroll.add_child(_content)
	_status_label = Label.new()
	_status_label.name = "SettingsStatus"
	_status_label.custom_minimum_size.y = 20
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", MUTED)
	main_column.add_child(_status_label)

	_guide_panel = PanelContainer.new()
	_guide_panel.name = "ControlsGuide"
	_guide_panel.anchor_left = 0.665
	_guide_panel.anchor_top = 0.19
	_guide_panel.anchor_right = 0.96
	_guide_panel.anchor_bottom = 0.79
	_guide_panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(_guide_panel)
	var guide_margin := MarginContainer.new()
	guide_margin.add_theme_constant_override("margin_left", 18)
	guide_margin.add_theme_constant_override("margin_right", 18)
	guide_margin.add_theme_constant_override("margin_top", 15)
	guide_margin.add_theme_constant_override("margin_bottom", 15)
	_guide_panel.add_child(guide_margin)
	_guide = VBoxContainer.new()
	_guide.add_theme_constant_override("separation", 8)
	guide_margin.add_child(_guide)

	_footer = HBoxContainer.new()
	_footer.anchor_left = 0.665
	_footer.anchor_top = 0.825
	_footer.anchor_right = 0.96
	_footer.anchor_bottom = 0.93
	_footer.add_theme_constant_override("separation", 8)
	add_child(_footer)

	_restore_dialog = ConfirmationDialog.new()
	_restore_dialog.title = "THE LAST LANTERN"
	_restore_dialog.confirmed.connect(_restore_defaults)
	add_child(_restore_dialog)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_footer.add_child(spacer)
	_restore_button = _make_action_button("restore_defaults", false)
	_restore_button.custom_minimum_size.x = 156
	_restore_button.pressed.connect(_restore_dialog.popup_centered)
	_footer.add_child(_restore_button)
	_apply_button = _make_action_button("apply", true)
	_apply_button.pressed.connect(_apply_changes)
	_footer.add_child(_apply_button)
	_footer_back_button = _make_action_button("back", false)
	_footer_back_button.pressed.connect(close.bind(true))
	_footer.add_child(_footer_back_button)

func _build_category_content() -> void:
	if _content == null:
		return
	for child in _content.get_children():
		child.queue_free()
	var heading := get_node_or_null("OptionsPanel/MarginContainer/VBoxContainer/CategoryHeading") as Label
	if heading != null:
		heading.text = SettingsManager.text_for(CATEGORY_KEYS[_active_category])
		heading.add_theme_font_override("font", _sans if String(SettingsManager.get_value("language", "English")) == "Arabic" else _serif)
	for category in _category_buttons:
		var button: Button = _category_buttons[category]
		button.text = SettingsManager.text_for(CATEGORY_KEYS[category])
		button.alignment = HORIZONTAL_ALIGNMENT_RIGHT if String(SettingsManager.get_value("language", "English")) == "Arabic" else HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_color_override("font_color", AMBER if category == _active_category else MUTED)
	get_node("SettingsCategories/NavBack").text = "←   " + SettingsManager.text_for("back")
	get_node("GameSubtitle").text = SettingsManager.text_for("subtitle")
	_apply_button.text = SettingsManager.text_for("apply")
	_restore_button.text = SettingsManager.text_for("restore_defaults")
	_footer_back_button.text = SettingsManager.text_for("back")
	_restore_dialog.dialog_text = SettingsManager.text_for("restore_question")
	_restore_dialog.ok_button_text = SettingsManager.text_for("confirm")
	_restore_dialog.cancel_button_text = SettingsManager.text_for("cancel")
	match _active_category:
		"GAMEPLAY": _build_gameplay_options()
		"GRAPHICS": _build_graphics_options()
		"AUDIO": _build_audio_options()
		"UI": _build_ui_options()
	_refresh_controls_overview()
	_apply_language_layout()
	call_deferred("_adjust_row_sizes")

func _select_category(category: String) -> void:
	if not CATEGORIES.has(category):
		return
	if _rebinding_action != "":
		_cancel_rebind()
	_active_category = category
	_build_category_content()

func _build_gameplay_options() -> void:
	_add_section_header("movement_camera")
	_add_static_row("movement_type", "%s  %s  %s  %s" % [_key("move_forward"), _key("move_left"), _key("move_backward"), _key("move_right")])
	_add_static_row("camera_mode", "first_person")
	_add_static_row("camera_rotation", "%s / %s · 360°" % [_key("camera_orbit_left"), _key("camera_orbit_right")])
	_add_slider_row("rotation_step", "camera_rotation_step", 10.0, 45.0, 1.0, "°")
	_add_toggle_row("mouse_control", "mouse_camera_control")
	_add_slider_row("mouse_sensitivity", "mouse_sensitivity", 0.1, 1.5, 0.05, "", "%.2f", not bool(_working.get("mouse_camera_control", false)))
	_add_toggle_row("invert_y", "invert_y", not bool(_working.get("mouse_camera_control", false)))
	_add_slider_row("fov", "field_of_view", 55.0, 95.0, 1.0, "°")
	_add_slider_row("camera_follow_speed", "camera_follow_speed", 0.2, 1.0, 0.05, "", "%.2f")
	_add_slider_row("camera_height", "camera_height", 1.0, 2.6, 0.1, " m", "%.1f")
	_add_slider_row("camera_distance", "camera_distance", 2.5, 7.0, 0.1, " m", "%.1f")
	_add_toggle_row("collision_avoidance", "camera_collision")
	_add_section_header("key_bindings")
	for action in SettingsManager.KEY_ACTIONS:
		_add_binding_row(action)
	_add_section_header("interaction")
	_add_slider_row("interaction_range", "interaction_range", 1.0, 4.0, 0.1, " m", "%.1f")
	_add_toggle_row("show_prompts", "show_interaction_prompts")

func _build_graphics_options() -> void:
	_add_section_header("display")
	_add_option_row("display_mode", "display_mode", ["Fullscreen", "Maximized", "Windowed"], false, {"Fullscreen": "fullscreen", "Maximized": "maximized", "Windowed": "windowed"})
	_add_option_row("resolution", "resolution", _available_resolutions(), String(_working.get("display_mode", "Maximized")) != "Windowed")
	_add_toggle_row("vsync", "vsync")
	_add_option_row("graphics_quality", "graphics_quality", ["Low", "Medium", "High"], false, {"Low": "low", "Medium": "medium", "High": "high"})
	_add_note("quality_note")
	_add_note("resolution_note")

func _build_audio_options() -> void:
	_add_section_header("audio_levels")
	_add_slider_row("master_volume", "master_volume", 0.0, 1.0, 0.01, "%", "%.0f", false, true)
	_add_slider_row("music_volume", "music_volume", 0.0, 1.0, 0.01, "%", "%.0f", false, true)
	_add_slider_row("sfx_volume", "sfx_volume", 0.0, 1.0, 0.01, "%", "%.0f", false, true)
	var preview := Button.new()
	preview.text = SettingsManager.text_for("preview_sound")
	preview.focus_mode = Control.FOCUS_ALL
	preview.pressed.connect(_play_audio_preview)
	_content.add_child(preview)
	_add_note("audio_note")

func _build_ui_options() -> void:
	_add_section_header("interface")
	_add_option_row("language", "language", ["English", "Arabic"], false, {"English": "language_english", "Arabic": "language_arabic"})
	_add_toggle_row("show_prompts", "show_interaction_prompts")
	_add_slider_row("ui_scale", "ui_scale", 0.8, 1.2, 0.05, "×", "%.2f")
	_add_note("language_note")

func _add_section_header(key: String) -> void:
	var label := Label.new()
	label.text = SettingsManager.text_for(key)
	label.custom_minimum_size.y = 27
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", _sans if String(SettingsManager.get_value("language", "English")) == "Arabic" else _serif)
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color("f4bd78"))
	_content.add_child(label)
	var divider := ColorRect.new()
	divider.color = Color(0.76, 0.71, 0.63, 0.16)
	divider.custom_minimum_size.y = 1
	_content.add_child(divider)

func _add_static_row(label_key: String, value_text: String) -> void:
	var row := _new_row(label_key)
	var value := Label.new()
	value.text = SettingsManager.text_for(value_text) if value_text == "first_person" else value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.custom_minimum_size.x = 142
	value.add_theme_color_override("font_color", PAPER)
	value.add_theme_font_size_override("font_size", 13)
	row.add_child(value)
	_content.add_child(row)

func _add_slider_row(label_key: String, key: String, minimum: float, maximum: float, step: float, suffix: String, number_format: String = "%.1f", disabled: bool = false, percent: bool = false) -> void:
	var row := _new_row(label_key)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = float(_working.get(key, minimum))
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.x = 84
	slider.focus_mode = Control.FOCUS_ALL
	slider.editable = not disabled
	var value_label := Label.new()
	value_label.custom_minimum_size.x = 42
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 12)
	value_label.add_theme_color_override("font_color", PAPER)
	value_label.text = _format_slider(slider.value, suffix, number_format, percent)
	slider.value_changed.connect(func(value: float) -> void:
		_working[key] = value
		value_label.text = _format_slider(value, suffix, number_format, percent)
		_preview_working()
	)
	row.add_child(slider)
	row.add_child(value_label)
	_content.add_child(row)

func _add_toggle_row(label_key: String, key: String, disabled: bool = false) -> void:
	var row := _new_row(label_key)
	var toggle := CheckButton.new()
	toggle.button_pressed = bool(_working.get(key, false))
	toggle.text = SettingsManager.text_for("on") if toggle.button_pressed else SettingsManager.text_for("off")
	toggle.custom_minimum_size.x = 80
	toggle.focus_mode = Control.FOCUS_ALL
	toggle.disabled = disabled
	toggle.toggled.connect(func(enabled: bool) -> void:
		_working[key] = enabled
		toggle.text = SettingsManager.text_for("on") if enabled else SettingsManager.text_for("off")
		_preview_working()
		if key == "mouse_camera_control":
			_build_category_content()
	)
	row.add_child(toggle)
	_content.add_child(row)

func _add_option_row(label_key: String, key: String, choices: Array, disabled: bool = false, translation_keys: Dictionary = {}) -> void:
	var row := _new_row(label_key)
	var option := OptionButton.new()
	option.custom_minimum_size.x = 135
	option.size_flags_horizontal = Control.SIZE_SHRINK_END
	option.focus_mode = Control.FOCUS_ALL
	option.disabled = disabled
	for choice in choices:
		var internal := String(choice)
		var display_key := String(translation_keys.get(internal, ""))
		option.add_item(SettingsManager.text_for(display_key) if not display_key.is_empty() else internal)
		option.set_item_metadata(option.item_count - 1, internal)
		if internal == String(_working.get(key, "")):
			option.select(option.item_count - 1)
	if option.selected < 0 and option.item_count > 0:
		option.select(0)
		if key == "resolution":
			_working[key] = String(option.get_item_metadata(0))
	option.item_selected.connect(func(index: int) -> void:
		var internal := String(option.get_item_metadata(index))
		_working[key] = internal
		_preview_working()
		if key in ["display_mode", "language"]:
			_build_category_content()
	)
	row.add_child(option)
	_content.add_child(row)

func _add_binding_row(action: String) -> void:
	var row := _new_row(BINDING_KEYS[action])
	var button := Button.new()
	button.name = "Binding_" + action
	button.text = SettingsManager.get_key_label(action)
	button.custom_minimum_size.x = 106
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(_begin_rebind.bind(action, button))
	row.add_child(button)
	_content.add_child(row)

func _add_note(key: String) -> void:
	var label := Label.new()
	label.text = SettingsManager.text_for(key)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(0, 44)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", MUTED)
	_content.add_child(label)

func _new_row(label_key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 30
	row.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = SettingsManager.text_for(label_key)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size.x = 128
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", _sans)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", PAPER)
	row.add_child(label)
	return row

func _adjust_row_sizes() -> void:
	if _content == null:
		return
	var width := get_viewport_rect().size.x
	for row in _content.get_children():
		if row is not HBoxContainer:
			continue
		var first := row.get_child(0) if row.get_child_count() > 0 else null
		if first is Label:
			first.custom_minimum_size.x = clampf(width * 0.13, 120.0, 168.0)
		for child in row.get_children():
			if child is HSlider:
				child.custom_minimum_size.x = clampf(width * 0.072, 78.0, 108.0)
			elif child is OptionButton:
				child.custom_minimum_size.x = clampf(width * 0.102, 110.0, 142.0)

func _refresh_controls_overview() -> void:
	for child in _guide.get_children():
		child.queue_free()
	var heading := Label.new()
	heading.text = SettingsManager.text_for("controls_overview")
	heading.add_theme_font_override("font", _sans if String(SettingsManager.get_value("language", "English")) == "Arabic" else _serif)
	heading.add_theme_font_size_override("font_size", 16)
	heading.add_theme_color_override("font_color", PAPER)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if String(SettingsManager.get_value("language", "English")) == "Arabic" else HORIZONTAL_ALIGNMENT_LEFT
	_guide.add_child(heading)
	_add_guide_section("camera_behavior", "%s / %s   ·   360°\n%s" % [_key("camera_orbit_left"), _key("camera_orbit_right"), SettingsManager.text_for("camera_guide")])
	_add_guide_section("movement_camera", "%s  %s  %s  %s   ·   %s" % [_key("move_forward"), _key("move_left"), _key("move_backward"), _key("move_right"), SettingsManager.text_for("movement_guide")])
	_add_guide_section("interaction", "%s   ·   %s" % [_key("interact"), SettingsManager.text_for("interaction_guide")])
	_add_guide_section("menu_guide", "Esc   ·   %s" % SettingsManager.text_for("menu_guide"))
	var note := Label.new()
	note.text = SettingsManager.text_for("mouse_guide")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.size_flags_vertical = Control.SIZE_EXPAND_FILL
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", MUTED)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if String(SettingsManager.get_value("language", "English")) == "Arabic" else HORIZONTAL_ALIGNMENT_LEFT
	_guide.add_child(note)

func _add_guide_section(title_key: String, content_text: String) -> void:
	var title := Label.new()
	title.text = SettingsManager.text_for(title_key)
	var arabic := String(SettingsManager.get_value("language", "English")) == "Arabic"
	title.add_theme_font_override("font", _sans if arabic else _serif)
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color("d3ba9a"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if arabic else HORIZONTAL_ALIGNMENT_LEFT
	_guide.add_child(title)
	var content := Label.new()
	content.text = content_text
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.custom_minimum_size.y = 40
	content.add_theme_font_override("font", _sans)
	content.add_theme_font_size_override("font_size", 12)
	content.add_theme_color_override("font_color", PAPER)
	content.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if arabic else HORIZONTAL_ALIGNMENT_LEFT
	_guide.add_child(content)
	var divider := ColorRect.new()
	divider.color = Color(0.76, 0.71, 0.63, 0.13)
	divider.custom_minimum_size.y = 1
	_guide.add_child(divider)

func _begin_rebind(action: String, button: Button) -> void:
	_rebinding_action = action
	_rebinding_button = button
	button.text = SettingsManager.text_for("press_key")
	_status_label.text = SettingsManager.text_for("cancel_rebind")
	_status_label.add_theme_color_override("font_color", AMBER)

func _cancel_rebind() -> void:
	_rebinding_action = ""
	_rebinding_button = null
	_build_category_content()
	_set_status("", false)

func _find_binding_conflict(code: int, except_action: String) -> String:
	var bindings: Dictionary = _working.get("key_bindings", {})
	for action in SettingsManager.KEY_ACTIONS:
		if action != except_action and int(bindings.get(action, -1)) == code:
			return action
	return ""

func _key(action: String) -> String:
	return SettingsManager.get_key_label(action)

func _available_resolutions() -> Array:
	var screen := DisplayServer.screen_get_size()
	var candidates := [Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1440, 810), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]
	var choices: Array = []
	for size in candidates:
		if size.x <= screen.x and size.y <= screen.y:
			choices.append("%dx%d" % [size.x, size.y])
	if choices.is_empty():
		choices.append("%dx%d" % [maxi(screen.x, 640), maxi(screen.y, 360)])
	var current := String(_working.get("resolution", "1440x810"))
	var current_parts := current.split("x")
	if not choices.has(current) and current_parts.size() == 2 and int(current_parts[0]) <= screen.x and int(current_parts[1]) <= screen.y:
		choices.append(current)
	return choices

func _preview_working() -> void:
	SettingsManager.preview_values(_working)
	_working = SettingsManager.get_values_copy()

func _apply_changes() -> void:
	var saved: bool = SettingsManager.apply_values(_working, true)
	_working = SettingsManager.get_values_copy()
	_apply_button.text = SettingsManager.text_for("applied") if saved else SettingsManager.text_for("save_failed")
	_set_status(SettingsManager.text_for("applied") if saved else SettingsManager.text_for("save_failed"), not saved)
	_apply_button.grab_focus()
	var timer := get_tree().create_timer(1.2)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(_apply_button):
			_apply_button.text = SettingsManager.text_for("apply")
	)

func _restore_defaults() -> void:
	_working = SettingsManager.get_default_values_copy()
	_rebinding_action = ""
	_preview_working()
	_build_category_content()
	_set_status(SettingsManager.text_for("defaults_restored"), false)

func _set_status(message: String, warning: bool) -> void:
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", AMBER if warning else MUTED)

func _apply_language_layout() -> void:
	var arabic := String(SettingsManager.get_value("language", "English")) == "Arabic"
	var direction := Control.LAYOUT_DIRECTION_RTL if arabic else Control.LAYOUT_DIRECTION_LTR
	layout_direction = direction
	_navigation.layout_direction = direction
	_main_panel.layout_direction = direction
	_guide_panel.layout_direction = direction
	_footer.layout_direction = direction
	var title := get_node_or_null("GameTitle") as Label
	var subtitle := get_node_or_null("GameSubtitle") as Label
	if arabic:
		_navigation.anchor_left = 0.775
		_navigation.anchor_right = 0.975
		_main_panel.anchor_left = 0.355
		_main_panel.anchor_right = 0.737
		_guide_panel.anchor_left = 0.04
		_guide_panel.anchor_right = 0.335
		_footer.anchor_left = 0.04
		_footer.anchor_right = 0.335
	else:
		_navigation.anchor_left = 0.025
		_navigation.anchor_right = 0.225
		_main_panel.anchor_left = 0.263
		_main_panel.anchor_right = 0.645
		_guide_panel.anchor_left = 0.665
		_guide_panel.anchor_right = 0.96
		_footer.anchor_left = 0.665
		_footer.anchor_right = 0.96
	if title != null:
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if arabic else HORIZONTAL_ALIGNMENT_LEFT
		title.anchor_left = 0.70 if arabic else 0.042
		title.anchor_right = 0.96 if arabic else 0.25
	if subtitle != null:
		subtitle.text = SettingsManager.text_for("subtitle")
		subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if arabic else HORIZONTAL_ALIGNMENT_LEFT
		subtitle.anchor_left = 0.70 if arabic else 0.043
		subtitle.anchor_right = 0.96 if arabic else 0.25
	for control in [title, subtitle, _content, _status_label]:
		if control != null:
			control.add_theme_font_override("font", _sans if arabic else _serif)
	for child in _content.get_children():
		if child is Label:
			child.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if arabic else HORIZONTAL_ALIGNMENT_LEFT
		if child is HBoxContainer and child.get_child_count() > 0 and child.get_child(0) is Label:
			child.get_child(0).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if arabic else HORIZONTAL_ALIGNMENT_LEFT
func _play_audio_preview() -> void:
	var sample_rate := 22050
	var duration := 0.18
	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index in sample_count:
		var time := float(index) / float(sample_rate)
		var envelope := exp(-11.0 * time) * minf(time * 90.0, 1.0)
		var sample := int(sin(TAU * (620.0 + 280.0 * time) * time) * envelope * 4200.0)
		data[index * 2] = sample & 0xff
		data[index * 2 + 1] = (sample >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	var player := AudioStreamPlayer.new()
	player.name = "UIAudioPreview"
	player.bus = "SFX"
	player.stream = stream
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func _format_slider(value: float, suffix: String, number_format: String, percent: bool) -> String:
	var shown := value * 100.0 if percent else value
	return (number_format % shown) + suffix

func _make_action_button(key: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = SettingsManager.text_for(key)
	button.custom_minimum_size = Vector2(112, 40)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", _sans if String(SettingsManager.get_value("language", "English")) == "Arabic" else _serif)
	button.add_theme_font_size_override("font_size", 14)
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
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	return style
