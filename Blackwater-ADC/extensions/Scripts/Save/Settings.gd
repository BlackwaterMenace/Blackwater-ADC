extends "res://Scripts/Save/Settings.gd"

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

func serialize() -> Dictionary:
	var normal_serialized_dict = super.serialize()
	var my_dict = {
		STEELTOE_OVERLAY_KEY: steeltoe_overlay,
		ROUTER_OVERLAY_KEY: router_overlay,
		APHID_OVERLAY_KEY: aphid_overlay,
		DEADLIFT_OVERLAY_KEY: deadlift_overlay,
	}
	normal_serialized_dict.merge(my_dict, false)
	return normal_serialized_dict

func deserialize_v2(serialized_dict : Dictionary) -> Settings:
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
	return super.deserialize_v2(serialized_dict)