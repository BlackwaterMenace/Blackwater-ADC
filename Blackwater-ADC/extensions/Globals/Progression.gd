extends "res://Globals/Progression.gd"

#Blackwater-SkinOverlays
var steeltoe_skin_overlays := [
	{
		"name" : "Default",
		"overlay_select_portrait_path" : "",
		"sprite_sheet_path" : "",
	},
]
var deadlift_skin_overlays := [
	{
		"name" : "Default",
		"overlay_select_portrait_path" : "",
		"sprite_sheet_path_upperbody" : "",
		"sprite_sheet_path_arm" : "",
	},
]
var aphid_skin_overlays := [
	{
		"name" : "Default",
		"overlay_select_portrait_path" : "",
		"sprite_sheet_path" : "",
	},
]
var router_skin_overlays := [
	{
		"name" : "Default",
		"overlay_select_portrait_path" : "",
		"sprite_sheet_path_main" : "",
		"sprite_sheet_path_arm" : "",
		"sprite_sheet_path_arm_shaped" : "",
	},
]

const base_path = "res://mods-unpacked/%s/Art/Characters/%s/Overlays/"

func add_steeltoe_overlay(mod_name: String, overlay_name: String):
	var overlays_path = base_path % [mod_name, "ShotgunnerRAM"]
	steeltoe_skin_overlays.push_back({
		"name" : overlay_name,
		"overlay_select_portrait_path" : overlays_path + "Steeltoe" + overlay_name + "OSP.png",
		"sprite_sheet_path" : overlays_path + "Steeltoe" + overlay_name + "Main.png",
	})

func add_router_overlay(mod_name: String, overlay_name: String):
	var overlays_path = base_path % [mod_name, "WheelbotRAM"]
	router_skin_overlays.push_back({
		"name" : overlay_name,
		"overlay_select_portrait_path" : overlays_path + "Router" + overlay_name + "OSP.png",
		"sprite_sheet_path_main" : overlays_path + "Router" + overlay_name + "Main.png",
		"sprite_sheet_path_arm" : overlays_path + "Router" + overlay_name + "Arm.png",
		"sprite_sheet_path_arm_shaped" : overlays_path + "Router" + overlay_name + "Shaped.png",
	})

func add_aphid_overlay(mod_name: String, overlay_name: String):
	var overlays_path = base_path % [mod_name, "FlamebotRAM"]
	aphid_skin_overlays.push_back({
		"name" : overlay_name,
		"overlay_select_portrait_path" : overlays_path + "Aphid" + overlay_name + "OSP.png",
		"sprite_sheet_path" : overlays_path + "Aphid" + overlay_name + "Main.png",
	})
	
func add_deadlift_overlay(mod_name: String, overlay_name: String):
	var overlays_path = base_path % [mod_name, "ChainbotRAM"]
	deadlift_skin_overlays.push_back({
		"name" : overlay_name,
		"overlay_select_portrait_path" : overlays_path + "Deadlift" + overlay_name + "OSP.png",
		"sprite_sheet_path_upperbody" : overlays_path + "Deadlift" + overlay_name + "Main.png",
		"sprite_sheet_path_arm" : overlays_path + "Deadlift" + overlay_name + "Arm.png",
	})
