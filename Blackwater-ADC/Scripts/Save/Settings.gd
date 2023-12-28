extends Resource
class_name Settings

class Resolution:
	var x = 0
	var y = 0
	
	func _init(x_y):
		if is_instance_of(x_y, Resolution):
			x = x_y.x
			y = x_y.y
		else:
			x = x_y[0]
			y = x_y[1]
	
	func serialize():
		return [x, y]
		
	func equals(other):
		return (x == other.x and y == other.y)
		

# Most common from https://store.steampowered.com/hwsurvey/
enum SUPPORTED_RESOLUTIONS {
	R640360,
	R1280720,
	R1366768,
	R1440900,
	R19201080,
	R25601440,
	R34562234, # This is my mac's resolution
	R38402160
}

var RESOLUTION_MAPPINGS : Dictionary = {
	SUPPORTED_RESOLUTIONS.R640360: Resolution.new([640, 360]),
	SUPPORTED_RESOLUTIONS.R1280720: Resolution.new([1280, 720]),
	SUPPORTED_RESOLUTIONS.R1366768: Resolution.new([1366, 768]),
	SUPPORTED_RESOLUTIONS.R1440900: Resolution.new([1440, 900]),
	SUPPORTED_RESOLUTIONS.R19201080: Resolution.new([1920, 1080]),
	SUPPORTED_RESOLUTIONS.R25601440: Resolution.new([2560, 1440]),
	SUPPORTED_RESOLUTIONS.R34562234: Resolution.new([3456, 2234]),
	SUPPORTED_RESOLUTIONS.R38402160: Resolution.new([3840, 2160])
}

# This probably isn't necessary, but it does expose an interface for consumers
# of this data for what keys are available, so it's probably worth.
const MASTER_VOLUME_KEY = 'master_volume'
const MUSIC_VOLUME_KEY = 'music_volume'
const EFFECTS_VOLUME_KEY = 'effects_volume'
const MASTER_MUTE_KEY = 'master_mute'
const MUSIC_MUTE_KEY = 'music_mute'
const EFFECTS_MUTE_KEY = 'effects_mute'
const RESOLUTION_KEY = 'resolution'
const FULLSCREEN_KEY = 'fullscreen'
const GAMEPAD_MODE_KEY = 'gamepad_mode'
const KEYBINDS_KEY = 'keybinds'
const CONTROLLER_BINDS_KEY = 'controller_binds'
#ACCESSIBILITY
const SHOW_EXTRA_HUD_KEY = 'show_extra_hud'
const ASSIST_MODE_KEY = 'assist_mode'
const TOGGLE_GRAPPLE_KEY = 'toggle_grapple'
const AUTO_UNGRAPPLE_KEY = 'auto_ungrapple'
const AUTO_SHOTGUN_KEY = 'auto_shotgun'
const DEBUG_TOOLS_KEY = 'debug_tools'
const BEGINNER_MODE_KEY = 'beginner_mode'
const SCREEN_SHAKE_DISABLE_KEY = "screen_shake_disable"

#GAMEPLAY
const AIM_LINE_KEY = "aim_line"
const STEELTOE_AIMING_RETICLE_KEY = "steeltoe_aiming_reticle"
const ROUTER_AIMING_RETICLE_KEY = "router_aiming_reticle"
const APHID_AIMING_RETICLE_KEY = "aphid_aiming_reticle"
const DEADLIFT_AIMING_RETICLE_KEY = "deadlift_aiming_reticle"
const LOCAL_JUICE_ABOVE_HOST_KEY = "local_juice_above_host"

#SKINS
const STEELTOE_SKIN_KEY = 'steeltoe_skin'
const ROUTER_SKIN_KEY = 'router_skin'
const APHID_SKIN_KEY = 'aphid_skin'
const DEADLIFT_SKIN_KEY = 'deadlift_skin'

#OVERLAYS
const STEELTOE_OVERLAY_KEY = 'steeltoe_overlay'
const ROUTER_OVERLAY_KEY = 'router_overlay'
const APHID_OVERLAY_KEY = 'aphid_overlay'
const DEADLIFT_OVERLAY_KEY = 'deadlift_overlay'
const STEELTOE_OVERLAY_DEFAULT := 0
const ROUTER_OVERLAY_DEFAULT := 0
const APHID_OVERLAY_DEFAULT := 0
const DEADLIFT_OVERLAY_DEFAULT := 0
var steeltoe_overlay := STEELTOE_OVERLAY_DEFAULT
var router_overlay := ROUTER_OVERLAY_DEFAULT
var aphid_overlay := APHID_OVERLAY_DEFAULT
var deadlift_overlay := DEADLIFT_OVERLAY_DEFAULT

