extends Node3D

const ENVIRONMENT_SCRIPT := preload("res://scripts/world/forest_environment.gd")
const PLAYER_SCENE := preload("res://scenes/player.tscn")
const LANTERN_SCRIPT := preload("res://scripts/world/lantern.gd")
const STONE_LANTERN_SCENE := preload("res://assets/models/props/japanese_stone_lanterntoro_512.glb")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const PAUSE_SCENE := preload("res://scenes/ui/pause_menu.tscn")
const TEMPLE_SCENE_PATH := "res://scenes/temple.tscn"
const MAIN_MENU_PATH := "res://scenes/main_menu.tscn"
const FOREST_AMBIENCE := preload("res://assets/audio/AMB_Forest_Night_Loop.mp3")
const SHRINE_WIND := preload("res://assets/audio/AMB_Shrine_Wind.ogg")
const LANTERN_IGNITE := preload("res://assets/audio/SFX_Lantern_Ignite.mp3")
const BRANCH_CREAK := preload("res://assets/audio/SFX_Branch_Creak.ogg")
const WHISPERS: Array[AudioStream] = [
	preload("res://assets/audio/SFX_Distant_Whisper_01.ogg"),
	preload("res://assets/audio/SFX_Distant_Whisper_02.ogg"),
	preload("res://assets/audio/SFX_Distant_Whisper_03.ogg"),
	preload("res://assets/audio/SFX_Distant_Whisper_04.ogg"),
]
const LANTERN_SYMBOL_MARKS: PackedStringArray = ["○", "◎", "△", "◇"]
const LANTERN_SYMBOL_KEYS: PackedStringArray = ["symbol_moon", "symbol_eye", "symbol_tree", "symbol_sun"]
const LANTERN_POSITIONS: Array[Vector3] = [
	Vector3(0.0, 0.0, -8.7),
	Vector3(-10.5, 0.0, -22.0),
	Vector3(10.5, 0.0, -22.0),
	Vector3(0.0, 0.0, -37.5),
]
var _environment: Node3D
var _player: CharacterBody3D
var _lanterns: Array[Area3D] = []
var _lit_flags: Array[bool] = [false, false, false, false]
var _hud: Control
var _pause_menu: Control
var _fade: ColorRect
var _lit_count := 0
var _transitioning := false
var _lantern_clues: Array[Label3D] = []
var _lantern_clue_font: SystemFont

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	GameProgress.begin_forest_run()
	_lantern_clue_font = SystemFont.new()
	_lantern_clue_font.font_names = PackedStringArray(["Segoe UI", "Arial"])
	_environment = ENVIRONMENT_SCRIPT.new() as Node3D
	_environment.name = "ForestEnvironment"
	add_child(_environment)
	_environment.call("build_gameplay")
	_create_gameplay_lanterns()
	SettingsManager.settings_changed.connect(_refresh_lantern_clues)
	_refresh_lantern_clues(SettingsManager.get_values_copy())
	_start_ambience()
	_start_shrine_ambience()
	_player = PLAYER_SCENE.instantiate() as CharacterBody3D
	_player.name = "Player"
	_player.position = Vector3(0.0, 0.02, 3.7)
	add_child(_player)
	_player.interaction_prompt_changed.connect(_on_interaction_prompt_changed)
	_create_ui()
	_refresh_lantern_availability()
	_hud.call("set_lantern_count", _lit_count)
	_hud.call("set_objective", "objective_start")
	_fade.color.a = 1.0
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 0.0, 0.75)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not get_tree().paused:
		_pause_menu.call("open")
		get_viewport().set_input_as_handled()

func _start_ambience() -> void:
	var loop_stream := FOREST_AMBIENCE.duplicate() as AudioStreamMP3
	loop_stream.loop = true
	var ambience := AudioStreamPlayer.new()
	ambience.name = "ForestAmbience"
	ambience.stream = loop_stream
	ambience.bus = "Music"
	ambience.volume_db = -18.0
	add_child(ambience)
	ambience.play()

func _start_shrine_ambience() -> void:
	var loop_stream := SHRINE_WIND.duplicate() as AudioStreamOggVorbis
	loop_stream.loop = true
	var ambience := AudioStreamPlayer3D.new()
	ambience.name = "ForgottenShelterWind"
	ambience.stream = loop_stream
	ambience.bus = "Music"
	ambience.volume_db = -24.0
	ambience.max_distance = 16.0
	add_child(ambience)
	ambience.global_position = Vector3(-15.5, 1.0, -21.4)
	ambience.play()

func _create_gameplay_lanterns() -> void:
	for index in LANTERN_POSITIONS.size():
		_create_gameplay_lantern(index, LANTERN_POSITIONS[index])

