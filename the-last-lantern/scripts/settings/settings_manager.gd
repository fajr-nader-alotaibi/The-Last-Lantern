extends Node

signal settings_changed(values: Dictionary)

const CONFIG_PATH := "user://settings.cfg"
const KEY_ACTIONS := [
	"move_forward", "move_left", "move_backward", "move_right",
	"camera_orbit_left", "camera_orbit_right", "interact", "sprint",
]
const DEFAULT_BINDINGS := {
	"move_forward": KEY_W,
	"move_left": KEY_A,
	"move_backward": KEY_S,
	"move_right": KEY_D,
	"sprint": KEY_SHIFT,
	"camera_orbit_left": KEY_Q,
	"camera_orbit_right": KEY_E,
	"interact": KEY_F,
}
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
	"language": "English",
	"key_bindings": DEFAULT_BINDINGS,
}

const TEXT := {
	"English": {
		"subtitle": "FOUR LANTERNS. ONE WAY OUT.", "play": "PLAY", "settings": "SETTINGS", "quit": "QUIT",
		"gameplay": "GAMEPLAY", "graphics": "GRAPHICS", "audio": "AUDIO", "ui": "UI",
		"controls_overview": "CONTROLS OVERVIEW", "back": "BACK", "apply": "APPLY", "applied": "APPLIED",
		"restore_defaults": "RESTORE DEFAULTS", "restore_question": "Restore all settings and key bindings to their defaults?",
		"cancel": "CANCEL", "confirm": "RESTORE", "press_key": "Press a key…", "cancel_rebind": "Press Esc to cancel.",
		"key_conflict": "That key is already assigned to %s.", "defaults_restored": "Default settings restored. Press Apply to save them.",
		"binding_saved": "Key binding updated. Press Apply to save it.", "save_failed": "Settings changed but could not be saved.",
		"quit_title": "Leave the forest?", "quit_question": "Are you sure you want to close the game?", "on": "ON", "off": "OFF",
		"movement_camera": "MOVEMENT & CAMERA", "key_bindings": "KEY BINDINGS", "interaction": "INTERACTION", "camera_behavior": "CAMERA BEHAVIOR",
		"movement_type": "Movement Type", "sprint": "Sprint (hold)", "camera_mode": "Camera Mode", "camera_rotation": "Camera Rotation", "rotation_step": "Rotation Step",
		"mouse_control": "Mouse Camera Control", "mouse_sensitivity": "Mouse Sensitivity", "invert_y": "Invert Y Axis", "fov": "Field of View",
		"camera_follow_speed": "Camera Follow Speed", "camera_height": "Camera Height", "camera_distance": "Camera Distance", "collision_avoidance": "Collision Avoidance",
		"move_forward": "Move Forward", "move_left": "Move Left", "move_backward": "Move Backward", "move_right": "Move Right",
		"orbit_left": "Orbit Camera Left", "orbit_right": "Orbit Camera Right", "interact_use": "Interact / Use", "interaction_range": "Interaction Range",
		"show_prompts": "Show Interaction Prompts", "display": "DISPLAY", "display_mode": "Display Mode", "resolution": "Resolution", "vsync": "VSync",
		"graphics_quality": "Graphics Quality", "quality_note": "Quality controls the 3D anti-aliasing level.", "audio_levels": "AUDIO LEVELS",
		"master_volume": "Master Volume", "music_volume": "Music Volume", "sfx_volume": "Sound Effects", "preview_sound": "PREVIEW UI SOUND",
		"audio_note": "Sliders update the Master, Music, and SFX buses immediately. Add your ambience and UI sound files to hear them in-game.",
		"interface": "INTERFACE", "language": "Language", "ui_scale": "UI Scale", "language_note": "Language changes immediately. Apply saves it; Back restores the saved language.",
		"camera_guide": "Orbit around the player. Each press rotates by the selected step.", "movement_guide": "Move through the forest.",
		"interaction_guide": "Light or use the object in view.", "menu_guide": "Pause, go back, or resume.", "mouse_guide": "Mouse look is optional and off by default.",
		"first_person": "Third Person", "fullscreen": "Fullscreen", "maximized": "Maximized", "windowed": "Windowed",
		"low": "Low", "medium": "Medium", "high": "High", "arabic": "العربية", "english": "English",
		"language_english": "English", "language_arabic": "Arabic", "resolution_note": "Only sizes that fit this display are listed.",
		"lanterns": "LANTERNS", "objective_start": "WALK THE STONE PATH  ·  FIND THE FIRST LIGHT",
		"objective_split": "THE PATH HAS SPLIT  ·  FIND BOTH LIGHTS", "objective_last": "A LAST LIGHT WAITS BEYOND THE TREES",
		"objective_complete": "LEVEL I COMPLETE  ·  THE TEMPLE AWAKENS",
		"interact_lantern": "F   LIGHT LANTERN", "lantern_lit": "LANTERN ALREADY LIT",
		"interact_symbols": "F   READ THE FOUR SYMBOLS",
		"paused": "PAUSED", "resume": "RESUME", "main_menu": "MAIN MENU",
		"puzzle_title": "THE FOUR LIGHTS", "puzzle_description": "The lights remember the order in which they were kindled.",
		"puzzle_choose": "Choose the four marks in the order of the lights.",
		"puzzle_wrong": "Wrong order. The marks fade; begin again.", "puzzle_answer": "The stone answers...",
		"puzzle_release": "The final lock releases.", "symbol_moon": "MOON", "symbol_eye": "EYE",
		"symbol_tree": "TREE", "symbol_sun": "SUN", "ending_title": "THE END",
		"ending_story": "YOU WERE NEVER SUPPOSED TO LEAVE.", "return_menu": "RETURN TO MAIN MENU",
		"objective_temple": "THE LIGHTS REMEMBER THEIR ORDER  ·  FIND THE SYMBOL WALL",
	},
	"Arabic": {
		"subtitle": "أربعة فوانيس، وطريق واحد للخروج.", "play": "ابدأ", "settings": "الإعدادات", "quit": "خروج",
		"gameplay": "اللعب", "graphics": "الرسومات", "audio": "الصوت", "ui": "الواجهة",
		"controls_overview": "ملخص التحكم", "back": "رجوع", "apply": "تطبيق", "applied": "تم التطبيق",
		"restore_defaults": "استعادة الافتراضي", "restore_question": "هل تريدين استعادة الإعدادات وأزرار التحكم الافتراضية؟",
		"cancel": "إلغاء", "confirm": "استعادة", "press_key": "اضغطي زرًا…", "cancel_rebind": "اضغطي Esc للإلغاء.",
		"key_conflict": "هذا الزر مرتبط بالفعل بـ%s.", "defaults_restored": "استُعيدت الإعدادات الافتراضية. اضغطي تطبيق لحفظها.",
		"binding_saved": "تم تغيير الزر. اضغطي تطبيق لحفظه.", "save_failed": "تغيّرت الإعدادات لكن تعذّر حفظها.",
		"quit_title": "مغادرة الغابة؟", "quit_question": "هل تريدين إغلاق اللعبة؟", "on": "تشغيل", "off": "إيقاف",
		"movement_camera": "الحركة والكاميرا", "key_bindings": "تغيير الأزرار", "interaction": "التفاعل", "camera_behavior": "سلوك الكاميرا",
		"movement_type": "طريقة الحركة", "sprint": "ركض سريع (استمرار)", "camera_mode": "نمط الكاميرا", "camera_rotation": "دوران الكاميرا", "rotation_step": "مقدار الدوران",
		"mouse_control": "التحكم بالكاميرا بالفأرة", "mouse_sensitivity": "حساسية الفأرة", "invert_y": "عكس المحور Y", "fov": "مجال الرؤية",
		"camera_follow_speed": "سرعة تتبع الكاميرا", "camera_height": "ارتفاع الكاميرا", "camera_distance": "بعد الكاميرا", "collision_avoidance": "تجنب الاصطدام",
		"move_forward": "تقدم", "move_left": "تحرك يسارًا", "move_backward": "تراجع", "move_right": "تحرك يمينًا",
		"orbit_left": "أدر الكاميرا يسارًا", "orbit_right": "أدر الكاميرا يمينًا", "interact_use": "تفاعل / استخدام", "interaction_range": "مدى التفاعل",
		"show_prompts": "إظهار تلميحات التفاعل", "display": "الشاشة", "display_mode": "نمط العرض", "resolution": "دقة العرض", "vsync": "مزامنة الإطارات",
		"graphics_quality": "جودة الرسومات", "quality_note": "تتحكم الجودة بمستوى تنعيم الحواف ثلاثية الأبعاد.", "audio_levels": "مستويات الصوت",
		"master_volume": "الصوت الرئيسي", "music_volume": "الموسيقى", "sfx_volume": "المؤثرات الصوتية", "preview_sound": "معاينة صوت الواجهة",
		"audio_note": "تغيّر الأشرطة صوت Master وMusic وSFX مباشرة. أضيفي ملفات أجواء الغابة وأصوات الواجهة لسماعها داخل اللعبة.",
		"interface": "الواجهة", "language": "اللغة", "ui_scale": "حجم الواجهة", "language_note": "تتغير اللغة فورًا. تطبيق يحفظها، ورجوع يعيد اللغة المحفوظة.",
		"camera_guide": "تدور الكاميرا حول الشخصية. كل ضغطة تديرها بالمقدار المحدد.", "movement_guide": "تحركي داخل الغابة.",
		"interaction_guide": "أضيئي الفانوس أو استخدمي الشيء أمامك.", "menu_guide": "إيقاف مؤقت أو رجوع أو متابعة.", "mouse_guide": "تحكم الفأرة اختياري ومغلق افتراضيًا.",
		"first_person": "منظور الشخص الثالث", "fullscreen": "ملء الشاشة", "maximized": "مكبّرة", "windowed": "نافذة",
		"low": "منخفض", "medium": "متوسط", "high": "مرتفع", "arabic": "العربية", "english": "الإنجليزية",
		"language_english": "الإنجليزية", "language_arabic": "العربية", "resolution_note": "تُعرض الدقات المناسبة لهذه الشاشة فقط.",
		"lanterns": "الفوانيس", "objective_start": "اتبعي الطريق الحجري وابحثي عن الضوء الأول",
		"objective_split": "تفرّق الطريق؛ اعثري على الضوءين", "objective_last": "ينتظر الضوء الأخير خلف الأشجار",
		"objective_complete": "اكتمل المستوى الأول؛ استيقظ المعبد",
		"interact_lantern": "F   أضيئي الفانوس", "lantern_lit": "الفانوس مضاء بالفعل",
		"interact_symbols": "F   اقرئي الرموز الأربعة",
		"paused": "إيقاف مؤقت", "resume": "متابعة", "main_menu": "القائمة الرئيسية",
		"puzzle_title": "الأضواء الأربعة", "puzzle_description": "تتذكر الأضواء الترتيب الذي أُشعلت به.",
		"puzzle_choose": "اختاري العلامات الأربع حسب ترتيب الأضواء.",
		"puzzle_wrong": "الترتيب غير صحيح. تلاشت العلامات؛ ابدئي من جديد.", "puzzle_answer": "استجاب الحجر...",
		"puzzle_release": "انفتح القفل الأخير.", "symbol_moon": "القمر", "symbol_eye": "العين",
		"symbol_tree": "الشجرة", "symbol_sun": "الشمس", "ending_title": "النهاية",
		"ending_story": "لم يكن من المفترض أن تغادري أبدًا.", "return_menu": "العودة إلى القائمة الرئيسية",
		"objective_temple": "تتذكر الأضواء ترتيبها؛ اعثري على جدار الرموز",
	},
}

