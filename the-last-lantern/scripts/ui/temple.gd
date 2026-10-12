extends Node3D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const PAUSE_SCENE := preload("res://scenes/ui/pause_menu.tscn")
const PUZZLE_INTERACTABLE := preload("res://scripts/world/temple_puzzle_interactable.gd")
const JAPANESE_HOUSE_SCENE := preload("res://assets/models/props/old_house.glb")
const MENU_SCENE := "res://scenes/main_menu.tscn"
const MENU_BACKGROUND := preload("res://assets/ui/menu_forest_background.png")
const TEMPLE_AMBIENCE := preload("res://assets/audio/AMB_Temple_Drone.ogg")
const WHISPERS: Array[AudioStream] = [
	preload("res://assets/audio/SFX_Distant_Whisper_01.ogg"),
	preload("res://assets/audio/SFX_Distant_Whisper_02.ogg"),
	preload("res://assets/audio/SFX_Distant_Whisper_03.ogg"),
	preload("res://assets/audio/SFX_Distant_Whisper_04.ogg"),
]
const SYMBOL_NAME_KEYS: PackedStringArray = ["symbol_moon", "symbol_eye", "symbol_tree", "symbol_sun"]
const SYMBOL_MARKS: PackedStringArray = ["○", "◎", "△", "◇"]
const AMBER := Color("e8a45b")
const PAPER := Color("e8e2d9")

var _player: CharacterBody3D
var _hud: Control
var _pause_menu: Control
var _fade: ColorRect
var _puzzle_overlay: Control
var _ending_overlay: Control
var _sequence_label: Label
var _status_label: Label
var _door_left: Node3D
var _door_right: Node3D
var _door_bodies: Array[StaticBody3D] = []
var _final_room: Node3D
var _final_light: OmniLight3D
var _final_glass_material: StandardMaterial3D
var _symbol_buttons: Array[Button] = []
var _symbol_world_labels: Array[Label3D] = []
var _lantern_order: Array[int] = []
var _puzzle_step := 0
var _puzzle_status_key := "puzzle_choose"
var _puzzle_title: Label
var _puzzle_description: Label
var _puzzle_back: Button
var _ending_title: Label
var _ending_subtitle: Label
var _ending_story: Label
var _ending_menu_button: Button
var _ui_sans: SystemFont
var _ui_serif: SystemFont
var _is_solved := false
var _transitioning := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_ui_sans = SystemFont.new()
	_ui_sans.font_names = PackedStringArray(["Segoe UI", "Arial"])
	_ui_serif = SystemFont.new()
	_ui_serif.font_names = PackedStringArray(["Georgia", "Times New Roman"])
	_lantern_order = GameProgress.get_lantern_order()
	if _lantern_order.size() != 4:
		_lantern_order = [0, 1, 2, 3]
	_build_atmosphere()
	_build_temple_hall()
	_build_symbol_wall()
	_start_ambience()
	_player = PLAYER_SCENE.instantiate() as CharacterBody3D
	_player.name = "Player"
	# Spawn fully inside the hall so the third-person camera starts past the entrance wall.
	_player.position = Vector3(0.0, 0.02, -1.8)
	add_child(_player)
	_player.interaction_prompt_changed.connect(_on_interaction_prompt_changed)
	_create_ui()
	_hud.call("set_lantern_count", 4)
	_hud.call("set_objective", "objective_temple")
	SettingsManager.settings_changed.connect(_refresh_language)
	_refresh_language(SettingsManager.get_values_copy())
	_fade.color.a = 1.0
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 0.0, 1.0)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause") or get_tree().paused:
		return
	if _puzzle_overlay.visible:
		_close_puzzle()
	else:
		_pause_menu.call("open")
	get_viewport().set_input_as_handled()