func _create_gameplay_lantern(index: int, world_position: Vector3) -> void:
	var lantern := LANTERN_SCRIPT.new() as Area3D
	lantern.name = "Lantern_%02d" % (index + 1)
	lantern.position = world_position
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.4
	collision.shape = sphere
	collision.position = Vector3(0.0, 1.25, 0.0)
	lantern.add_child(collision)
	var lantern_model := STONE_LANTERN_SCENE.instantiate() as Node3D
	lantern_model.name = "DownloadedStoneLantern"
	# GLB already converts to Godot's Y-up coordinates. A second rotation lays it over.
	lantern_model.scale = Vector3.ONE * 0.65
	lantern.add_child(lantern_model)
	_disable_model_shadows(lantern_model)
	var flame := MeshInstance3D.new()
	flame.name = "Flame"
	var flame_mesh := SphereMesh.new()
	flame_mesh.radius = 0.11
	flame_mesh.height = 0.28
	flame.mesh = flame_mesh
	flame.material_override = _material(Color("ffb56a"), 0.3, Color("ff8138"), 4.0)
	flame.position = Vector3(0.0, 0.98, 0.0)
	flame.visible = false
	lantern.add_child(flame)
	var lamp_light := OmniLight3D.new()
	lamp_light.name = "FlameLight"
	lamp_light.position.y = 0.98
	lamp_light.light_color = Color("ff9c51")
	lamp_light.light_energy = 0.0
	lamp_light.omni_range = 7.0
	lamp_light.shadow_enabled = false
	lamp_light.visible = false
	lantern.add_child(lamp_light)
	var clue := Label3D.new()
	clue.name = "LanternInscription"
	clue.position = Vector3(0.0, 1.9, 0.0)
	clue.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	clue.no_depth_test = true
	clue.font = _lantern_clue_font
	clue.font_size = 38
	clue.pixel_size = 0.007
	clue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clue.modulate = Color("f3d7aa")
	clue.outline_size = 9
	clue.outline_modulate = Color("111719")
	lantern.add_child(clue)
	_lantern_clues.append(clue)
	add_child(lantern)
	lantern.connect("lit_changed", Callable(self, "_on_lantern_lit").bind(index + 1))
	_lanterns.append(lantern)

func _refresh_lantern_clues(_values: Dictionary) -> void:
	for index in _lantern_clues.size():
		_lantern_clues[index].text = "%s\n%s" % [LANTERN_SYMBOL_MARKS[index], SettingsManager.text_for(LANTERN_SYMBOL_KEYS[index])]

func _disable_model_shadows(node: Node) -> void:
	for child in node.get_children():
		if child is GeometryInstance3D:
			child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_disable_model_shadows(child)

func _refresh_lantern_availability() -> void:
	var available_ids: Array[int] = []
	if not _lit_flags[0]:
		available_ids.append(1)
	if _lit_flags[0]:
		if not _lit_flags[1]:
			available_ids.append(2)
		if not _lit_flags[2]:
			available_ids.append(3)
	if _lit_flags[1] and _lit_flags[2] and not _lit_flags[3]:
		available_ids.append(4)
	for index in _lanterns.size():
		var is_lit: bool = _lit_flags[index]
		var can_be_lit: bool = available_ids.has(index + 1)
		_lanterns[index].call("set_available", is_lit or can_be_lit)
		var discovery_strength: float = 0.0 if index == 3 else 0.60
		_lanterns[index].call("set_discovery_strength", discovery_strength if can_be_lit else 0.0)

func _on_lantern_lit(lit: bool, lantern_id: int) -> void:
	if not lit or _transitioning or _lit_flags[lantern_id - 1]:
		return
	_lit_flags[lantern_id - 1] = true
	GameProgress.register_lantern(lantern_id)
	_lit_count = GameProgress.get_lantern_order().size()
	_hud.call("set_lantern_count", _lit_count)
	_play_one_shot(LANTERN_IGNITE, "SFX", LANTERN_POSITIONS[lantern_id - 1], -5.0)
	if lantern_id == 1:
		_play_one_shot(BRANCH_CREAK, "SFX", _player.global_position + Vector3(4.0, 1.0, -2.0), -12.0)
	elif lantern_id == 2 or lantern_id == 3:
		_play_one_shot(WHISPERS.pick_random(), "SFX", _player.global_position + Vector3(0.0, 0.0, 4.0), -17.0)
	_refresh_lantern_availability()
	if _lit_flags[0] and not (_lit_flags[1] and _lit_flags[2]):
		_environment.call("set_progression_stage", 1)
		_hud.call("set_objective", "objective_split")
	elif _lit_flags[1] and _lit_flags[2] and not _lit_flags[3]:
		_environment.call("set_progression_stage", 2)
		_hud.call("set_objective", "objective_last")
	elif _lit_count == 4:
		_environment.call("set_progression_stage", 3)
		_hud.call("set_objective", "objective_complete")
		_finish_forest_level()

func _finish_forest_level() -> void:
	if _transitioning:
		return
	_transitioning = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 1.15)
	await tween.finished
	var error := get_tree().change_scene_to_file(TEMPLE_SCENE_PATH)
	if error != OK:
		_transitioning = false
		push_error("Could not load Temple level: %s" % error_string(error))

func _play_one_shot(stream: AudioStream, bus_name: String, at: Vector3, volume_db: float = 0.0) -> void:
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.bus = bus_name
	player.volume_db = volume_db
	player.max_distance = 28.0
	player.finished.connect(player.queue_free)
	add_child(player)
	player.global_position = at
	player.play()

func _create_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "GameUI"
	canvas.layer = 10
	add_child(canvas)
	_hud = HUD_SCENE.instantiate()
	canvas.add_child(_hud)
	_pause_menu = PAUSE_SCENE.instantiate()
	_pause_menu.visible = false
	_pause_menu.connect("resume_requested", Callable(self, "_on_game_resumed"))
	_pause_menu.connect("main_menu_requested", Callable(self, "_return_to_main_menu"))
	canvas.add_child(_pause_menu)
	_fade = ColorRect.new()
	_fade.name = "SceneFade"
	_fade.color = Color(0.0, 0.0, 0.0, 1.0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(_fade)

func _on_interaction_prompt_changed(prompt: String) -> void:
	_hud.call("set_interaction_prompt", prompt)

func _on_game_resumed() -> void:
	_player.call("refresh_cursor_state")

func _return_to_main_menu() -> void:
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.4)
	await tween.finished
	get_tree().change_scene_to_file(MAIN_MENU_PATH)

func _material(color: Color, roughness: float, emission: Color = Color.BLACK, energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material