const MASTER_VOLUME_DEFAULT := 0.5
const MUSIC_VOLUME_DEFAULT := 0.5
const EFFECTS_VOLUME_DEFAULT := 0.5
const MASTER_MUTE_DEFAULT := false
const MUSIC_MUTE_DEFAULT := false
const EFFECTS_MUTE_DEFAULT := false
const RESOLUTION_DEFAULT := [1920, 1080]
const FULLSCREEN_DEFAULT := true
const GAMEPAD_MODE_DEFAULT := false
const SHOW_EXTRA_HUD_DEFAULT := false
const ASSIST_MODE_DEFAULT := false
const TOGGLE_GRAPPLE_DEFAULT := false
const AUTO_UNGRAPPLE_DEFAULT := false
const AUTO_SHOTGUN_DEFAULT := false
const DEBUG_TOOLS_DEFAULT := false
const BEGINNER_MODE_DEFAULT := false
const SCREEN_SHAKE_DISABLE_DEFAULT := false

const AIM_LINE_DEFAULT := true
const STEELTOE_AIMING_RETICLE_DEFAULT := true
const ROUTER_AIMING_RETICLE_DEFAULT := true
const APHID_AIMING_RETICLE_DEFAULT := true
const DEADLIFT_AIMING_RETICLE_DEFAULT := true
const LOCAL_JUICE_ABOVE_DEFAULT := true

const STEELTOE_SKIN_DEFAULT := 0
const ROUTER_SKIN_DEFAULT := 0
const APHID_SKIN_DEFAULT := 0
const DEADLIFT_SKIN_DEFAULT := 0

@export var master_volume := MASTER_VOLUME_DEFAULT
@export var music_volume := MUSIC_VOLUME_DEFAULT
@export var effects_volume := EFFECTS_VOLUME_DEFAULT
@export var master_mute := MASTER_MUTE_DEFAULT
@export var music_mute := MUSIC_MUTE_DEFAULT
@export var effects_mute := EFFECTS_MUTE_DEFAULT
var resolution := Resolution.new(RESOLUTION_DEFAULT)
@export var fullscreen := FULLSCREEN_DEFAULT
@export var gamepad_mode := GAMEPAD_MODE_DEFAULT
var keybinds : Bindings = KeyBindings.new()
var controller_binds : Bindings = ControllerBindings.new()
@export var show_extra_hud := SHOW_EXTRA_HUD_DEFAULT
@export var assist_mode := ASSIST_MODE_DEFAULT
@export var toggle_grapple := TOGGLE_GRAPPLE_DEFAULT
@export var auto_ungrapple := AUTO_UNGRAPPLE_DEFAULT
@export var auto_shotgun := AUTO_SHOTGUN_DEFAULT
@export var debug_tools := DEBUG_TOOLS_DEFAULT
@export var beginner_mode := BEGINNER_MODE_DEFAULT
@export var screen_shake_disable := SCREEN_SHAKE_DISABLE_DEFAULT

var aim_line := AIM_LINE_DEFAULT
var steeltoe_aiming_reticle := STEELTOE_AIMING_RETICLE_DEFAULT
var router_aiming_reticle := ROUTER_AIMING_RETICLE_DEFAULT
var aphid_aiming_reticle := APHID_AIMING_RETICLE_DEFAULT
var deadlift_aiming_reticle := DEADLIFT_AIMING_RETICLE_DEFAULT
var local_juice_above_host := LOCAL_JUICE_ABOVE_DEFAULT

var steeltoe_skin := STEELTOE_SKIN_DEFAULT
var router_skin := ROUTER_SKIN_DEFAULT
var aphid_skin := APHID_SKIN_DEFAULT
var deadlift_skin := DEADLIFT_SKIN_DEFAULT

var deserializers = [deserialize_v2]

func set_resolution(res : Resolution):
	resolution = res

func get_resolution_from_index(index) -> Resolution:
	return RESOLUTION_MAPPINGS[index]

func get_resolution_from_enum(enum_val) -> Resolution:
	return RESOLUTION_MAPPINGS[SUPPORTED_RESOLUTIONS.get(enum_val)]

func get_current_resolution_index():
	for enum_val in RESOLUTION_MAPPINGS.keys():
		if resolution.equals(RESOLUTION_MAPPINGS[enum_val]):
			return enum_val
	print("As far as I know we shouldn't hit this. This means we've set our resolution to something weird and unexpected.")
	return -1

func show_extra_hud_info(state):
	show_extra_hud = state