func _build_atmosphere() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("07090d")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("75634f")
	environment.ambient_light_energy = 0.42
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color("211f20")
	environment.fog_density = 0.008
	world.environment = environment
	add_child(world)
	var moonlight := DirectionalLight3D.new()
	moonlight.name = "TempleMoonlight"
	moonlight.light_color = Color("8da6c0")
	moonlight.light_energy = 0.16
	moonlight.rotation_degrees = Vector3(-32.0, -22.0, 0.0)
	moonlight.shadow_enabled = false
	add_child(moonlight)

func _build_temple_hall() -> void:
	var dark_wood := _material(Color("211914"), 0.93)
	var aged_wood := _material(Color("38291f"), 0.9)
	var stone := _material(Color("353536"), 0.96)
	var floor := _material(Color("282320"), 0.9)
	var screen_paper := _material(Color("554835"), 0.97)
	_solid_box("TempleFloor", Vector3(0.0, -0.2, -5.5), Vector3(14.0, 0.4, 23.0), floor)
	_solid_box("TempleLeftWall", Vector3(-7.0, 3.0, -5.5), Vector3(0.45, 6.0, 23.0), dark_wood)
	_solid_box("TempleRightWall", Vector3(7.0, 3.0, -5.5), Vector3(0.45, 6.0, 23.0), dark_wood)
	# Leave a real 4.2 m doorway in the back wall for the final double door.
	_solid_box("TempleBackWallLeft", Vector3(-4.6, 3.0, -17.0), Vector3(4.8, 6.0, 0.45), dark_wood)
	_solid_box("TempleBackWallRight", Vector3(4.6, 3.0, -17.0), Vector3(4.8, 6.0, 0.45), dark_wood)
	_solid_box("EntranceWallLeft", Vector3(-5.15, 3.0, 6.0), Vector3(3.7, 6.0, 0.45), dark_wood)
	_solid_box("EntranceWallRight", Vector3(5.15, 3.0, 6.0), Vector3(3.7, 6.0, 0.45), dark_wood)
	var exterior := JAPANESE_HOUSE_SCENE.instantiate() as Node3D
	exterior.name = "JapaneseTempleHouseExterior"
	exterior.scale = Vector3.ONE * 0.72
	add_child(exterior)
	_place_model_base_centered(exterior, Vector3(0.0, 0.0, 12.5))
	_disable_model_shadows(exterior)
	var ceiling := MeshInstance3D.new()
	ceiling.name = "TempleCeiling"
	var ceiling_mesh := BoxMesh.new()
	ceiling_mesh.size = Vector3(14.2, 0.5, 23.0)
	ceiling.mesh = ceiling_mesh
	ceiling.material_override = dark_wood
	ceiling.position = Vector3(0.0, 6.2, -5.5)
	ceiling.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ceiling)
	for x in [-5.5, -2.8, 0.0, 2.8, 5.5]:
		_solid_box("TimberPillar", Vector3(x, 2.7, 3.2), Vector3(0.38, 5.4, 0.38), aged_wood)
		_solid_box("PillarFoot", Vector3(x, 0.22, 3.2), Vector3(0.64, 0.44, 0.64), stone)
	_solid_box("EntranceBeam", Vector3(0.0, 5.65, 3.2), Vector3(12.3, 0.52, 0.58), aged_wood)
	_solid_box("HallCrossBeam", Vector3(0.0, 5.75, -5.5), Vector3(13.5, 0.55, 0.8), aged_wood)
	var roof := MeshInstance3D.new()
	roof.name = "TempleRoofInterior"
	var roof_mesh := PrismMesh.new()
	roof_mesh.size = Vector3(15.5, 1.65, 24.0)
	roof.mesh = roof_mesh
	roof.material_override = _material(Color("17191b"), 0.9)
	roof.position = Vector3(0.0, 7.0, -5.5)
	roof.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(roof)
	_build_temple_shoji(aged_wood, screen_paper)
	# A plain wooden double door and warm light provide the final focal point.
	_door_left = _make_door_leaf("FinalDoorLeft", -2.1, aged_wood)
	_door_right = _make_door_leaf("FinalDoorRight", 2.1, aged_wood)
	var exit_light := OmniLight3D.new()
	exit_light.name = "LightBeyondFinalDoor"
	exit_light.position = Vector3(0.0, 2.0, -18.2)
	exit_light.light_color = Color("ffb66b")
	exit_light.light_energy = 0.0
	exit_light.omni_range = 10.0
	exit_light.shadow_enabled = false
	add_child(exit_light)
	set_meta("exit_light", exit_light)
	_build_final_room(aged_wood, stone)
	# A few warm lamps are enough to keep the hall readable on a low-end PC.
	for x in [-5.6, 5.6]:
		var lamp := OmniLight3D.new()
		lamp.name = "TempleWallLamp"
		lamp.position = Vector3(x, 2.8, -5.0)
		lamp.light_color = Color("d88a45")
		lamp.light_energy = 0.72
		lamp.omni_range = 7.0
		lamp.shadow_enabled = false
		add_child(lamp)

