extends Node3D

const DISTANT_PINE_SCENE := preload("res://assets/models/Japanese_Pine_v1_1K.glb")
const LOW_POLY_TREE_SCENE := preload("res://assets/models/props/tree_low_poly.glb")
const OLD_HOUSE_SCENE := preload("res://assets/models/props/old_house.glb")
const LOW_POLY_TREE_BASE_HEIGHT := 9.0
const OLD_HOUSE_SCALE := 0.72
const GAMEPLAY_LANTERN_SITES: Array[Vector3] = [
	Vector3(0.0, 0.0, -8.7),
	Vector3(-10.5, 0.0, -22.0),
	Vector3(10.5, 0.0, -22.0),
	Vector3(0.0, 0.0, -37.5),
]
const FERN_PROP_SCENE := preload("res://assets/models/props/fern_low_poly_512.glb")
const SHRUB_PROP_SCENES: Array[PackedScene] = [
	preload("res://assets/models/props/euonymus_shrub_a_low.glb"),
	preload("res://assets/models/props/euonymus_shrub_b_low.glb"),
	preload("res://assets/models/props/euonymus_shrub_c_low.glb"),
]
const TORII_PROP_SCENE := preload("res://assets/models/props/japanese_torii_gate_1k.glb")
const STONE_LANTERN_SCENE := preload("res://assets/models/props/japanese_stone_lanterntoro_512.glb")

var _canopies: Array[Node3D] = []
var _flicker_lights: Array[OmniLight3D] = []
var _camera: Camera3D
var _time := 0.0
var _base_fog_density := 0.021
var _fog_environment: Environment
var _progression_sections: Array[Node3D] = []
var _paver_mesh: ArrayMesh
var _grass_blade_mesh: CylinderMesh

func build_menu() -> void:
	_build_base_world()
	_build_forest_line()
	_build_path_and_torii()
	_build_stone_lanterns()
	_build_moon()
	_create_menu_camera()
	_create_drifting_motes()

func build_gameplay() -> void:
	_build_gameplay_world()
	_build_gameplay_paths()
	_build_gameplay_landmarks()
	_build_gameplay_forest()
	set_progression_stage(0)

func set_progression_stage(stage: int) -> void:
	var visible_through := clampi(stage, 0, _progression_sections.size() - 1)
	for index in _progression_sections.size():
		_progression_sections[index].visible = index <= visible_through

func _build_gameplay_world() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	_fog_environment = environment
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("08111a")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("344553")
	environment.ambient_light_energy = 0.3
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color("1b2930")
	environment.fog_density = 0.0055
	_base_fog_density = 0.0055
	environment.fog_sun_scatter = 0.12
	environment.fog_depth_begin = 12.0
	environment.fog_depth_end = 64.0
	world_environment.environment = environment
	add_child(world_environment)

	var moonlight := DirectionalLight3D.new()
	moonlight.name = "Moonlight"
	moonlight.light_color = Color("a8c5e4")
	moonlight.light_energy = 0.48
	moonlight.rotation_degrees = Vector3(-48.0, -24.0, 0.0)
	moonlight.shadow_enabled = false
	add_child(moonlight)

	var ground := MeshInstance3D.new()
	ground.name = "ForestFloor"
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(52.0, 70.0)
	ground.mesh = ground_mesh
	ground.material_override = _material(Color("29352f"), 0.98)
	# Align the visible grass plane with the collision floor so pavers sit nearly flush.
	ground.position = Vector3(0.0, -0.02, -23.0)
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ground)

	var ground_body := StaticBody3D.new()
	ground_body.name = "ForestGroundCollision"
	ground_body.position = Vector3(0.0, -0.22, -23.0)
	var ground_collision := CollisionShape3D.new()
	var ground_shape := BoxShape3D.new()
	ground_shape.size = Vector3(52.0, 0.4, 70.0)
	ground_collision.shape = ground_shape
	ground_body.add_child(ground_collision)
	add_child(ground_body)
	_add_gameplay_bounds()

func _add_gameplay_bounds() -> void:
	_add_invisible_boundary("ForestBoundaryLeft", Vector3(-25.5, 3.0, -23.0), Vector3(0.5, 6.0, 70.0))
	_add_invisible_boundary("ForestBoundaryRight", Vector3(25.5, 3.0, -23.0), Vector3(0.5, 6.0, 70.0))
	_add_invisible_boundary("ForestBoundaryStart", Vector3(0.0, 3.0, 11.5), Vector3(52.0, 6.0, 0.5))
	_add_invisible_boundary("ForestBoundaryEnd", Vector3(0.0, 3.0, -57.5), Vector3(52.0, 6.0, 0.5))