func apply_resolution_settings():
	ProjectSettings.set_setting("display/window/size/width", resolution.x)
	ProjectSettings.set_setting("display/window/size/test_width", resolution.x)
	ProjectSettings.set_setting("display/window/size/width", resolution.y)
	ProjectSettings.set_setting("display/window/size/test_height", resolution.y)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_size(Vector2i(resolution.x, resolution.y))
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
func apply_audio_settings():
	AudioServer.set_bus_volume_db(0, linear_to_db(0.0 if master_mute else master_volume))
	AudioServer.set_bus_volume_db(1, linear_to_db(0.0 if music_mute else music_volume))
	AudioServer.set_bus_volume_db(2, linear_to_db(0.0 if effects_mute else effects_volume))
	
func apply_keybind_settings():
	var keybinds_json = keybinds.serialize()
	for key in keybinds_json.keys():
		var scancode = keybinds_json[key]
		if not scancode:
			return
		var actionlist = InputMap.action_get_events(key)
		if actionlist:
			var count = 0
			for action in actionlist:
				if action is InputEventKey or action is InputEventMouseButton:
					InputMap.action_erase_event(key, actionlist[count])
					break
				count += 1
		var new_input_event
		if scancode < 10:
			new_input_event = InputEventMouseButton.new()
			new_input_event.button_index = scancode
		else:
			new_input_event = InputEventKey.new()
			new_input_event.keycode = scancode
		InputMap.action_add_event(key, new_input_event)
		
func apply_controller_settings():
	controller_binds.apply()
		

func serialize() -> Dictionary:
	return {
		MASTER_VOLUME_KEY: master_volume,
		MUSIC_VOLUME_KEY: music_volume,
		EFFECTS_VOLUME_KEY: effects_volume,
		MASTER_MUTE_KEY: master_mute,
		MUSIC_MUTE_KEY: music_mute,
		EFFECTS_MUTE_KEY: effects_mute,
		RESOLUTION_KEY: resolution.serialize(),
		FULLSCREEN_KEY: fullscreen,
		GAMEPAD_MODE_KEY: gamepad_mode,
		KEYBINDS_KEY: keybinds.serialize(),
		CONTROLLER_BINDS_KEY: controller_binds.serialize(),
		SHOW_EXTRA_HUD_KEY: show_extra_hud,
		ASSIST_MODE_KEY : assist_mode,
		TOGGLE_GRAPPLE_KEY : toggle_grapple,
		AUTO_UNGRAPPLE_KEY: auto_ungrapple,
		AUTO_SHOTGUN_KEY: auto_shotgun,
		DEBUG_TOOLS_KEY: debug_tools,
		BEGINNER_MODE_KEY: beginner_mode,
		SCREEN_SHAKE_DISABLE_KEY: screen_shake_disable,
		AIM_LINE_KEY: aim_line,
		STEELTOE_AIMING_RETICLE_KEY: steeltoe_aiming_reticle,
		ROUTER_AIMING_RETICLE_KEY: router_aiming_reticle,
		APHID_AIMING_RETICLE_KEY: aphid_aiming_reticle,
		DEADLIFT_AIMING_RETICLE_KEY: deadlift_aiming_reticle,
		LOCAL_JUICE_ABOVE_HOST_KEY: local_juice_above_host,
		STEELTOE_SKIN_KEY: steeltoe_skin,
		ROUTER_SKIN_KEY: router_skin,
		APHID_SKIN_KEY: aphid_skin,
		DEADLIFT_SKIN_KEY: deadlift_skin,
		STEELTOE_OVERLAY_KEY: steeltoe_overlay,
		ROUTER_OVERLAY_KEY: router_overlay,
		APHID_OVERLAY_KEY: aphid_overlay,
		DEADLIFT_OVERLAY_KEY: deadlift_overlay,
	}
	
func deserialize(serialized_dict : Dictionary) -> Settings:
	var settings = false
	for deserializer in deserializers:
		settings = deserializer.call(serialized_dict)
		if settings:
			return settings
	# This is where we can implement and call new deserializers if the save
	# data changes dramatically and the default/main deserializer fails
	return settings