func _build_temple_shoji(wood: Material, paper: Material) -> void:
	# Japanese timber and paper-screen details; the puzzle marks remain abstract and non-religious.
	for side in [-1.0, 1.0]:
		for panel_index in range(4):
			var z := -0.8 - panel_index * 4.1
			var face_x: float = float(side) * 6.73
			_decorative_box("ShojiPaperScreen", Vector3(face_x, 2.6, z), Vector3(0.035, 2.2, 2.72), paper, self)
			for y in [1.48, 3.72]:
				_decorative_box("ShojiHorizontalFrame", Vector3(face_x + side * 0.025, y, z), Vector3(0.085, 0.09, 2.88), wood, self)
			for offset in [-1.38, 0.0, 1.38]:
				_decorative_box("ShojiVerticalFrame", Vector3(face_x + side * 0.025, 2.6, z + offset), Vector3(0.085, 2.34, 0.09), wood, self)
			for y in [2.22, 2.98]:
				_decorative_box("ShojiLattice", Vector3(face_x + side * 0.03, y, z), Vector3(0.07, 0.055, 2.72), wood, self)

func _place_model_base_centered(model: Node3D, base_point: Vector3) -> void:
	var inverse := model.global_transform.affine_inverse()
	var bounds := AABB()
	var has_bounds := false
	for candidate in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := candidate as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var mesh_bounds := inverse * mesh_instance.global_transform * mesh_instance.get_aabb()
		if has_bounds:
			bounds = bounds.merge(mesh_bounds)
		else:
			bounds = mesh_bounds
			has_bounds = true
	if not has_bounds:
		model.position = base_point
		return
	var model_scale := model.scale
	model.position = base_point - Vector3(
		bounds.get_center().x * model_scale.x,
		bounds.position.y * model_scale.y,
		bounds.get_center().z * model_scale.z
	)

func _disable_model_shadows(node: Node) -> void:
	for child in node.get_children():
		if child is GeometryInstance3D:
			child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_disable_model_shadows(child)

