extends "res://Scripts/Hosts/ShotgunBot/ShotgunBot.gd"

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
		skin_overlay.texture = load(GameManager.player_steeltoe_skin_overlay_path["sprite_sheet_path"])
		return
	skin_overlay.texture = load("")