func _add_invisible_boundary(node_name: String, origin: Vector3, dimensions: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = origin
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _build_gameplay_paths() -> void:
	var path_material := _material(Color("302f2a"), 0.97)
	var edge_material := _material(Color("303a35"), 0.96)
	var routes := _gameplay_path_segments()
	for index in range(4):
		var section := Node3D.new()
		section.name = "ForestPathSection_%02d" % index
		_progression_sections.append(section)
		add_child(section)
	var section_by_route := [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3]
	for index in routes.size():
		var route: PackedVector3Array = routes[index]
		_path_segment(route[0], route[1], 3.1, path_material, "ForestTrail_%02d" % index, _progression_sections[section_by_route[index]])
	# The optional shelter is a short side spur off the Lantern 2 clearing.
	_path_segment(Vector3(-10.5, 0.0, -22.0), Vector3(-15.5, 0.0, -18.9), 2.2, path_material, "OptionalShelterTrail", _progression_sections[1])

	# A shallow stream crosses under a simple plank bridge at the first lantern.
	var stream := MeshInstance3D.new()
	stream.name = "NarrowForestStream"
	var stream_mesh := BoxMesh.new()
	stream_mesh.size = Vector3(4.3, 0.025, 2.3)
	stream.mesh = stream_mesh
	stream.material_override = _material(Color("182c36"), 0.35)
	stream.position = Vector3(0.0, -0.105, -9.0)
	stream.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_progression_sections[0].add_child(stream)
	var plank_material := _material(Color("302923"), 0.94)
	for index in range(9):
		var plank := MeshInstance3D.new()
		plank.name = "BridgePlank_%02d" % index
		var plank_mesh := BoxMesh.new()
		plank_mesh.size = Vector3(3.5, 0.075, 0.31)
		plank.mesh = plank_mesh
		plank.material_override = plank_material if index % 2 == 0 else edge_material
		plank.position = Vector3(0.0, -0.015, -10.25 + index * 0.32)
		plank.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_progression_sections[0].add_child(plank)

func _gameplay_path_segments() -> Array[PackedVector3Array]:
	return [
		PackedVector3Array([Vector3(0.0, 0.0, 5.0), Vector3(0.0, 0.0, -9.0)]),
		PackedVector3Array([Vector3(0.0, 0.0, -9.0), Vector3(0.0, 0.0, -14.0)]),
		PackedVector3Array([Vector3(0.0, 0.0, -14.0), Vector3(-5.0, 0.0, -17.0)]),
		PackedVector3Array([Vector3(-5.0, 0.0, -17.0), Vector3(-10.5, 0.0, -22.0)]),
		PackedVector3Array([Vector3(-10.5, 0.0, -22.0), Vector3(-5.0, 0.0, -26.0)]),
		PackedVector3Array([Vector3(-5.0, 0.0, -26.0), Vector3(0.0, 0.0, -28.0)]),
		PackedVector3Array([Vector3(0.0, 0.0, -28.0), Vector3(5.0, 0.0, -26.0)]),
		PackedVector3Array([Vector3(5.0, 0.0, -26.0), Vector3(10.5, 0.0, -22.0)]),
		PackedVector3Array([Vector3(10.5, 0.0, -22.0), Vector3(5.0, 0.0, -17.0)]),
		PackedVector3Array([Vector3(5.0, 0.0, -17.0), Vector3(0.0, 0.0, -14.0)]),
		PackedVector3Array([Vector3(0.0, 0.0, -28.0), Vector3(0.0, 0.0, -37.5)]),
		PackedVector3Array([Vector3(0.0, 0.0, -37.5), Vector3(0.0, 0.0, -46.0)]),
	]

func _path_segment(start: Vector3, finish: Vector3, width: float, material: Material, node_name: String, parent: Node3D = null) -> void:
	var segment := MeshInstance3D.new()
	segment.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, 0.055, start.distance_to(finish))
	segment.mesh = mesh
	segment.material_override = material
	segment.position = (start + finish) * 0.5 + Vector3(0.0, -0.115, 0.0)
	var direction := finish - start
	segment.rotation.y = atan2(direction.x, direction.z)
	segment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var destination: Node3D = self if parent == null else parent
	destination.add_child(segment)
	_add_stone_pavers(start, finish, width, destination, node_name)
	_add_path_edge_grass(start, finish, width, destination, node_name)

func _add_stone_pavers(start: Vector3, finish: Vector3, width: float, destination: Node3D, node_name: String) -> void:
	if _paver_mesh == null:
		_paver_mesh = _make_stone_paver_mesh()
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(node_name.hash()) + 17831
	var direction := finish - start
	direction.y = 0.0
	var length := direction.length()
	if length < 0.1:
		return
	direction /= length
	var side := Vector3(-direction.z, 0.0, direction.x)
	var rows := maxi(2, ceili(length / 0.78))
	var tones: Array[Color] = [Color("454747"), Color("383c3c"), Color("50504c")]
	var batches: Array = [[], [], []]
	for row in rows:
		var along := (float(row) + 0.5) / float(rows)
		var center := start.lerp(finish, along)
		for lane in range(-1, 2):
			var tone := rng.randi_range(0, tones.size() - 1)
			var lateral_offset := float(lane) * width * 0.29 + rng.randf_range(-0.07, 0.07)
			var position := center + side * lateral_offset
			position.y = -0.018 + rng.randf_range(-0.006, 0.006)
			var yaw := atan2(direction.x, direction.z) + rng.randf_range(-0.12, 0.12)
			var size := Vector3(rng.randf_range(0.70, 0.84), rng.randf_range(0.76, 0.94), rng.randf_range(0.70, 0.84))
			var basis := Basis(Vector3.UP, yaw).scaled(size)
			batches[tone].append(Transform3D(basis, position))
	for tone in batches.size():
		if batches[tone].is_empty():
			continue
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = _paver_mesh
		multimesh.instance_count = batches[tone].size()
		for index in batches[tone].size():
			multimesh.set_instance_transform(index, batches[tone][index])
		var stones := MultiMeshInstance3D.new()
		stones.name = "%s_Pavers_%d" % [node_name, tone]
		stones.multimesh = multimesh
		stones.material_override = _material(tones[tone], 0.96)
		stones.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		destination.add_child(stones)