func _build_final_room(aged_wood: Material, stone: Material) -> void:
	_final_room = Node3D.new()
	_final_room.name = "FinalLanternRoom"
	add_child(_final_room)
	_solid_box("FinalRoomFloor", Vector3(0.0, -0.2, -21.0), Vector3(12.0, 0.4, 8.0), stone, _final_room)
	_solid_box("FinalRoomLeftWall", Vector3(-6.0, 2.5, -21.0), Vector3(0.35, 5.0, 8.0), aged_wood, _final_room)
	_solid_box("FinalRoomRightWall", Vector3(6.0, 2.5, -21.0), Vector3(0.35, 5.0, 8.0), aged_wood, _final_room)
	_solid_box("FinalRoomBackWall", Vector3(0.0, 2.5, -25.0), Vector3(12.0, 5.0, 0.35), aged_wood, _final_room)
	_solid_box("FinalRoomCeiling", Vector3(0.0, 5.1, -21.0), Vector3(12.0, 0.3, 8.0), aged_wood, _final_room)
	# A large, purely decorative lantern is the final visual; no altar or religious props.
	_decorative_box("GiantLanternBase", Vector3(0.0, 0.2, -21.6), Vector3(2.4, 0.4, 2.4), stone, _final_room)
	var stem := MeshInstance3D.new()
	stem.name = "GiantLanternStem"
	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.28
	stem_mesh.bottom_radius = 0.42
	stem_mesh.height = 1.45
	stem_mesh.radial_segments = 8
	stem.mesh = stem_mesh
	stem.material_override = aged_wood
	stem.position = Vector3(0.0, 1.1, -21.6)
	_final_room.add_child(stem)
	_decorative_box("GiantLanternFootCap", Vector3(0.0, 1.8, -21.6), Vector3(1.8, 0.18, 1.8), stone, _final_room)
	_final_glass_material = _material(Color("4a3321"), 0.4, Color("ff9c4b"), 0.15)
	_decorative_box("GiantLanternGlass", Vector3(0.0, 2.65, -21.6), Vector3(1.22, 1.45, 1.22), _final_glass_material, _final_room)
	for offset in [-0.57, 0.57]:
		_decorative_box("GiantLanternFrame", Vector3(offset, 2.65, -20.98), Vector3(0.09, 1.55, 0.09), aged_wood, _final_room)
		_decorative_box("GiantLanternFrame", Vector3(offset, 2.65, -22.22), Vector3(0.09, 1.55, 0.09), aged_wood, _final_room)
	_decorative_box("GiantLanternRoof", Vector3(0.0, 3.45, -21.6), Vector3(2.1, 0.24, 2.1), aged_wood, _final_room)
	_final_light = OmniLight3D.new()
	_final_light.name = "GiantLanternLight"
	_final_light.position = Vector3(0.0, 2.65, -21.6)
	_final_light.light_color = Color("ff9e51")
	_final_light.light_energy = 0.0
	_final_light.omni_range = 14.0
	_final_light.shadow_enabled = false
	_final_room.add_child(_final_light)
	# Restrained timber trim and stone bands add age without religious markings.
	for y in [0.45, 4.5]:
		_decorative_box("FinalRoomTimberTrim", Vector3(0.0, y, -24.76), Vector3(10.4, 0.12, 0.08), stone, _final_room)

func _make_door_leaf(leaf_name: String, hinge_x: float, material: Material) -> Node3D:
	var hinge := Node3D.new()
	hinge.name = leaf_name
	hinge.position = Vector3(hinge_x, 0.0, -16.7)
	add_child(hinge)
	var body := StaticBody3D.new()
	body.name = "DoorCollision"
	body.position = Vector3(-signf(hinge_x) * 1.05, 2.15, 0.0)
	hinge.add_child(body)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.1, 4.3, 0.35)
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	collision.shape = shape
	body.add_child(collision)
	_door_bodies.append(body)
	return hinge

