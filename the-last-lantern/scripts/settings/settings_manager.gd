extends Node

signal settings_changed(values: Dictionary)

const CONFIG_PATH := "user://settings.cfg"
const DEFAULTS := {
	"camera_rotation_step": 20.0,
	"mouse_camera_control": false,
	"mouse_sensitivity": 0.5,
	"invert_y": false,
	"field_of_view": 70.0,
	"show_interaction_prompts": true,
	"interaction_range": 2.5,
	"camera_follow_speed": 0.8,
	"camera_height": 1.6,
	"camera_distance": 4.0,
	"camera_collision": true,
	"display_mode": "Maximized",
	"resolution": "1440x810",
	"vsync": true,
	"graphics_quality": "High",
	"master_volume": 1.0,
	"music_volume": 0.8,
	"sfx_volume": 0.8,
	"ui_scale": 1.0,
}

var values: Dictionary = {}

func _ready() -> void:
	_ensure_input_actions()
	_ensure_audio_buses()
	values = DEFAULTS.duplicate(true)
	_load_config()
	_apply_runtime()

func get_value(key: String, fallback: Variant = null) -> Variant:
	return values.get(key, fallback)

func get_values_copy() -> Dictionary:
	return values.duplicate(true)

func apply_values(new_values: Dictionary, save_to_disk: bool = false) -> void:
	values = DEFAULTS.duplicate(true)
	for key in new_values:
		if DEFAULTS.has(key):
			values[key] = new_values[key]
	_apply_runtime()
	if save_to_disk:
		_save_config()
	settings_changed.emit(values.duplicate(true))

func reset_to_saved() -> void:
	values = DEFAULTS.duplicate(true)
	_load_config()
	_apply_runtime()
	settings_changed.emit(values.duplicate(true))

func _load_config() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return
	for key in DEFAULTS:
		values[key] = config.get_value("settings", key, DEFAULTS[key])

func _save_config() -> void:
	var config := ConfigFile.new()
	for key in DEFAULTS:
		config.set_value("settings", key, values.get(key, DEFAULTS[key]))
	var error := config.save(CONFIG_PATH)
	if error != OK:
		push_warning("Could not save game settings: %s" % error_string(error))

func _apply_runtime() -> void:
	var mode := String(values.get("display_mode", "Windowed"))
	if mode == "Fullscreen":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif mode == "Maximized":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var resolution := _parse_resolution(String(values.get("resolution", "1440x810")))
		DisplayServer.window_set_size(resolution)
		var screen_size := DisplayServer.screen_get_size()
		DisplayServer.window_set_position((screen_size - resolution) / 2)
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if bool(values.get("vsync", true)) else DisplayServer.VSYNC_DISABLED
	)
	_apply_quality()
	_apply_audio()
	if is_inside_tree() and get_tree() != null:
		get_tree().root.content_scale_factor = float(values.get("ui_scale", 1.0))

func _apply_quality() -> void:
	if not is_inside_tree() or get_tree() == null:
		return
	var quality := String(values.get("graphics_quality", "High"))
	var viewport := get_tree().root
	match quality:
		"Low":
			viewport.msaa_3d = Viewport.MSAA_DISABLED
			viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		"Medium":
			viewport.msaa_3d = Viewport.MSAA_2X
			viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
		_:
			viewport.msaa_3d = Viewport.MSAA_4X
			viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA

func _apply_audio() -> void:
	for pair in [["Master", "master_volume"], ["Music", "music_volume"], ["SFX", "sfx_volume"]]:
		var bus_index := AudioServer.get_bus_index(pair[0])
		if bus_index >= 0:
			var linear := clampf(float(values.get(pair[1], 1.0)), 0.0, 1.0)
			AudioServer.set_bus_mute(bus_index, linear <= 0.001)
			AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(linear, 0.001)))

func _ensure_audio_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, "Master")

func _ensure_input_actions() -> void:
	_add_key_action("move_forward", KEY_W)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_backward", KEY_S)
	_add_key_action("move_right", KEY_D)
	_add_key_action("camera_orbit_left", KEY_Q)
	_add_key_action("camera_orbit_right", KEY_E)
	_add_key_action("interact", KEY_F)
	_add_key_action("pause", KEY_ESCAPE)

func _add_key_action(action_name: String, key_code: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.physical_keycode == key_code:
			return
	var key_event := InputEventKey.new()
	key_event.physical_keycode = key_code
	InputMap.action_add_event(action_name, key_event)

func _parse_resolution(value: String) -> Vector2i:
	var parts := value.split("x")
	if parts.size() != 2:
		return Vector2i(1440, 810)
	return Vector2i(maxi(int(parts[0]), 640), maxi(int(parts[1]), 360))
