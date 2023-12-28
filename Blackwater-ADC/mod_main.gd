extends Node

const AUTHORNAME_MODNAME_DIR := "Blackwater-ADC"
const AUTHORNAME_MODNAME_LOG_NAME := AUTHORNAME_MODNAME_DIR + ":Main"

var mod_dir_path := ""
var extensions_dir_path := ""

func _init(mod_loader = ModLoader) -> void:
	mod_dir_path = ModLoaderMod.get_unpacked_dir().path_join(AUTHORNAME_MODNAME_DIR)
	extensions_dir_path = mod_dir_path.path_join("extensions")
	install_script_extensions()

func install_script_extensions() -> void:
	ModLoaderMod.install_script_extension(extensions_dir_path.path_join("Globals/GameManager.gd"))
	ModLoaderMod.install_script_extension(extensions_dir_path.path_join("Globals/Progression.gd"))
	ModLoaderMod.install_script_extension(extensions_dir_path.path_join("Scripts/Menus/DressingRoom.gd"))
	# Uncomment this as soon as the modloader actually works a bit, then delete the accompanying Scripts folder.
#	ModLoaderMod.install_script_extension(extensions_dir_path.path_join("Scripts/Save/Settings.gd"))
#	ModLoaderMod.install_script_extension(extensions_dir_path.path_join("Scripts/Hosts/ChainBot/ChainBot.gd"))
#	ModLoaderMod.install_script_extension(extensions_dir_path.path_join("Scripts/Hosts/FlameBot/FlameBot.gd"))
#	ModLoaderMod.install_script_extension(extensions_dir_path.path_join("Scripts/Hosts/ShotgunBot/ShotgunBot.gd"))
#	ModLoaderMod.install_script_extension(extensions_dir_path.path_join("Scripts/Hosts/WheelBot/WheelBot.gd"))
#	ModLoaderMod.install_script_extension(extensions_dir_path.path_join("Scripts/Hosts/Enemy.gd"))

func _ready() -> void:
	ModLoaderLog.info("Ready!", AUTHORNAME_MODNAME_LOG_NAME)