func _build_symbol_wall() -> void:
	var stone := _material(Color("42403b"), 0.94)
	var trim := _material(Color("78603e"), 0.86, Color("c18243"), 0.22)
	for index in SYMBOL_NAME_KEYS.size():
		var x := -4.65 + float(index) * 3.1
		var plaque := MeshInstance3D.new()
		plaque.name = "SymbolPlaque_%02d" % index
		var mesh := BoxMesh.new()
		mesh.size = Vector3(2.35, 2.4, 0.28)
		plaque.mesh = mesh
		plaque.material_override = stone
		plaque.position = Vector3(x, 3.3, -16.57)
		add_child(plaque)
		var label := Label3D.new()
		label.text = SYMBOL_MARKS[index] + "\n" + _symbol_name(index)
		label.font = _ui_sans
		label.font_size = 30
		label.pixel_size = 0.004
		label.modulate = Color("efd2a2")
		label.position = Vector3(x, 3.3, -16.39)
		add_child(label)
		_symbol_world_labels.append(label)
		var edge := MeshInstance3D.new()
		var edge_mesh := BoxMesh.new()
		edge_mesh.size = Vector3(2.5, 2.55, 0.08)
		edge.mesh = edge_mesh
		edge.material_override = trim
		edge.position = Vector3(x, 3.3, -16.66)
		edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(edge)
	# The player must approach the wall and press F before the sequence interface appears.
	var interaction := PUZZLE_INTERACTABLE.new() as Area3D
	interaction.name = "SymbolWallInteraction"
	interaction.position = Vector3(0.0, 1.35, -14.45)
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 2.1
	collision.shape = sphere
	interaction.add_child(collision)
	interaction.activated.connect(_open_puzzle)
	add_child(interaction)
	var pad := MeshInstance3D.new()
	pad.name = "PuzzleStandingStone"
	var pad_mesh := BoxMesh.new()
	pad_mesh.size = Vector3(2.8, 0.12, 1.3)
	pad.mesh = pad_mesh
	pad.material_override = stone
	pad.position = Vector3(0.0, -0.03, -14.25)
	add_child(pad)

