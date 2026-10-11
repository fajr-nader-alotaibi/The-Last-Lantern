extends Area3D

signal lit_changed(lit: bool)

@export var prompt_when_unlit := "F   Light lantern"
@export var prompt_when_lit := "Lantern is already lit"

var is_lit := false
var _flame_light: OmniLight3D
var _flame_mesh: MeshInstance3D

func _ready() -> void:
	add_to_group("interactables")
	_flame_light = get_node_or_null("FlameLight") as OmniLight3D
	_flame_mesh = get_node_or_null("Flame") as MeshInstance3D
	_update_visuals()

func get_interaction_prompt() -> String:
	return prompt_when_lit if is_lit else prompt_when_unlit

func interact(_player: Node) -> void:
	if is_lit:
		return
	is_lit = true
	_update_visuals()
	lit_changed.emit(true)

func _update_visuals() -> void:
	if is_instance_valid(_flame_light):
		_flame_light.visible = is_lit
		_flame_light.light_energy = 2.1 if is_lit else 0.0
	if is_instance_valid(_flame_mesh):
		_flame_mesh.visible = is_lit
