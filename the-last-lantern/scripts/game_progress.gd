extends Node

var lantern_order: Array[int] = []

func begin_forest_run() -> void:
	lantern_order.clear()

func register_lantern(lantern_id: int) -> void:
	if lantern_id >= 1 and lantern_id <= 4 and not lantern_order.has(lantern_id - 1):
		lantern_order.append(lantern_id - 1)

func get_lantern_order() -> Array[int]:
	return lantern_order.duplicate()