func deserialize_v2(serialized_dict : Dictionary) -> Settings:
	master_volume = serialized_dict.get(MASTER_VOLUME_KEY, MASTER_VOLUME_DEFAULT)
	music_volume = serialized_dict.get(MUSIC_VOLUME_KEY, MUSIC_VOLUME_DEFAULT)
	effects_volume = serialized_dict.get(EFFECTS_VOLUME_KEY, EFFECTS_VOLUME_DEFAULT)
	master_mute = serialized_dict.get(MASTER_MUTE_KEY, MASTER_MUTE_DEFAULT)
	music_mute = serialized_dict.get(MUSIC_MUTE_KEY, MUSIC_MUTE_DEFAULT)
	effects_mute = serialized_dict.get(EFFECTS_MUTE_KEY, EFFECTS_MUTE_DEFAULT)
	resolution = Resolution.new(serialized_dict.get(RESOLUTION_KEY, RESOLUTION_DEFAULT))
	fullscreen = serialized_dict.get(FULLSCREEN_KEY, FULLSCREEN_DEFAULT)
	gamepad_mode = serialized_dict.get(GAMEPAD_MODE_KEY, GAMEPAD_MODE_DEFAULT)
	keybinds.deserialize(serialized_dict.get(KEYBINDS_KEY, KeyBindings.new().serialize()))
	controller_binds.deserialize(serialized_dict.get(CONTROLLER_BINDS_KEY, ControllerBindings.new().serialize()))
	show_extra_hud = serialized_dict.get(SHOW_EXTRA_HUD_KEY, SHOW_EXTRA_HUD_DEFAULT)
	assist_mode = serialized_dict.get(ASSIST_MODE_KEY, ASSIST_MODE_DEFAULT)
	toggle_grapple = serialized_dict.get(TOGGLE_GRAPPLE_KEY, TOGGLE_GRAPPLE_DEFAULT)
	auto_ungrapple = serialized_dict.get(AUTO_UNGRAPPLE_KEY, AUTO_UNGRAPPLE_DEFAULT)
	auto_shotgun = serialized_dict.get(AUTO_SHOTGUN_KEY, AUTO_SHOTGUN_DEFAULT)
	debug_tools = serialized_dict.get(DEBUG_TOOLS_KEY, DEBUG_TOOLS_DEFAULT)
	beginner_mode = serialized_dict.get(BEGINNER_MODE_KEY, BEGINNER_MODE_DEFAULT)
	screen_shake_disable = serialized_dict.get(SCREEN_SHAKE_DISABLE_KEY, SCREEN_SHAKE_DISABLE_DEFAULT)
	aim_line = serialized_dict.get(AIM_LINE_KEY, AIM_LINE_DEFAULT)
	steeltoe_aiming_reticle = serialized_dict.get(STEELTOE_AIMING_RETICLE_KEY, STEELTOE_AIMING_RETICLE_DEFAULT)
	router_aiming_reticle = serialized_dict.get(ROUTER_AIMING_RETICLE_KEY, ROUTER_AIMING_RETICLE_DEFAULT)
	aphid_aiming_reticle = serialized_dict.get(APHID_AIMING_RETICLE_KEY, APHID_AIMING_RETICLE_DEFAULT)
	deadlift_aiming_reticle = serialized_dict.get(DEADLIFT_AIMING_RETICLE_KEY, DEADLIFT_AIMING_RETICLE_DEFAULT)
	local_juice_above_host = serialized_dict.get(LOCAL_JUICE_ABOVE_HOST_KEY, LOCAL_JUICE_ABOVE_DEFAULT)
	steeltoe_skin = serialized_dict.get(STEELTOE_SKIN_KEY, STEELTOE_SKIN_DEFAULT)
	router_skin = serialized_dict.get(ROUTER_SKIN_KEY, ROUTER_SKIN_DEFAULT)
	aphid_skin = serialized_dict.get(APHID_SKIN_KEY, APHID_SKIN_DEFAULT)
	deadlift_skin = serialized_dict.get(DEADLIFT_SKIN_KEY, DEADLIFT_SKIN_DEFAULT)
	steeltoe_overlay = serialized_dict.get(STEELTOE_OVERLAY_KEY, STEELTOE_OVERLAY_DEFAULT)
	router_overlay = serialized_dict.get(ROUTER_OVERLAY_KEY, ROUTER_OVERLAY_DEFAULT)
	aphid_overlay = serialized_dict.get(APHID_OVERLAY_KEY, APHID_OVERLAY_DEFAULT)
	deadlift_overlay = serialized_dict.get(DEADLIFT_OVERLAY_KEY, DEADLIFT_OVERLAY_DEFAULT)
	if steeltoe_overlay >= Progression.steeltoe_skin_overlays.size() || steeltoe_overlay < 0:
		steeltoe_overlay = STEELTOE_OVERLAY_DEFAULT
	if router_overlay >= Progression.router_skin_overlays.size() || router_overlay < 0:
		router_overlay = ROUTER_OVERLAY_DEFAULT
	if aphid_overlay >= Progression.aphid_skin_overlays.size() || aphid_overlay < 0:
		aphid_overlay = APHID_OVERLAY_DEFAULT
	if deadlift_overlay >= Progression.deadlift_skin_overlays.size() || deadlift_overlay < 0:
		deadlift_overlay = DEADLIFT_OVERLAY_DEFAULT
	return self