func _create_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "TempleUI"
	canvas.layer = 10
	add_child(canvas)
	_hud = HUD_SCENE.instantiate()
	canvas.add_child(_hud)
	_puzzle_overlay = _build_puzzle_overlay()
	_puzzle_overlay.visible = false
	canvas.add_child(_puzzle_overlay)
	_ending_overlay = _build_ending_overlay()
	_ending_overlay.visible = false
	canvas.add_child(_ending_overlay)
	_pause_menu = PAUSE_SCENE.instantiate()
	_pause_menu.visible = false
	_pause_menu.resume_requested.connect(_on_game_resumed)
	_pause_menu.main_menu_requested.connect(_return_to_main_menu)
	canvas.add_child(_pause_menu)
	_fade = ColorRect.new()
	_fade.name = "SceneFade"
	_fade.color = Color(0.0, 0.0, 0.0, 1.0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(_fade)

func _build_puzzle_overlay() -> Control:
	var overlay := Control.new()
	overlay.name = "SymbolPuzzleOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.003, 0.006, 0.009, 0.88)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.anchor_left = 0.21
	panel.anchor_top = 0.25
	panel.anchor_right = 0.79
	panel.anchor_bottom = 0.77
	panel.add_theme_stylebox_override("panel", _panel_style())
	overlay.add_child(panel)
	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 18)
	panel.add_child(layout)
	var title := Label.new()
	title.name = "PuzzleTitle"
	title.text = SettingsManager.text_for("puzzle_title")
	_puzzle_title = title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_color_override("font_color", PAPER)
	layout.add_child(title)
	var description := Label.new()
	description.text = SettingsManager.text_for("puzzle_description")
	_puzzle_description = description
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 16)
	description.add_theme_color_override("font_color", Color("c8c4bd"))
	layout.add_child(description)
	_sequence_label = Label.new()
	_sequence_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sequence_label.add_theme_font_size_override("font_size", 19)
	_sequence_label.add_theme_color_override("font_color", AMBER)
	layout.add_child(_sequence_label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	layout.add_child(row)
	for index in SYMBOL_NAME_KEYS.size():
		var button := Button.new()
		button.text = SYMBOL_MARKS[index] + "\n" + _symbol_name(index)
		button.custom_minimum_size = Vector2(126.0, 92.0)
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_font_size_override("font_size", 17)
		button.add_theme_color_override("font_color", PAPER)
		button.add_theme_color_override("font_hover_color", AMBER)
		button.add_theme_stylebox_override("normal", _button_style(false))
		button.add_theme_stylebox_override("hover", _button_style(true))
		button.add_theme_stylebox_override("focus", _button_style(true))
		button.pressed.connect(_on_symbol_selected.bind(index))
		row.add_child(button)
		_symbol_buttons.append(button)
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(footer)
	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", Color("c8c4bd"))
	footer.add_child(_status_label)
	var back := Button.new()
	back.text = SettingsManager.text_for("back")
	_puzzle_back = back
	back.custom_minimum_size = Vector2(140, 40)
	back.pressed.connect(_close_puzzle)
	layout.add_child(back)
	_refresh_sequence_label()
	return overlay

func _build_ending_overlay() -> Control:
	var overlay := Control.new()
	overlay.name = "EndingOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var background := TextureRect.new()
	background.name = "MenuForestEndingBackground"
	background.texture = MENU_BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(background)
	var dim := ColorRect.new()
	dim.color = Color(0.004, 0.006, 0.009, 0.52)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)
	var text_scrim := ColorRect.new()
	text_scrim.name = "EndingTextScrim"
	text_scrim.color = Color(0.003, 0.006, 0.01, 0.42)
	text_scrim.anchor_left = 0.0
	text_scrim.anchor_top = 0.0
	text_scrim.anchor_right = 0.56
	text_scrim.anchor_bottom = 1.0
	text_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(text_scrim)
	var layout := VBoxContainer.new()
	layout.anchor_left = 0.075
	layout.anchor_top = 0.22
	layout.anchor_right = 0.48
	layout.anchor_bottom = 0.78
	layout.offset_left = 0.0
	layout.offset_top = 0.0
	layout.offset_right = 0.0
	layout.offset_bottom = 0.0
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 14)
	overlay.add_child(layout)
	var brand := Label.new()
	brand.text = "THE LAST\nLANTERN"
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	brand.add_theme_font_size_override("font_size", 43)
	brand.add_theme_color_override("font_color", PAPER)
	layout.add_child(brand)
	var subtitle := Label.new()
	subtitle.text = "FOUR LANTERNS. ONE WAY OUT."
	_ending_subtitle = subtitle
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color("d2cbc0"))
	layout.add_child(subtitle)
	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(260.0, 1.0)
	divider.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	divider.color = Color(0.91, 0.58, 0.28, 0.72)
	layout.add_child(divider)
	var title := Label.new()
	title.text = SettingsManager.text_for("ending_title")
	_ending_title = title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", PAPER)
	layout.add_child(title)
	var story := Label.new()
	story.text = SettingsManager.text_for("ending_story")
	_ending_story = story
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	story.add_theme_font_size_override("font_size", 17)
	story.add_theme_color_override("font_color", AMBER)
	layout.add_child(story)
	var menu_button := Button.new()
	menu_button.text = SettingsManager.text_for("return_menu")
	_ending_menu_button = menu_button
	menu_button.custom_minimum_size = Vector2(300.0, 52.0)
	menu_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	menu_button.focus_mode = Control.FOCUS_ALL
	menu_button.add_theme_font_size_override("font_size", 18)
	menu_button.add_theme_color_override("font_color", PAPER)
	menu_button.add_theme_color_override("font_hover_color", AMBER)
	menu_button.add_theme_stylebox_override("normal", _button_style(false))
	menu_button.add_theme_stylebox_override("hover", _button_style(true))
	menu_button.add_theme_stylebox_override("focus", _button_style(true))
	menu_button.pressed.connect(_return_to_main_menu)
	layout.add_child(menu_button)
	return overlay

func _open_puzzle() -> void:
	if _is_solved or _puzzle_overlay.visible:
		return
	_puzzle_step = 0
	_puzzle_status_key = "puzzle_choose"
	_refresh_language(SettingsManager.get_values_copy())
	_refresh_sequence_label()
	_puzzle_overlay.visible = true
	_set_player_controls(false)
	if not _symbol_buttons.is_empty():
		_symbol_buttons[0].grab_focus.call_deferred()

