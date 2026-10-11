extends Node3D

const ENVIRONMENT_SCRIPT := preload("res://scripts/world/forest_environment.gd")
const PLAYER_SCENE := preload("res://scenes/player.tscn")
const LANTERN_SCRIPT := preload("res://scripts/world/lantern.gd")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const PAUSE_SCENE := preload("res://scenes/ui/pause_menu.tscn")
const MAIN_MENU_PATH := "res://scenes/main_menu.tscn"
const LANTERN_POSITIONS := [
	Vector3(0.0, 0.0, -8.7),
	Vector3(-8.2, 0.0, -19.8),
	Vector3(8.4, 0.0, -20.3),
	Vector3(0.0, 0.0, -34.3),
]

var _player: CharacterBody3D
var _hud: Control
var _pause_menu: Control
var _fade: ColorRect
var _lit_count := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var environment := ENVIRONMENT_SCRIPT.new()
	add_child(environment)
	environment.call("build_gameplay")
	_create_gameplay_lanterns()
	_player = PLAYER_SCENE.instantiate() as CharacterBody3D
	_player.name = "Player"
	_player.position = Vector3(0.0, 0.02, 3.7)
	add_child(_player)
	_player.connect("interaction_prompt_changed", Callable(self, "_on_interaction_prompt_changed"))
	_create_ui()
	_fade.color.a = 1.0
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 0.0, 0.75)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not get_tree().paused:
		_pause_menu.call("open")
		get_viewport().set_input_as_handled()

func _create_gameplay_lanterns() -> void:
	for index in LANTERN_POSITIONS.size():
		_create_gameplay_lantern(index + 1, LANTERN_POSITIONS[index])

func _create_gameplay_lantern(index: int, world_position: Vector3) -> void:
	var lantern := LANTERN_SCRIPT.new()
	lantern.name = "Lantern_%02d" % index
	lantern.position = world_position
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.15
	collision.shape = sphere
	collision.position = Vector3(0.0, 1.25, 0.0)
	lantern.add_child(collision)
	var stone := _material(Color("3a3d3d"), 0.82)
	var dark_stone := _material(Color("232a2b"), 0.93)
	var unlit_glass := _material(Color("211b16"), 0.38)
	_box(Vector3(0.0, 0.18, 0.0), Vector3(0.62, 0.36, 0.62), dark_stone, "LanternPedestal", lantern)
	_box(Vector3(0.0, 0.72, 0.0), Vector3(0.34, 0.78, 0.34), stone, "LanternStem", lantern)
	_box(Vector3(0.0, 1.18, 0.0), Vector3(0.72, 0.13, 0.72), dark_stone, "LanternSill", lantern)
	_box(Vector3(0.0, 1.5, 0.0), Vector3(0.48, 0.56, 0.48), unlit_glass, "LanternHousing", lantern)
	var flame := MeshInstance3D.new()
	flame.name = "Flame"
	var flame_mesh := SphereMesh.new()
	flame_mesh.radius = 0.11
	flame_mesh.height = 0.28
	flame.mesh = flame_mesh
	flame.material_override = _material(Color("ffb56a"), 0.3, Color("ff8138"), 4.0)
	flame.position = Vector3(0.0, 1.5, 0.0)
	flame.visible = false
	lantern.add_child(flame)
	var roof := MeshInstance3D.new()
	var roof_mesh := PrismMesh.new()
	roof_mesh.size = Vector3(0.98, 0.33, 0.98)
	roof.mesh = roof_mesh
	roof.material_override = stone
	roof.position.y = 1.93
	lantern.add_child(roof)
	var lamp_light := OmniLight3D.new()
	lamp_light.name = "FlameLight"
	lamp_light.position.y = 1.53
	lamp_light.light_color = Color("ff9c51")
	lamp_light.light_energy = 0.0
	lamp_light.omni_range = 7.0
	lamp_light.shadow_enabled = false
	lamp_light.visible = false
	lantern.add_child(lamp_light)
	add_child(lantern)
	lantern.connect("lit_changed", Callable(self, "_on_lantern_lit"))

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
	_hud.call("set_lantern_count", _lit_count)

func _on_lantern_lit(lit: bool) -> void:
	if lit:
		_lit_count = mini(_lit_count + 1, 4)
		_hud.call("set_lantern_count", _lit_count)

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

func _box(position: Vector3, size: Vector3, material: Material, node_name: String, parent: Node3D) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	parent.add_child(instance)
	return instance
