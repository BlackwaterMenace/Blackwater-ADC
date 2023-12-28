extends "res://Scripts/Hosts/WheelBot/WheelBot.gd"

@onready var arm_overlay = $ArmOverlay

#Delete and use the one in Enemy.gd when that's possible
@onready var skin_overlay = $SkinOverlay

#For some reason this mod messes up the spawn animation unless this is here
func _ready():
	super._ready()
	play_animation('Spawn')

#Delete and use the one in Enemy.gd when that's possible
func update_look_direction(dir):
	super.update_look_direction(dir)
	if dir > 0:
		skin_overlay.flip_h = false
		skin_overlay.offset.x = 0
	else:
		skin_overlay.flip_h = true
		skin_overlay.offset.x = flip_offset
#When Enemy.gd extension is possible, move the above stuff there and uncomment this:
#func update_look_direction(dir):
#	super.update_look_direction(dir)
	if dir > 0:
		arm_overlay.flip_h = false
		arm_overlay.offset.x = 0
		arm_overlay.position.x = -8
	else:
		arm_overlay.flip_h = true
		arm_overlay.offset.x = arm_flip_offset
		arm_overlay.position.x = -6

func toggle_enhancement(state):
	super.toggle_enhancement(state)
	var upgrades_to_apply = get_currently_applicable_upgrades()
	if upgrades_to_apply['shaped_charges'] > 0:
		arm_overlay.texture = load(GameManager.player_router_skin_overlay_path["sprite_sheet_path_arm_shaped"])

func misc_update(delta):
	super.misc_update(delta)
	if flow_state:
			if flow_state_damage_mult > 1:
				arm_overlay.modulate = Color.RED
			else:
				arm_overlay.modulate = Color(1,1,1,1)

func handle_skin():
	super.handle_skin()
	if is_player:
		skin_overlay.texture = load(GameManager.player_router_skin_overlay_path["sprite_sheet_path_main"])
		arm_overlay.texture = load(GameManager.player_router_skin_overlay_path["sprite_sheet_path_arm"])
		return
	skin_overlay.texture = load("")
	arm_overlay.texture = load("")

