extends "res://Scripts/Hosts/ChainBot/ChainBot.gd"

@onready var arm_overlay = $ArmOverlay

#Delete and use the one in Enemy.gd when that's possible
@onready var skin_overlay = $SkinOverlay

#Delete and use the one in Enemy.gd when that's possible
func update_look_direction(dir):
	super.update_look_direction(dir)
	if dir > 0:
		skin_overlay.flip_h = false
		skin_overlay.offset.x = 0
	else:
		skin_overlay.flip_h = true
		skin_overlay.offset.x = flip_offset

func handle_skin():
	super.handle_skin()
	if is_player:
		skin_overlay.texture = load(GameManager.player_deadlift_skin_overlay_path["sprite_sheet_path_upperbody"])
		arm_overlay.texture = load(GameManager.player_deadlift_skin_overlay_path["sprite_sheet_path_arm"])
	
	skin_overlay.texture = load("")
	arm_overlay.texture = load("")

func animate():
	super.animate()
	arm_overlay.frame = arm_sprite.frame
	arm_overlay.visible = arm_sprite.visible
	arm_overlay.flip_h = arm_sprite.flip_h
	arm_overlay.offset.x = arm_sprite.offset.x
	arm_overlay.position.x = arm_sprite.position.x