func _on_symbol_selected(symbol_id: int) -> void:
	if _is_solved:
		return
	if _lantern_order[_puzzle_step] != symbol_id:
		_puzzle_step = 0
		_puzzle_status_key = "puzzle_wrong"
		_refresh_language(SettingsManager.get_values_copy())
		_play_whisper()
		_refresh_sequence_label()
		return
	_puzzle_step += 1
	_puzzle_status_key = "puzzle_answer" if _puzzle_step < 4 else "puzzle_release"
	_refresh_language(SettingsManager.get_values_copy())
	_refresh_sequence_label()
	if _puzzle_step == 4:
		_complete_puzzle()

func _refresh_sequence_label() -> void:
	if not is_instance_valid(_sequence_label):
		return
	var entries := PackedStringArray()
	for index in range(4):
		if index < _puzzle_step:
			entries.append(_symbol_name(_lantern_order[index]))
		else:
			entries.append("?")
	_sequence_label.text = "   →   ".join(entries)

func _symbol_name(index: int) -> String:
	return SettingsManager.text_for(SYMBOL_NAME_KEYS[index])

func _refresh_language(_values: Dictionary) -> void:
	var arabic := String(SettingsManager.get_value("language", "English")) == "Arabic"
	var direction := Control.LAYOUT_DIRECTION_RTL if arabic else Control.LAYOUT_DIRECTION_LTR
	if is_instance_valid(_puzzle_overlay):
		_puzzle_overlay.layout_direction = direction
	if is_instance_valid(_puzzle_title):
		_puzzle_title.text = SettingsManager.text_for("puzzle_title")
		_puzzle_title.add_theme_font_override("font", _ui_sans if arabic else _ui_serif)
	if is_instance_valid(_puzzle_description):
		_puzzle_description.text = SettingsManager.text_for("puzzle_description")
	if is_instance_valid(_puzzle_back):
		_puzzle_back.text = SettingsManager.text_for("back")
	if is_instance_valid(_status_label):
		_status_label.text = SettingsManager.text_for(_puzzle_status_key)
	for index in _symbol_buttons.size():
		_symbol_buttons[index].text = SYMBOL_MARKS[index] + "\n" + _symbol_name(index)
		_symbol_buttons[index].add_theme_font_override("font", _ui_sans if arabic else _ui_serif)
	for index in _symbol_world_labels.size():
		_symbol_world_labels[index].text = SYMBOL_MARKS[index] + "\n" + _symbol_name(index)
	if is_instance_valid(_ending_overlay):
		_ending_overlay.layout_direction = direction
	if is_instance_valid(_ending_title):
		_ending_title.text = SettingsManager.text_for("ending_title")
	if is_instance_valid(_ending_subtitle):
		_ending_subtitle.text = SettingsManager.text_for("subtitle")
		_ending_subtitle.add_theme_font_override("font", _ui_sans if arabic else _ui_serif)
	if is_instance_valid(_ending_story):
		_ending_story.text = SettingsManager.text_for("ending_story")
	if is_instance_valid(_ending_menu_button):
		_ending_menu_button.text = SettingsManager.text_for("return_menu")
	if is_instance_valid(_ending_overlay):
		var layout: VBoxContainer = null
		if is_instance_valid(_ending_title):
			layout = _ending_title.get_parent() as VBoxContainer
		if layout != null:
			layout.layout_direction = direction
			layout.anchor_left = 0.53 if arabic else 0.075
			layout.anchor_right = 0.93 if arabic else 0.48
			var text_scrim := _ending_overlay.get_node_or_null("EndingTextScrim") as ColorRect
			if is_instance_valid(text_scrim):
				text_scrim.anchor_left = 0.44 if arabic else 0.0
				text_scrim.anchor_right = 1.0 if arabic else 0.56
			for control in layout.get_children():
				if control is Label:
					control.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if arabic else HORIZONTAL_ALIGNMENT_LEFT
					control.add_theme_font_override("font", _ui_sans if arabic else _ui_serif)
				elif control is Button:
					control.alignment = HORIZONTAL_ALIGNMENT_RIGHT if arabic else HORIZONTAL_ALIGNMENT_LEFT
					control.size_flags_horizontal = Control.SIZE_SHRINK_END if arabic else Control.SIZE_SHRINK_BEGIN
	_refresh_sequence_label()