func _make_stone_paver_mesh() -> ArrayMesh:
	# A shallow chamfered flagstone, reused by MultiMesh batches along every trail.
	var points := PackedVector2Array([
		Vector2(-0.50, -0.34), Vector2(-0.43, 0.16), Vector2(-0.25, 0.37), Vector2(0.28, 0.36),
		Vector2(0.49, 0.19), Vector2(0.46, -0.22), Vector2(0.30, -0.38), Vector2(-0.31, -0.40),
	])
	var bottom_y := -0.075
	var top_y := 0.035
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in points.size():
		var next := (index + 1) % points.size()
		var bottom_a := Vector3(points[index].x, bottom_y, points[index].y)
		var bottom_b := Vector3(points[next].x, bottom_y, points[next].y)
		var top_a := Vector3(points[index].x * 0.92, top_y, points[index].y * 0.92)
		var top_b := Vector3(points[next].x * 0.92, top_y, points[next].y * 0.92)
		tool.add_vertex(bottom_a)
		tool.add_vertex(bottom_b)
		tool.add_vertex(top_b)
		tool.add_vertex(bottom_a)
		tool.add_vertex(top_b)
		tool.add_vertex(top_a)
	for index in range(1, points.size() - 1):
		var a := Vector3(points[0].x * 0.92, top_y, points[0].y * 0.92)
		var b := Vector3(points[index].x * 0.92, top_y, points[index].y * 0.92)
		var c := Vector3(points[index + 1].x * 0.92, top_y, points[index + 1].y * 0.92)
		tool.add_vertex(a)
		tool.add_vertex(b)
		tool.add_vertex(c)
	tool.generate_normals()
	return tool.commit()

func _add_path_edge_grass(start: Vector3, finish: Vector3, width: float, destination: Node3D, node_name: String) -> void:
	if _grass_blade_mesh == null:
		_grass_blade_mesh = CylinderMesh.new()
		_grass_blade_mesh.top_radius = 0.008
		_grass_blade_mesh.bottom_radius = 0.038
		_grass_blade_mesh.height = 0.24
		_grass_blade_mesh.radial_segments = 3
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(node_name.hash()) + 6907
	var direction := finish - start
	direction.y = 0.0
	var length := direction.length()
	if length < 0.1:
		return
	direction /= length
	var side := Vector3(-direction.z, 0.0, direction.x)
	var rows := maxi(2, ceili(length / 1.25))
	var transforms: Array[Transform3D] = []
	for row in rows:
		var center := start.lerp(finish, (float(row) + 0.5) / float(rows))
		for edge in [-1.0, 1.0]:
			var edge_offset: float = float(edge) * (width * 0.5 + rng.randf_range(0.32, 0.78))
			var tuft: Vector3 = center + side * edge_offset
			for blade in range(3):
				var angle := rng.randf_range(0.0, TAU)
				var scale := Vector3(rng.randf_range(0.75, 1.15), rng.randf_range(0.72, 1.22), rng.randf_range(0.75, 1.15))
				var basis := Basis(Vector3.UP, angle).scaled(scale)
				var position := tuft + Vector3(rng.randf_range(-0.12, 0.12), 0.11, rng.randf_range(-0.12, 0.12))
				transforms.append(Transform3D(basis, position))
	if transforms.is_empty():
		return
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = _grass_blade_mesh
	multimesh.instance_count = transforms.size()
	for index in transforms.size():
		multimesh.set_instance_transform(index, transforms[index])
	var grass := MultiMeshInstance3D.new()
	grass.name = "%s_GrassBorders" % node_name
	grass.multimesh = multimesh
	grass.material_override = _material(Color("354436"), 0.98)
	grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	destination.add_child(grass)