var values: Dictionary = {}
var _saved_values: Dictionary = {}
var _applied_values: Dictionary = {}

func _ready() -> void:
	_ensure_input_actions()
	_ensure_audio_buses()
	values = DEFAULTS.duplicate(true)
	_load_config()
	_saved_values = values.duplicate(true)
	_apply_runtime()

func text_for(key: String) -> String:
	var language := String(values.get("language", "English"))
	var table: Dictionary = TEXT.get(language, TEXT["English"])
	return String(table.get(key, key))

func get_value(key: String, fallback: Variant = null) -> Variant:
	return values.get(key, fallback)

func get_values_copy() -> Dictionary:
	return values.duplicate(true)

func get_saved_values_copy() -> Dictionary:
	return _saved_values.duplicate(true)

func get_default_values_copy() -> Dictionary:
	return DEFAULTS.duplicate(true)

func get_key_bindings() -> Dictionary:
	return Dictionary(values.get("key_bindings", DEFAULT_BINDINGS)).duplicate(true)

func get_key_label(action: String) -> String:
	var bindings := get_key_bindings()
	var physical_code := int(bindings.get(action, DEFAULT_BINDINGS.get(action, KEY_UNKNOWN)))
	return OS.get_keycode_string(physical_code)

func preview_values(new_values: Dictionary) -> void:
	values = _sanitize(new_values)
	_apply_runtime()
	settings_changed.emit(values.duplicate(true))

