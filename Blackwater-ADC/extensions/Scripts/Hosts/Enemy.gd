extends "res://Scripts/Hosts/Enemy.gd"

@onready var skin_overlay = get_node_or_null("SkinOverlay")

func update_look_direction(dir):
	super.update_look_direction(dir)
	if skin_overlay != null:
		if dir > 0:
			skin_overlay.flip_h = false
			skin_overlay.offset.x = 0
		else:
			skin_overlay.flip_h = true
			skin_overlay.offset.x = flip_offset