func _complete_puzzle() -> void:
	_is_solved = true
	for button in _symbol_buttons:
		button.disabled = true
	for body in _door_bodies:
		body.collision_layer = 0
		body.collision_mask = 0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_door_left, "rotation:y", deg_to_rad(-92.0), 1.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_door_right, "rotation:y", deg_to_rad(92.0), 1.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	var exit_light := get_meta("exit_light") as OmniLight3D
	tween.tween_property(exit_light, "light_energy", 1.7, 1.5)
	tween.tween_property(_final_light, "light_energy", 3.5, 1.5)
	tween.tween_property(_final_glass_material, "emission_energy_multiplier", 4.5, 1.4)
	await tween.finished
	_puzzle_overlay.visible = false
	_hud.visible = false
	var player_visual := _player.get_node_or_null("VisualPivot") as Node3D
	if is_instance_valid(player_visual):
		player_visual.visible = false
	_ending_overlay.visible = true
	_set_player_controls(false)

func _close_puzzle() -> void:
	if _is_solved:
		return
	_puzzle_overlay.visible = false
	_set_player_controls(true)

func _set_player_controls(enabled: bool) -> void:
	if not is_instance_valid(_player):
		return
	_player.set_physics_process(enabled)
	_player.set_process(enabled)
	_player.set_process_unhandled_input(enabled)
	_player.set_process_unhandled_key_input(enabled)
	if enabled:
		_player.call("refresh_cursor_state")
	else:
		_player.velocity = Vector3.ZERO
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _play_whisper() -> void:
	var player := AudioStreamPlayer.new()
	player.stream = WHISPERS.pick_random()
	player.bus = "SFX"
	player.volume_db = -12.0
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()

func _start_ambience() -> void:
	var loop_stream := TEMPLE_AMBIENCE.duplicate() as AudioStreamOggVorbis
	loop_stream.loop = true
	var ambience := AudioStreamPlayer.new()
	ambience.name = "TempleAmbience"
	ambience.stream = loop_stream
	ambience.bus = "Music"
	ambience.volume_db = -19.0
	add_child(ambience)
	ambience.play()

func _on_interaction_prompt_changed(prompt: String) -> void:
	_hud.call("set_interaction_prompt", prompt)

func _on_game_resumed() -> void:
	_player.call("refresh_cursor_state")

func _return_to_main_menu() -> void:
	if _transitioning:
		return
	_transitioning = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.55)
	await tween.finished
	get_tree().paused = false
	var error := get_tree().change_scene_to_file(MENU_SCENE)
	if error != OK:
		_transitioning = false
		push_error("Could not open the main menu. Error: %s" % error_string(error))

func _solid_box(node_name: String, position: Vector3, size: Vector3, material: Material, parent: Node3D = null) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	var destination: Node3D = self if parent == null else parent
	destination.add_child(body)
	return body

func _decorative_box(node_name: String, position: Vector3, size: Vector3, material: Material, parent: Node3D) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return instance

func _material(color: Color, roughness: float, emission: Color = Color.BLACK, energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.006, 0.012, 0.016, 0.97)
	style.border_color = Color(0.75, 0.52, 0.28, 0.7)
	style.set_border_width_all(1)
	style.content_margin_left = 28.0
	style.content_margin_right = 28.0
	style.content_margin_top = 24.0
	style.content_margin_bottom = 24.0
	return style

func _button_style(highlighted: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.085, 0.045, 0.82) if highlighted else Color(0.025, 0.035, 0.04, 0.88)
	style.border_color = Color(0.91, 0.58, 0.28, 0.9) if highlighted else Color(0.5, 0.52, 0.51, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style