func apply_values(new_values: Dictionary, save_to_disk: bool = true) -> bool:
	values = _sanitize(new_values)
	_apply_runtime()
	var saved := false
	if save_to_disk:
		saved = _save_config()
		if saved:
			_saved_values = values.duplicate(true)
	settings_changed.emit(values.duplicate(true))
	return saved

func reset_to_saved() -> void:
	values = _saved_values.duplicate(true)
	_apply_runtime()
	settings_changed.emit(values.duplicate(true))

func _load_config() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		values = _sanitize(DEFAULTS)
		return
	var loaded := DEFAULTS.duplicate(true)
	for key in DEFAULTS:
		loaded[key] = config.get_value("settings", key, DEFAULTS[key])
	values = _sanitize(loaded)

func _save_config() -> bool:
	var config := ConfigFile.new()
	for key in DEFAULTS:
		config.set_value("settings", key, values.get(key, DEFAULTS[key]))
	var error := config.save(CONFIG_PATH)
	if error != OK:
		push_warning("Could not save game settings: %s" % error_string(error))
		return false
	return true

func _sanitize(candidate: Dictionary) -> Dictionary:
	var clean := DEFAULTS.duplicate(true)
	for key in DEFAULTS:
		if candidate.has(key):
			clean[key] = candidate[key]
	for key in ["camera_rotation_step", "mouse_sensitivity", "field_of_view", "interaction_range", "camera_follow_speed", "camera_height", "camera_distance", "master_volume", "music_volume", "sfx_volume", "ui_scale"]:
		if typeof(clean[key]) not in [TYPE_INT, TYPE_FLOAT]:
			clean[key] = DEFAULTS[key]
	clean["camera_rotation_step"] = clampf(float(clean["camera_rotation_step"]), 10.0, 45.0)
	clean["mouse_sensitivity"] = clampf(float(clean["mouse_sensitivity"]), 0.1, 1.5)
	clean["field_of_view"] = clampf(float(clean["field_of_view"]), 55.0, 95.0)
	clean["interaction_range"] = clampf(float(clean["interaction_range"]), 1.0, 4.0)
	clean["camera_follow_speed"] = clampf(float(clean["camera_follow_speed"]), 0.2, 1.0)
	clean["camera_height"] = clampf(float(clean["camera_height"]), 1.0, 2.6)
	clean["camera_distance"] = clampf(float(clean["camera_distance"]), 2.5, 7.0)
	clean["master_volume"] = clampf(float(clean["master_volume"]), 0.0, 1.0)
	clean["music_volume"] = clampf(float(clean["music_volume"]), 0.0, 1.0)
	clean["sfx_volume"] = clampf(float(clean["sfx_volume"]), 0.0, 1.0)
	clean["ui_scale"] = clampf(float(clean["ui_scale"]), 0.8, 1.2)
	for key in ["mouse_camera_control", "invert_y", "show_interaction_prompts", "camera_collision", "vsync"]:
		if typeof(clean[key]) != TYPE_BOOL:
			clean[key] = DEFAULTS[key]
	if not ["Fullscreen", "Maximized", "Windowed"].has(clean["display_mode"]):
		clean["display_mode"] = DEFAULTS["display_mode"]
	if not ["Low", "Medium", "High"].has(clean["graphics_quality"]):
		clean["graphics_quality"] = DEFAULTS["graphics_quality"]
	if not ["English", "Arabic"].has(clean["language"]):
		clean["language"] = DEFAULTS["language"]
	clean["resolution"] = _valid_resolution(String(clean["resolution"]))
	clean["key_bindings"] = _sanitize_bindings(clean["key_bindings"])
	return clean