func _build_gameplay_landmarks() -> void:
	var wood := _material(Color("29211e"), 0.9)
	var wood_trim := _material(Color("49332b"), 0.86)
	var roof_material := _material(Color("171d20"), 0.9)
	var stone := _material(Color("343a3c"), 0.95)
	var water := _material(Color("172b34"), 0.28)

	# The forgotten shrine is treated as an abandoned forest house: no icons or statues.
	_box(Vector3(-15.5, 1.2, -21.4), Vector3(4.4, 2.4, 3.4), wood, "ForgottenForestHouse")
	var house_collision := CollisionShape3D.new()
	var house_shape := BoxShape3D.new()
	house_shape.size = Vector3(4.4, 2.4, 3.4)
	house_collision.shape = house_shape
	house_collision.position = Vector3(-15.5, 1.2, -21.4)
	var house_body := StaticBody3D.new()
	house_body.name = "ForgottenForestHouseCollision"
	house_body.add_child(house_collision)
	add_child(house_body)
	var house_roof := MeshInstance3D.new()
	var house_roof_mesh := PrismMesh.new()
	house_roof_mesh.size = Vector3(5.55, 1.25, 4.65)
	house_roof.mesh = house_roof_mesh
	house_roof.material_override = roof_material
	house_roof.position = Vector3(-15.5, 2.95, -21.4)
	house_roof.name = "ForestHouseRoof"
	house_roof.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(house_roof)
	_box(Vector3(-15.5, 0.92, -19.65), Vector3(1.35, 1.82, 0.12), wood_trim, "ForestHouseDoor")
	var window_material := _material(Color("101719"), 0.35)
	_box(Vector3(-17.25, 1.35, -19.64), Vector3(0.55, 0.52, 0.1), window_material, "HouseWindowLeft")
	_box(Vector3(-13.75, 1.35, -19.64), Vector3(0.55, 0.52, 0.1), window_material, "HouseWindowRight")
	for y in [0.25, 2.15]:
		_box(Vector3(-15.5, y, -19.58), Vector3(4.5, 0.16, 0.16), wood_trim, "HouseFrontBeam")
	for x in [-17.55, -13.45]:
		_box(Vector3(x, 1.2, -19.58), Vector3(0.18, 2.35, 0.18), wood_trim, "HouseFrontPost")
	var porch := MeshInstance3D.new()
	var porch_mesh := BoxMesh.new()
	porch_mesh.size = Vector3(2.5, 0.12, 0.9)
	porch.mesh = porch_mesh
	porch.material_override = wood_trim
	porch.position = Vector3(-15.5, 0.04, -19.15)
	add_child(porch)

	# The pond uses one cheap water mesh; rocks and trees provide the shoreline.
	var pond := MeshInstance3D.new()
	pond.name = "MoonlitPond"
	var pond_mesh := CylinderMesh.new()
	pond_mesh.top_radius = 1.0
	pond_mesh.bottom_radius = 1.0
	pond_mesh.height = 1.0
	pond_mesh.radial_segments = 24
	pond.mesh = pond_mesh
	pond.scale = Vector3(4.2, 0.035, 3.1)
	pond.material_override = water
	pond.position = Vector3(15.0, -0.105, -28.0)
	pond.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(pond)
	_create_rock_ring(Vector3(15.0, 0.0, -28.0), 4.8, 15, stone, 301)

	# A low rocky clearing marks the fourth lantern without a tall step the player cannot climb.
	_box(Vector3(0.0, -0.02, -37.5), Vector3(8.0, 0.16, 5.0), stone, "CliffsideClearing")
	_create_rock_ring(Vector3(0.0, 0.0, -37.5), 5.4, 12, stone, 907)

	# Imported low-poly gate marks the forest's far end.
	_add_torii(Vector3(0.0, 0.0, -43.0), 0.75, "TempleToriiGate", PI)

	_box(Vector3(0.0, 0.12, -51.0), Vector3(10.0, 0.24, 8.0), stone, "TempleForecourt")
	var temple_house := OLD_HOUSE_SCENE.instantiate() as Node3D
	temple_house.name = "JapaneseHouseTempleExterior"
	temple_house.scale = Vector3.ONE * OLD_HOUSE_SCALE
	add_child(temple_house)
	_place_model_base_centered(temple_house, Vector3(0.0, 0.0, -51.5))
	_disable_shadows_recursively(temple_house)
	for index in range(5):
		var step := MeshInstance3D.new()
		step.name = "TempleStep_%02d" % index
		var step_mesh := BoxMesh.new()
		step_mesh.size = Vector3(4.1 + index * 0.55, 0.12, 0.45)
		step.mesh = step_mesh
		step.material_override = stone
		step.position = Vector3(0.0, -0.05 + index * 0.035, -46.1 - index * 0.52)
		step.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(step)

