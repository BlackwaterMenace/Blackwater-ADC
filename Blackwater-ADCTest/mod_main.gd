extends Node

const AUTHORNAME_MODNAME_DIR := "Blackwater-ADCTest"
const AUTHORNAME_MODNAME_LOG_NAME := AUTHORNAME_MODNAME_DIR + ":Main"

var mod_dir_path := ""

func _init(mod_loader = ModLoader) -> void:
	pass

func add_overlays():
	#Progression.add_{Bot name}_overlay(mod_name, overlay_name)
	#Always pass AUTHORNAME_MODNAME_DIR as the first param; it's needed so the game knows what directory the sprites are in
	Progression.add_steeltoe_overlay(AUTHORNAME_MODNAME_DIR, "Test")
	Progression.add_router_overlay(AUTHORNAME_MODNAME_DIR, "Test")
	Progression.add_aphid_overlay(AUTHORNAME_MODNAME_DIR, "Test")
	Progression.add_deadlift_overlay(AUTHORNAME_MODNAME_DIR, "Test")

func _ready() -> void:
	add_overlays()
	ModLoaderLog.info("Ready!", AUTHORNAME_MODNAME_LOG_NAME)