func _sanitize_bindings(raw: Variant) -> Dictionary:
	var source: Dictionary = raw if raw is Dictionary else {}
	var result: Dictionary = {}
	var used: Dictionary = {}
	for action in KEY_ACTIONS:
		var code := int(source.get(action, DEFAULT_BINDINGS[action]))
		if code <= 0 or code == KEY_ESCAPE or used.has(code):
			code = int(DEFAULT_BINDINGS[action])
		if used.has(code):
			for fallback_action in KEY_ACTIONS:
				var fallback_code := int(DEFAULT_BINDINGS[fallback_action])
				if not used.has(fallback_code):
					code = fallback_code
					break
		result[action] = code
		used[code] = action
	return result

func _valid_resolution(value: String) -> String:
	var parts := value.split("x")
	if parts.size() != 2:
		return String(DEFAULTS["resolution"])
	var width := int(parts[0])
	var height := int(parts[1])
	if width < 640 or height < 360 or width > 7680 or height > 4320:
		return String(DEFAULTS["resolution"])
	return "%dx%d" % [width, height]

func _apply_runtime() -> void:
	var mode := String(values.get("display_mode", "Maximized"))
	if _applied_values.get("display_mode") != mode or _applied_values.get("resolution") != values.get("resolution"):
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
	if _applied_values.get("vsync") != values.get("vsync"):
		DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_ENABLED if bool(values.get("vsync", true)) else DisplayServer.VSYNC_DISABLED
		)
	if _applied_values.get("graphics_quality") != values.get("graphics_quality"):
		_apply_quality()
	if _applied_values.get("master_volume") != values.get("master_volume") or _applied_values.get("music_volume") != values.get("music_volume") or _applied_values.get("sfx_volume") != values.get("sfx_volume"):
		_apply_audio()
	if _applied_values.get("key_bindings") != values.get("key_bindings"):
		_apply_key_bindings()
	if _applied_values.get("language") != values.get("language"):
		_apply_locale()
	if _applied_values.get("ui_scale") != values.get("ui_scale") and is_inside_tree() and get_tree() != null:
		get_tree().root.content_scale_factor = float(values.get("ui_scale", 1.0))
	_applied_values = values.duplicate(true)

