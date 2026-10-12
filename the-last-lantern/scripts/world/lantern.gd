extends Area3D

signal lit_changed(lit: bool)

@export var prompt_when_unlit := "interact_lantern"
@export var prompt_when_lit := "lantern_lit"

var is_lit := false
var is_available := true
var _flame_light: OmniLight3D
var _flame_mesh: MeshInstance3D
var _flicker_time := 0.0
var _discovery_strength := 0.0

func _ready() -> void:
	add_to_group("interactables")
	_flame_light = get_node_or_null("FlameLight") as OmniLight3D
	_flame_mesh = get_node_or_null("Flame") as MeshInstance3D
	_update_visuals()

func _process(delta: float) -> void:
	if not is_instance_valid(_flame_light):
		return
	if not is_lit:
		if is_available and _discovery_strength > 0.0:
			_flicker_time += delta
			_flame_light.light_energy = _discovery_strength * (1.0 + sin(_flicker_time * 2.2) * 0.035)
		return
	_flicker_time += delta
	_flame_light.light_energy = 2.0 + sin(_flicker_time * 7.4) * 0.11 + sin(_flicker_time * 13.1) * 0.05

func get_interaction_prompt() -> String:
	if not is_available:
		return ""
	return prompt_when_lit if is_lit else prompt_when_unlit

func set_available(available: bool) -> void:
	is_available = available and not is_lit
	visible = is_available or is_lit
	monitoring = is_available
	monitorable = is_available
	_update_visuals()

func set_discovery_strength(strength: float) -> void:
	_discovery_strength = maxf(strength, 0.0)
	_update_visuals()

func interact(_player: Node) -> void:
	if is_lit or not is_available:
		return
	is_lit = true
	_update_visuals()
	lit_changed.emit(true)

func _update_visuals() -> void:
	if is_instance_valid(_flame_light):
		_flame_light.visible = is_lit or (is_available and _discovery_strength > 0.0)
		_flame_light.omni_range = 11.5 if _discovery_strength > 0.75 else 6.5
		_flame_light.light_energy = 2.1 if is_lit else (_discovery_strength if is_available else 0.0)
	if is_instance_valid(_flame_mesh):
		_flame_mesh.visible = is_lit
