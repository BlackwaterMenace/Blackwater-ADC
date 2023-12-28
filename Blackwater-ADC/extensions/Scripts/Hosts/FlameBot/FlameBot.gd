extends "res://Scripts/Hosts/FlameBot/FlameBot.gd"

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

func update_overheat_visual():
	super.update_overheat_visual()
	if sprite.material == default_material:
		var critical_level = 1.0 - 0.7*heat_buildup_rate
		var intensity
		if heat_buildup < critical_level: 
			intensity = pow(heat_buildup/critical_level, 1.5)
		elif not is_exploding:
			intensity = 1.0 + pow(sin((heat_buildup - critical_level)/heat_buildup_rate/0.7*3*PI), 2)
		else:
			intensity = 1.0 if int(GameManager.game_time*10) % 2 == 0 else 10.0
			if is_player:
				GameManager.camera.set_trauma(0.3)
		skin_overlay.material.set_shader_parameter('intensity', intensity)

func handle_skin():
	super.handle_skin()
	if is_player:
		skin_overlay.texture = load(GameManager.player_aphid_skin_overlay_path["sprite_sheet_path"])
		return
	skin_overlay.texture = load("")