func _apply_locale() -> void:
	var locale := "ar" if String(values.get("language", "English")) == "Arabic" else "en"
	TranslationServer.set_locale(locale)

func _apply_quality() -> void:
	if not is_inside_tree() or get_tree() == null:
		return
	var viewport := get_tree().root
	match String(values.get("graphics_quality", "High")):
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
	for action in KEY_ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	if not InputMap.has_action("pause"):
		InputMap.add_action("pause")
	if InputMap.action_get_events("pause").is_empty():
		var escape_event := InputEventKey.new()
		escape_event.physical_keycode = KEY_ESCAPE
		InputMap.action_add_event("pause", escape_event)

func _apply_key_bindings() -> void:
	var bindings: Dictionary = values.get("key_bindings", DEFAULT_BINDINGS)
	for action in KEY_ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				InputMap.action_erase_event(action, event)
		var key_event := InputEventKey.new()
		key_event.physical_keycode = int(bindings.get(action, DEFAULT_BINDINGS[action]))
		InputMap.action_add_event(action, key_event)

func _parse_resolution(value: String) -> Vector2i:
	var parts := value.split("x")
	if parts.size() != 2:
		return Vector2i(1440, 810)
	return Vector2i(maxi(int(parts[0]), 640), maxi(int(parts[1]), 360))
