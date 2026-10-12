extends Area3D

signal activated

func _ready() -> void:
	add_to_group("interactables")

func get_interaction_prompt() -> String:
	return "interact_symbols"

func interact(_player: Node) -> void:
	activated.emit()