func _build_gameplay_forest() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4102026
	var tree_lanes: Array[float] = [6.8, 11.4, 16.0, 20.3, 24.0]
	for row in range(14):
		var row_z: float = 6.5 - float(row) * 4.6
		for lane_index in tree_lanes.size():
			for side in [-1.0, 1.0]:
				var x: float = float(side) * (tree_lanes[lane_index] + rng.randf_range(-0.85, 0.85))
				var z: float = row_z + rng.randf_range(-1.25, 1.25)
				var tree_position := Vector3(x, 0.0, z)
				if not _is_tree_site_clear(tree_position):
					continue
				if lane_index == tree_lanes.size() - 1 and row % 2 == 0:
					_create_distant_pine(tree_position, rng.randf_range(0.68, 0.82), rng.randf_range(0.0, TAU))
				else:
					var tree_height: float = rng.randf_range(6.6, 8.6) if lane_index == 0 else rng.randf_range(7.3, 10.0)
					_create_low_poly_tree(tree_position, tree_height, rng, lane_index == 0)

	# A symmetric inner grove fills the center of the fork while keeping the stone routes clear.
	var central_grove_positions: Array[Vector3] = [
		Vector3(0.0, 0.0, -18.6),
		Vector3(-2.3, 0.0, -20.4), Vector3(2.3, 0.0, -20.4),
		Vector3(0.0, 0.0, -21.4),
		Vector3(-3.5, 0.0, -22.2), Vector3(3.5, 0.0, -22.2),
		Vector3(-2.0, 0.0, -23.0), Vector3(2.0, 0.0, -23.0),
	]
	for grove_position in central_grove_positions:
		if _is_tree_site_clear(grove_position):
			_create_low_poly_tree(grove_position, rng.randf_range(7.0, 8.8), rng, true)

	# Backdrop trees break the silhouette of the temple roof without blocking its approach.
	var backdrop_positions: Array[Vector3] = [
		Vector3(-8.8, 0.0, -55.0), Vector3(8.8, 0.0, -55.0),
		Vector3(-14.0, 0.0, -52.6), Vector3(14.0, 0.0, -52.6),
		Vector3(-20.5, 0.0, -54.4), Vector3(20.5, 0.0, -54.4),
	]
	for backdrop_position in backdrop_positions:
		if _is_tree_site_clear(backdrop_position):
			_create_low_poly_tree(backdrop_position, rng.randf_range(7.4, 9.4), rng)

	_build_gameplay_understory(rng)
	_create_ground_scatter(rng)

func _is_tree_site_clear(origin: Vector3) -> bool:
	if _minimum_gameplay_path_distance(origin) < 3.75:
		return false
	if _distance_to_segment_xz(origin, Vector3(-10.5, 0.0, -22.0), Vector3(-15.5, 0.0, -18.9)) < 3.6:
		return false
	for lantern_position in GAMEPLAY_LANTERN_SITES:
		if origin.distance_to(lantern_position) < 4.25:
			return false
	if origin.distance_to(Vector3(15.0, 0.0, -28.0)) < 5.4:
		return false
	if origin.distance_to(Vector3(0.0, 0.0, -50.5)) < 7.2:
		return false
	return true

func _minimum_gameplay_path_distance(origin: Vector3) -> float:
	var nearest: float = INF
	for route in _gameplay_path_segments():
		var distance: float = _distance_to_segment_xz(origin, route[0], route[1])
		nearest = minf(nearest, distance)
	return nearest

func _distance_to_segment_xz(point: Vector3, start: Vector3, finish: Vector3) -> float:
	var point_xz := Vector2(point.x, point.z)
	var start_xz := Vector2(start.x, start.z)
	var segment := Vector2(finish.x - start.x, finish.z - start.z)
	var segment_length_squared: float = segment.length_squared()
	if segment_length_squared < 0.0001:
		return point_xz.distance_to(start_xz)
	var along: float = clampf((point_xz - start_xz).dot(segment) / segment_length_squared, 0.0, 1.0)
	return point_xz.distance_to(start_xz + segment * along)

func _build_gameplay_understory(rng: RandomNumberGenerator) -> void:
	var routes := _gameplay_path_segments()
	for route in routes:
		var start: Vector3 = route[0]
		var finish: Vector3 = route[1]
		var direction := finish - start
		direction.y = 0.0
		var length: float = direction.length()
		if length < 0.1:
			continue
		direction /= length
		var side := Vector3(-direction.z, 0.0, direction.x)
		var samples: int = maxi(1, ceili(length / 3.6))
		for sample_index in samples:
			var center := start.lerp(finish, (float(sample_index) + 0.5) / float(samples))
			for edge in [-1.0, 1.0]:
				var offset: float = float(edge) * rng.randf_range(2.45, 4.35)
				var plant_position := center + side * offset
				if not _is_understory_site_clear(plant_position):
					continue
				_add_understory_plant(plant_position, rng)

	# Fill a few open pockets away from the walkable stones so the ground reads as forest floor.
	for attempt in range(96):
		var plant_position := Vector3(rng.randf_range(-23.5, 23.5), 0.0, rng.randf_range(-54.5, 7.0))
		var path_distance: float = _minimum_gameplay_path_distance(plant_position)
		if path_distance < 4.3 or path_distance > 10.0 or not _is_understory_site_clear(plant_position):
			continue
		if rng.randf() < 0.72:
			_add_understory_plant(plant_position, rng)

