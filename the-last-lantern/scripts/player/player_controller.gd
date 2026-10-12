extends CharacterBody3D

signal interaction_prompt_changed(prompt: String)

const WALK_SPEED := 3.5
const RUN_SPEED := 5.0
const ACCELERATION := 12.0
const GRAVITY := 18.0
const FOCUS_HEIGHT := 0.95
const TURN_SPEED := deg_to_rad(145.0)
const CHARACTER_SCENE := preload("res://assets/character/explorer_rigged.glb")

@onready var _visual_pivot: Node3D = $VisualPivot
@onready var _camera: Camera3D = $CameraPivot/Camera3D

var _camera_yaw := 0.0
var _target_yaw := 0.0
var _queued_yaw := 0.0
var _mouse_pitch := 0.0
var _interactable: Node
var _last_prompt := ""
var _camera_distance := 4.0
var _camera_height := 1.6
var _follow_speed := 0.8
var _fov := 70.0
var _collision_avoidance := true
var _character_animation_player: AnimationPlayer
var _current_character_animation := ""

func _ready() -> void:
	var character := CHARACTER_SCENE.instantiate()
	character.name = "ExplorerModel"
	_visual_pivot.add_child(character)
	_visual_pivot.position.y = 0.0
	_setup_character_animations(character)
	_camera.current = true
	_apply_settings(SettingsManager.get_values_copy())
	SettingsManager.settings_changed.connect(_apply_settings)
	refresh_cursor_state()

func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var forward := Vector3(sin(_camera_yaw), 0.0, -cos(_camera_yaw))
	var right := Vector3(cos(_camera_yaw), 0.0, sin(_camera_yaw))
	var direction := right * input_vector.x - forward * input_vector.y
	var wants_to_run := Input.is_action_pressed("sprint") and direction.length_squared() > 0.01
	if direction.length_squared() > 0.01:
		direction = direction.normalized()
		_visual_pivot.rotation.y = atan2(-direction.x, -direction.z)
	var move_speed := RUN_SPEED if wants_to_run else WALK_SPEED
	velocity.x = move_toward(velocity.x, direction.x * move_speed, ACCELERATION * delta)
	velocity.z = move_toward(velocity.z, direction.z * move_speed, ACCELERATION * delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.05
	move_and_slide()
	_update_character_animation(direction.length_squared() > 0.01, wants_to_run)
	_update_interactable()
	if Input.is_action_just_pressed("interact") and is_instance_valid(_interactable):
		if _interactable.has_method("interact"):
			_interactable.interact(self)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("camera_orbit_left"):
		_queue_orbit(-1.0)
	if Input.is_action_just_pressed("camera_orbit_right"):
		_queue_orbit(1.0)
	if absf(_target_yaw - _camera_yaw) < 0.001 and absf(_queued_yaw) > 0.001:
		var step_radians := deg_to_rad(float(SettingsManager.get_value("camera_rotation_step", 20.0)))
		var consumed := signf(_queued_yaw) * minf(absf(_queued_yaw), step_radians)
		_queued_yaw -= consumed
		_target_yaw += consumed
	_camera_yaw = move_toward(_camera_yaw, _target_yaw, TURN_SPEED * delta)
	_update_camera(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and bool(SettingsManager.get_value("mouse_camera_control", false)):
		var sensitivity := float(SettingsManager.get_value("mouse_sensitivity", 0.5))
		var invert := -1.0 if bool(SettingsManager.get_value("invert_y", false)) else 1.0
		_target_yaw -= event.relative.x * sensitivity * 0.0025
		_mouse_pitch = clampf(_mouse_pitch + event.relative.y * sensitivity * 0.0025 * invert, -0.35, 0.48)
		_queued_yaw = 0.0

func refresh_cursor_state() -> void:
	if get_tree() != null and get_tree().paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif bool(SettingsManager.get_value("mouse_camera_control", false)):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _queue_orbit(direction: float) -> void:
	if bool(SettingsManager.get_value("mouse_camera_control", false)):
		return
	var step := deg_to_rad(float(SettingsManager.get_value("camera_rotation_step", 20.0)))
	_queued_yaw += step * direction

func _update_camera(delta: float) -> void:
	var focus := global_position + Vector3(0.0, FOCUS_HEIGHT, 0.0)
	var horizontal_distance := _camera_distance * cos(_mouse_pitch)
	var vertical_offset := (_camera_height - FOCUS_HEIGHT) + _camera_distance * sin(_mouse_pitch)
	var offset := Vector3(sin(_camera_yaw) * horizontal_distance, vertical_offset, cos(_camera_yaw) * horizontal_distance)
	var desired := focus + offset
	if _collision_avoidance:
		var query := PhysicsRayQueryParameters3D.create(focus, desired)
		query.exclude = [get_rid()]
		query.collide_with_areas = false
		var result := get_world_3d().direct_space_state.intersect_ray(query)
		if not result.is_empty():
			desired = result.position + result.normal * 0.22
	var smoothing := 1.0 - exp(-maxf(_follow_speed, 0.1) * 9.0 * delta)
	_camera.global_position = _camera.global_position.lerp(desired, smoothing)
	_camera.look_at(focus, Vector3.UP)
	_camera.fov = _fov

func _update_interactable() -> void:
	var origin := global_position + Vector3(0.0, 1.35, 0.0)
	var direction := -_camera.global_transform.basis.z
	var reach := float(SettingsManager.get_value("interaction_range", 2.5))
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * reach)
	query.exclude = [get_rid()]
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	var new_target: Node
	if not result.is_empty():
		var collider := result.get("collider") as Node
		if is_instance_valid(collider) and collider.is_in_group("interactables"):
			new_target = collider
	_interactable = new_target
	var prompt := ""
	if is_instance_valid(_interactable) and bool(SettingsManager.get_value("show_interaction_prompts", true)):
		prompt = String(_interactable.call("get_interaction_prompt"))
	if prompt != _last_prompt:
		_last_prompt = prompt
		interaction_prompt_changed.emit(prompt)

func _apply_settings(settings: Dictionary) -> void:
	_camera_distance = float(settings.get("camera_distance", 4.0))
	_camera_height = float(settings.get("camera_height", 1.6))
	_follow_speed = float(settings.get("camera_follow_speed", 0.8))
	_fov = float(settings.get("field_of_view", 70.0))
	_collision_avoidance = bool(settings.get("camera_collision", true))
	refresh_cursor_state()

func _setup_character_animations(character: Node) -> void:
	var players := character.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		push_warning("Explorer rig imported without an AnimationPlayer; using the model without animation.")
		return
	_character_animation_player = players[0] as AnimationPlayer
	for animation_name in ["Idle", "Walk", "Run"]:
		if _character_animation_player.has_animation(animation_name):
			_character_animation_player.get_animation(animation_name).loop_mode = Animation.LOOP_LINEAR
	_update_character_animation(false, false)

func _update_character_animation(is_moving: bool, is_running: bool) -> void:
	if not is_instance_valid(_character_animation_player):
		return
	var animation_name := "Idle"
	if is_moving:
		animation_name = "Run" if is_running else "Walk"
	if animation_name == _current_character_animation or not _character_animation_player.has_animation(animation_name):
		return
	_current_character_animation = animation_name
	_character_animation_player.play(animation_name, 0.18)
