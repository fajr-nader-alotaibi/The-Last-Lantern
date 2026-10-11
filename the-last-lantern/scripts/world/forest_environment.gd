extends Node3D

var _canopies: Array[Node3D] = []
var _flicker_lights: Array[OmniLight3D] = []
var _camera: Camera3D
var _time := 0.0
var _fog_environment: Environment

func build_menu() -> void:
	_build_base_world()
	_build_forest_line()
	_build_path_and_torii()
	_build_stone_lanterns()
	_build_moon()
	_create_menu_camera()
	_create_drifting_motes()

func build_gameplay() -> void:
	_build_base_world()
	_build_forest_line()
	_build_path_and_torii()
	_build_stone_lanterns(false)

func _process(delta: float) -> void:
	_time += delta
	for index in _canopies.size():
		_canopies[index].rotation.z = sin(_time * 0.22 + index * 1.7) * 0.012
	for index in _flicker_lights.size():
		var pulse := sin(_time * 2.4 + index * 1.31) * 0.07
		_flicker_lights[index].light_energy = 1.15 + pulse
	if is_instance_valid(_fog_environment):
		_fog_environment.fog_density = 0.021 + sin(_time * 0.13) * 0.0018
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
	var trunk_materials := [
		_material(Color("11191b"), 0.93),
		_material(Color("182023"), 0.92),
		_material(Color("0c1417"), 0.95),
	]
	var leaf_materials := [
		_material(Color("101c20"), 0.96),
		_material(Color("142126"), 0.95),
		_material(Color("0c171b"), 0.97),
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 94217
	for side in [-1.0, 1.0]:
		for row in range(6):
			var z: float = -1.5 - row * 4.6 + rng.randf_range(-1.0, 1.0)
			var x: float = float(side) * (4.8 + row * 0.72 + rng.randf_range(-0.6, 0.6))
			var tree_height: float = rng.randf_range(8.0, 13.0)
			_create_tree(Vector3(x, 0.0, z), tree_height,
				trunk_materials[rng.randi_range(0, trunk_materials.size() - 1)],
				leaf_materials[rng.randi_range(0, leaf_materials.size() - 1)], rng)

func _create_tree(origin: Vector3, height: float, trunk_material: Material, leaf_material: Material, rng: RandomNumberGenerator) -> void:
	var trunk := MeshInstance3D.new()
	trunk.name = "PineTrunk"
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = rng.randf_range(0.18, 0.29)
	trunk_mesh.bottom_radius = trunk_mesh.top_radius * 1.65
	trunk_mesh.height = height
	trunk_mesh.radial_segments = 7
	trunk.mesh = trunk_mesh
	trunk.material_override = trunk_material
	trunk.position = origin + Vector3(0.0, height * 0.5, 0.0)
	trunk.rotation.z = rng.randf_range(-0.035, 0.035)
	add_child(trunk)

	var canopy_root := Node3D.new()
	canopy_root.name = "SwayingCrown"
	canopy_root.position = origin + Vector3(0.0, height * 0.78, 0.0)
	add_child(canopy_root)
	_canopies.append(canopy_root)
	for layer in range(3):
		var cone := MeshInstance3D.new()
		var cone_mesh := CylinderMesh.new()
		cone_mesh.top_radius = 0.03
		cone_mesh.bottom_radius = (2.4 - layer * 0.34) * rng.randf_range(0.78, 1.05)
		cone_mesh.height = 3.8 - layer * 0.28
		cone_mesh.radial_segments = 7
		cone.mesh = cone_mesh
		cone.material_override = leaf_material
		cone.position.y = 1.25 - layer * 1.15
		canopy_root.add_child(cone)

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

	var torii_material := _material(Color("241d1b"), 0.78, Color("3d211b"), 0.08)
	var upright_left := _box(Vector3(-3.3, 2.65, -17.1), Vector3(0.42, 5.3, 0.5), torii_material, "ToriiPillarLeft")
	var upright_right := _box(Vector3(3.3, 2.65, -17.1), Vector3(0.42, 5.3, 0.5), torii_material, "ToriiPillarRight")
	upright_left.rotation.z = 0.018
	upright_right.rotation.z = -0.018
	_box(Vector3(0.0, 5.24, -17.1), Vector3(8.1, 0.43, 0.75), torii_material, "ToriiCrossbeam")
	_box(Vector3(0.0, 4.56, -17.1), Vector3(6.8, 0.24, 0.52), torii_material, "ToriiLintel")
	_box(Vector3(0.0, 3.91, -17.1), Vector3(0.22, 0.98, 0.22), torii_material, "ToriiCenterBrace")

func _build_stone_lanterns(lit: bool = true) -> void:
	var stone := _material(Color("353638"), 0.8)
	var dark_stone := _material(Color("202527"), 0.91)
	var ember := _material(Color("ff9b45") if lit else Color("181a19"), 0.4, Color("ff7d2f"), 3.0 if lit else 0.0)
	for index in range(4):
		var side := -1.0 if index % 2 == 0 else 1.0
		var z := -1.4 - floori(float(index) / 2.0) * 5.4
		var lantern_root := Node3D.new()
		lantern_root.name = "PathLantern_%02d" % (index + 1)
		lantern_root.position = Vector3(side * 2.45, 0.0, z)
		add_child(lantern_root)
		_box(Vector3(0.0, 0.16, 0.0), Vector3(0.52, 0.32, 0.52), dark_stone, "Foot", lantern_root)
		_box(Vector3(0.0, 0.62, 0.0), Vector3(0.28, 0.64, 0.28), stone, "Stem", lantern_root)
		_box(Vector3(0.0, 1.1, 0.0), Vector3(0.66, 0.14, 0.66), dark_stone, "BaseCap", lantern_root)
		_box(Vector3(0.0, 1.48, 0.0), Vector3(0.4, 0.6, 0.4), stone, "LightHousing", lantern_root)
		var window := _box(Vector3(0.0, 1.48, 0.205), Vector3(0.2, 0.31, 0.025), ember, "WarmWindow", lantern_root)
		window.visible = lit
		_box(Vector3(0.0, 1.84, 0.0), Vector3(0.82, 0.15, 0.82), dark_stone, "RoofEdge", lantern_root)
		var roof := MeshInstance3D.new()
		var roof_mesh := PrismMesh.new()
		roof_mesh.size = Vector3(0.95, 0.34, 0.95)
		roof.mesh = roof_mesh
		roof.material_override = stone
		roof.position.y = 2.08
		lantern_root.add_child(roof)
		var light := OmniLight3D.new()
		light.name = "LanternGlow"
		light.position.y = 1.5
		light.light_color = Color("ff9a4b")
		light.light_energy = 1.15
		light.omni_range = 5.7
		light.shadow_enabled = false
		light.visible = lit
		lantern_root.add_child(light)
		_flicker_lights.append(light)
		window.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

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
	var destination := self if parent == null else parent
	destination.add_child(instance)
	return instance
