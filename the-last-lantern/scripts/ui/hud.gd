extends Control

var _lantern_count: Label
var _prompt_panel: PanelContainer
var _prompt_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_create_counter()
	_create_objective()
	_create_prompt()

func set_lantern_count(count: int, total: int = 4) -> void:
	if is_instance_valid(_lantern_count):
		_lantern_count.text = "LANTERNS   %d / %d" % [count, total]

func set_interaction_prompt(text: String) -> void:
	if not is_instance_valid(_prompt_panel):
		return
	_prompt_label.text = text.to_upper()
	_prompt_panel.visible = not text.is_empty()

func _create_counter() -> void:
	_lantern_count = Label.new()
	_lantern_count.text = "LANTERNS   0 / 4"
	_lantern_count.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_lantern_count.anchor_left = 0.035
	_lantern_count.anchor_top = 0.035
	_lantern_count.offset_right = 240.0
	_lantern_count.offset_bottom = 28.0
	_lantern_count.add_theme_font_size_override("font_size", 14)
	_lantern_count.add_theme_color_override("font_color", Color("e8e2d9"))
	_lantern_count.add_theme_constant_override("character_spacing", 2)
	add_child(_lantern_count)

func _create_objective() -> void:
	var objective := Label.new()
	objective.text = "WALK THE STONE PATH  ·  FIND THE FIRST LIGHT"
	objective.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	objective.anchor_left = 0.53
	objective.anchor_top = 0.91
	objective.anchor_right = 0.97
	objective.anchor_bottom = 0.96
	objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	objective.add_theme_font_size_override("font_size", 13)
	objective.add_theme_color_override("font_color", Color("d7d8d5"))
	add_child(objective)

func _create_prompt() -> void:
	_prompt_panel = PanelContainer.new()
	_prompt_panel.name = "InteractionPrompt"
	_prompt_panel.visible = false
	_prompt_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_panel.anchor_left = 0.35
	_prompt_panel.anchor_right = 0.65
	_prompt_panel.anchor_top = 0.83
	_prompt_panel.anchor_bottom = 0.9
	_prompt_panel.add_theme_stylebox_override("panel", _prompt_style())
	add_child(_prompt_panel)
	_prompt_label = Label.new()
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_font_size_override("font_size", 15)
	_prompt_label.add_theme_color_override("font_color", Color("ffe2be"))
	_prompt_panel.add_child(_prompt_label)

func _prompt_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.006, 0.012, 0.016, 0.86)
	style.border_color = Color(0.81, 0.49, 0.22, 0.68)
	style.set_border_width_all(1)
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 9.0
	style.content_margin_bottom = 9.0
	return style
