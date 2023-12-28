extends "res://Scripts/Menus/DressingRoom.gd"

var current_skin_overlay
var current_skin_overlay_selection
@onready var osp = $Panel/HBoxContainer/MarginContainer/OverlaySelectPortrait

func _ready():
	character = $Panel/HBoxContainer/MarginContainer/Character
	super._ready()

func set_bot(type):
	match type:
		Enemy.EnemyType.SHOTGUN:
			current_skin_overlay_selection = Progression.steeltoe_skin_overlays
			current_skin_overlay = SaveManager.settings.steeltoe_overlay
		Enemy.EnemyType.WHEEL:
			current_skin_overlay_selection = Progression.router_skin_overlays
			current_skin_overlay = SaveManager.settings.router_overlay
		Enemy.EnemyType.FLAME:
			current_skin_overlay_selection = Progression.aphid_skin_overlays
			current_skin_overlay = SaveManager.settings.aphid_overlay
		Enemy.EnemyType.CHAIN:
			current_skin_overlay_selection = Progression.deadlift_skin_overlays
			current_skin_overlay = SaveManager.settings.deadlift_overlay
	super.set_bot(type)

func update_selected_skin():
	super.update_selected_skin()
	update_selected_skin_overlay()

func _on_left_skin_overlay_pressed():
	if current_skin_overlay <= 0:
		current_skin_overlay = current_skin_overlay_selection.size() - 1
	else:
		current_skin_overlay -= 1
	update_selected_skin_overlay()

func _on_right_skin_overlay_pressed():
	if current_skin_overlay >= current_skin_overlay_selection.size() - 1:
		current_skin_overlay = 0
	else:
		current_skin_overlay += 1
	update_selected_skin_overlay()

func update_selected_skin_overlay():
	if not current_skin_selection[current_skin]["unlocked"]:
		osp.texture = load("")
	else:
		osp.texture = load(current_skin_overlay_selection[current_skin_overlay]["overlay_select_portrait_path"])
		match current_bot:
			Enemy.EnemyType.SHOTGUN:
				GameManager.player_steeltoe_skin_overlay_path = current_skin_overlay_selection[current_skin_overlay]
				SaveManager.settings.steeltoe_overlay = current_skin_overlay
			Enemy.EnemyType.WHEEL:
				GameManager.player_router_skin_overlay_path = current_skin_overlay_selection[current_skin_overlay]
				SaveManager.settings.router_overlay = current_skin_overlay
			Enemy.EnemyType.FLAME:
				GameManager.player_aphid_skin_overlay_path = current_skin_overlay_selection[current_skin_overlay]
				SaveManager.settings.aphid_overlay = current_skin_overlay
			Enemy.EnemyType.CHAIN:
				GameManager.player_deadlift_skin_overlay_path = current_skin_overlay_selection[current_skin_overlay]
				SaveManager.settings.deadlift_overlay = current_skin_overlay