func _is_understory_site_clear(origin: Vector3) -> bool:
	if _minimum_gameplay_path_distance(origin) < 2.0:
		return false
	for lantern_position in GAMEPLAY_LANTERN_SITES:
		if origin.distance_to(lantern_position) < 3.3:
			return false
	if origin.distance_to(Vector3(-15.5, 0.0, -21.4)) < 4.0:
		return false
	if origin.distance_to(Vector3(15.0, 0.0, -28.0)) < 4.6:
		return false
	if origin.distance_to(Vector3(0.0, 0.0, -50.5)) < 7.0:
		return false
	return true

func _add_understory_plant(origin: Vector3, rng: RandomNumberGenerator) -> void:
	if rng.randf() < 0.62:
		_create_fern_cluster(origin, rng)
		return
	var shrub_index: int = rng.randi_range(0, SHRUB_PROP_SCENES.size() - 1)
	var shrub := SHRUB_PROP_SCENES[shrub_index].instantiate() as Node3D
	shrub.name = "LowPolyEuonymusShrub"
	shrub.position = origin
	shrub.rotation.y = rng.randf_range(0.0, TAU)
	shrub.scale = Vector3.ONE * rng.randf_range(0.30, 0.46)
	_disable_shadows_recursively(shrub)
	add_child(shrub)

func _create_low_poly_tree(origin: Vector3, height: float, rng: RandomNumberGenerator, add_collision: bool = false) -> void:
	var tree := LOW_POLY_TREE_SCENE.instantiate() as Node3D
	tree.name = "ForestLowPolyPine"
	tree.position = origin
	tree.rotation.y = rng.randf_range(0.0, TAU)
	var scale_factor := height / LOW_POLY_TREE_BASE_HEIGHT
	tree.scale = Vector3(scale_factor, scale_factor * 0.92, scale_factor)
	_disable_shadows_recursively(tree)
	add_child(tree)
	if add_collision:
		var trunk_body := StaticBody3D.new()
		trunk_body.name = "PineTrunkCollision"
		trunk_body.position = origin + Vector3(0.0, 0.95 * scale_factor, 0.0)
		var trunk_collision := CollisionShape3D.new()
		var trunk_shape := CapsuleShape3D.new()
		trunk_shape.radius = 0.34 * scale_factor
		trunk_shape.height = 1.9 * scale_factor
		trunk_collision.shape = trunk_shape
		trunk_body.add_child(trunk_collision)
		add_child(trunk_body)

func _place_model_base_centered(model: Node3D, base_point: Vector3) -> void:
	var bounds := _model_bounds(model)
	var model_scale := model.scale
	model.position = base_point - Vector3(
		bounds.get_center().x * model_scale.x,
		bounds.position.y * model_scale.y,
		bounds.get_center().z * model_scale.z
	)

func _model_bounds(model: Node3D) -> AABB:
	var inverse := model.global_transform.affine_inverse()
	var bounds := AABB()
	var found_mesh := false
	for candidate in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := candidate as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var mesh_bounds := inverse * mesh_instance.global_transform * mesh_instance.get_aabb()
		if found_mesh:
			bounds = bounds.merge(mesh_bounds)
		else:
			bounds = mesh_bounds
			found_mesh = true
	return bounds

func _create_ground_scatter(rng: RandomNumberGenerator) -> void:
	# Two MultiMesh batches add low-cost stones and moss around the trail edges.
	for batch in range(2):
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		var pebble := SphereMesh.new()
		pebble.radial_segments = 7
		pebble.rings = 4
		multimesh.mesh = pebble
		var pebble_count := 34
		multimesh.instance_count = pebble_count
		for index in range(pebble_count):
			var side: float = -1.0 if index % 2 == 0 else 1.0
			var x: float = side * rng.randf_range(3.7, 22.5)
			var z: float = rng.randf_range(-54.0, 8.0)
			var pebble_scale: Vector3 = Vector3(rng.randf_range(0.18, 0.72), rng.randf_range(0.08, 0.26), rng.randf_range(0.2, 0.68))
			var rotation: Basis = Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(pebble_scale)
			multimesh.set_instance_transform(index, Transform3D(rotation, Vector3(x, -0.03, z)))
		var stones := MultiMeshInstance3D.new()
		stones.name = "MossyForestGroundScatter_%02d" % batch
		stones.multimesh = multimesh
		stones.material_override = _material(Color("242c29") if batch == 0 else Color("303130"), 0.97)
		stones.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(stones)

func _create_distant_pine(origin: Vector3, size: float, yaw: float) -> void:
	var tree := DISTANT_PINE_SCENE.instantiate() as Node3D
	tree.name = "DistantJapanesePine"
	tree.position = origin
	tree.rotation.y = yaw
	tree.scale = Vector3.ONE * size
	_disable_shadows_recursively(tree)
	add_child(tree)

func _disable_shadows_recursively(node: Node) -> void:
	for child in node.get_children():
		if child is GeometryInstance3D:
			child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_disable_shadows_recursively(child)

func _create_rock_ring(center: Vector3, radius: float, count: int, material: Material, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for index in count:
		var angle := TAU * float(index) / float(count) + rng.randf_range(-0.12, 0.12)
		var rock := MeshInstance3D.new()
		rock.name = "MossyRock_%02d" % index
		var mesh := SphereMesh.new()
		mesh.radial_segments = 7
		mesh.rings = 4
		rock.mesh = mesh
		rock.material_override = material
		rock.scale = Vector3(rng.randf_range(0.35, 0.8), rng.randf_range(0.18, 0.48), rng.randf_range(0.35, 0.72))
		rock.position = center + Vector3(cos(angle) * radius, rock.scale.y * 0.72, sin(angle) * radius)
		rock.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(rock)

func _create_fern_cluster(origin: Vector3, rng: RandomNumberGenerator) -> void:
	var fern := FERN_PROP_SCENE.instantiate() as Node3D
	fern.name = "FernCluster"
	fern.position = origin
	fern.rotation.y = rng.randf_range(0.0, TAU)
	# Keep the repeated 512 px fern small so it frames paths without blocking them.
	fern.scale = Vector3.ONE * rng.randf_range(0.5, 0.78)
	_disable_shadows_recursively(fern)
	add_child(fern)

func _add_torii(origin: Vector3, uniform_scale: float, node_name: String, yaw: float = 0.0) -> void:
	var gate := TORII_PROP_SCENE.instantiate() as Node3D
	gate.name = node_name
	# The optimized GLB includes a corrected scale, orientation, and ground-level pivot.
	gate.position = origin
	gate.rotation.y = yaw
	gate.scale = Vector3.ONE * uniform_scale
	_disable_shadows_recursively(gate)
	add_child(gate)

func _process(delta: float) -> void:
	_time += delta
	for index in _canopies.size():
		_canopies[index].rotation.z = sin(_time * 0.22 + index * 1.7) * 0.012
	for index in _flicker_lights.size():
		var pulse := sin(_time * 2.4 + index * 1.31) * 0.07
		_flicker_lights[index].light_energy = 1.15 + pulse
	if is_instance_valid(_fog_environment):
		_fog_environment.fog_density = _base_fog_density + sin(_time * 0.13) * 0.0007
	if is_instance_valid(_camera):
		_camera.position.x = sin(_time * 0.12) * 0.045

func _build_base_world() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	_fog_environment = environment
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("071019")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("4a6078")
	environment.ambient_light_energy = 0.42
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color("253541")
	environment.fog_density = 0.021
	_base_fog_density = 0.021
	environment.fog_sun_scatter = 0.16
	environment.fog_depth_begin = 5.0
	environment.fog_depth_end = 42.0
	world_environment.environment = environment
	add_child(world_environment)

	var moonlight := DirectionalLight3D.new()
	moonlight.name = "Moonlight"
	moonlight.light_color = Color("a8c5e4")
	moonlight.light_energy = 0.38
	moonlight.rotation_degrees = Vector3(-43.0, -28.0, 0.0)
	moonlight.shadow_enabled = true
	moonlight.directional_shadow_max_distance = 36.0
	add_child(moonlight)

	var ground_material := _material(Color("11181a"), 0.96)
	var ground := MeshInstance3D.new()
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(82.0, 70.0)
	ground.mesh = ground_mesh
	ground.material_override = ground_material
	ground.position = Vector3(0.0, -0.22, -13.0)
	add_child(ground)
	var ground_body := StaticBody3D.new()
	ground_body.name = "ForestGroundCollision"
	ground_body.position = ground.position
	var ground_collision := CollisionShape3D.new()
	var ground_shape := BoxShape3D.new()
	ground_shape.size = Vector3(82.0, 0.4, 70.0)
	ground_collision.shape = ground_shape
	ground_body.add_child(ground_collision)
	add_child(ground_body)

func _build_forest_line() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 94217
	for side in [-1.0, 1.0]:
		for row in range(8):
			var z: float = -1.5 - row * 4.6 + rng.randf_range(-1.0, 1.0)
			var x: float = float(side) * (5.5 + row * 0.82 + rng.randf_range(-0.6, 0.6))
			_create_tree(Vector3(x, 0.0, z), rng.randf_range(8.0, 12.0), rng)

func _create_tree(origin: Vector3, height: float, rng: RandomNumberGenerator, add_collision: bool = false) -> void:
	var tree := DISTANT_PINE_SCENE.instantiate() as Node3D
	tree.name = "JapanesePine"
	tree.position = origin
	tree.rotation.y = rng.randf_range(0.0, TAU)
	tree.rotation.z = rng.randf_range(-0.018, 0.018)
	tree.scale = Vector3.ONE * (height / 10.0)
	_disable_shadows_recursively(tree)
	add_child(tree)
	_canopies.append(tree)
	if add_collision:
		var trunk_body := StaticBody3D.new()
		trunk_body.name = "PineTrunkCollision"
		trunk_body.position = origin + Vector3(0.0, 0.95 * height / 10.0, 0.0)
		var trunk_collision := CollisionShape3D.new()
		var trunk_shape := CapsuleShape3D.new()
		trunk_shape.radius = 0.32 * height / 10.0
		trunk_shape.height = 1.9 * height / 10.0
		trunk_collision.shape = trunk_shape
		trunk_body.add_child(trunk_collision)
		add_child(trunk_body)

func _build_path_and_torii() -> void:
	var path_materials := [
		_material(Color("252b2c"), 0.83),
		_material(Color("303637"), 0.88),
		_material(Color("1c2426"), 0.9),
	]
	var path_base := MeshInstance3D.new()
	var path_base_mesh := BoxMesh.new()
	path_base_mesh.size = Vector3(3.4, 0.12, 33.0)
	path_base.mesh = path_base_mesh
	path_base.material_override = path_materials[0]
	path_base.position = Vector3(0.0, -0.08, -12.0)
	add_child(path_base)
	for index in range(18):
		var step := MeshInstance3D.new()
		var step_mesh := BoxMesh.new()
		step_mesh.size = Vector3(2.65 + (index % 3) * 0.11, 0.12, 0.68)
		step.mesh = step_mesh
		step.material_override = path_materials[index % path_materials.size()]
		step.position = Vector3(0.0, -0.005 + index * 0.012, -0.2 - index * 1.48)
		step.rotation.y = (0.5 - float(index % 2)) * 0.015
		add_child(step)

	_add_torii(Vector3(0.0, 0.0, -17.1), 1.0, "MenuToriiGate")

func _build_stone_lanterns(lit: bool = true) -> void:
	for index in range(4):
		var side := -1.0 if index % 2 == 0 else 1.0
		var z := -1.4 - floori(float(index) / 2.0) * 5.4
		var lantern_root := Node3D.new()
		lantern_root.name = "PathLantern_%02d" % (index + 1)
		lantern_root.position = Vector3(side * 2.45, 0.0, z)
		add_child(lantern_root)
		var model := STONE_LANTERN_SCENE.instantiate() as Node3D
		model.name = "DownloadedStoneLantern"
		# GLB is already converted from glTF's Y-up coordinates by Godot.
		model.scale = Vector3.ONE * 0.65
		lantern_root.add_child(model)
		_disable_shadows_recursively(model)
		var light := OmniLight3D.new()
		light.name = "LanternGlow"
		light.position.y = 0.98
		light.light_color = Color("ff9a4b")
		light.light_energy = 1.05
		light.omni_range = 5.7
		light.shadow_enabled = false
		light.visible = lit
		lantern_root.add_child(light)
		_flicker_lights.append(light)

func _build_moon() -> void:
	var moon := MeshInstance3D.new()
	var moon_mesh := SphereMesh.new()
	moon_mesh.radius = 1.45
	moon_mesh.height = 2.9
	moon.mesh = moon_mesh
	var moon_material := StandardMaterial3D.new()
	moon_material.albedo_color = Color("dce6e9")
	moon_material.emission_enabled = true
	moon_material.emission = Color("94b6d5")
	moon_material.emission_energy_multiplier = 0.75
	moon_material.roughness = 1.0
	moon.material_override = moon_material
	moon.position = Vector3(9.0, 12.0, -27.0)
	add_child(moon)

func _create_menu_camera() -> void:
	_camera = Camera3D.new()
	_camera.name = "MenuCamera"
	_camera.position = Vector3(0.0, 3.0, 10.5)
	_camera.fov = 62.0
	_camera.far = 90.0
	add_child(_camera)
	_camera.look_at(Vector3(0.0, 0.8, -8.0), Vector3.UP)
	_camera.make_current()

func _create_drifting_motes() -> void:
	var particles := GPUParticles3D.new()
	particles.name = "ForestMotes"
	particles.amount = 44
	particles.lifetime = 12.0
	particles.preprocess = 5.0
	particles.emitting = true
	var process_material := ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_material.emission_box_extents = Vector3(16.0, 7.0, 21.0)
	process_material.direction = Vector3(-0.15, -0.12, -0.2)
	process_material.spread = 32.0
	process_material.initial_velocity_min = 0.04
	process_material.initial_velocity_max = 0.18
	process_material.gravity = Vector3(0.0, -0.012, 0.0)
	process_material.scale_min = 0.35
	process_material.scale_max = 0.8
	particles.process_material = process_material
	var mote := SphereMesh.new()
	mote.radius = 0.035
	mote.height = 0.07
	var mote_material := StandardMaterial3D.new()
	mote_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mote_material.albedo_color = Color("e39a56")
	mote.material = mote_material
	particles.draw_pass_1 = mote
	add_child(particles)

func _material(color: Color, roughness: float, emission_color: Color = Color.BLACK, emission_energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission_color
		material.emission_energy_multiplier = emission_energy
	return material

func _box(position: Vector3, size: Vector3, material: Material, node_name: String, parent: Node3D = null) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	var destination: Node3D = self if parent == null else parent
	destination.add_child(instance)
	return instance
