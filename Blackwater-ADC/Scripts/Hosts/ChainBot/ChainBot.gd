extends Enemy

const GhostImage = preload('res://Scenes/Utilities/GhostImage.tscn')
const Projectilizer = preload('res://Scenes/Violence/EntityProjectilizer.tscn')

@onready var grapple = $Grapple
@onready var attack_area = $AttackCollider
@onready var attack_collider = $AttackCollider/AttackShape
@onready var attack_sprite = $AttackCollider/AttackSprite
@onready var charged_attack_sprite = $AttackCollider/ChargedAttackSprite
@onready var audio = $AudioStreamPlayer2D
@onready var attack_audio = $AttackAudio
@onready var juggle_audio_player = $JuggleAudio
@onready var arms_animation = $AnimationPlayerArms
@onready var arm_sprite = $Arm
@onready var punch_aim_indicator = $Sights
@onready var launch_aim_indicator = $Sights2


#SKIN PATHS
var default_body_skin_path = "res://Art/Characters/ChainbotRAM/upper&lower 107x109.png"
var default_arm_skin_path = "res://Art/Characters/ChainbotRAM/reel 107x109.png"
var gold_body_skin_path = "res://Art/Characters/ChainbotRAM/upper&lower 107x109 Gold.png"
var gold_arm_skin_path = "res://Art/Characters/ChainbotRAM/reel 107x109 Gold.png"
var grey_body_skin_path = "res://Art/Characters/ChainbotRAM/upper&lower 107x109 Grey.png"
var grey_arm_skin_path = "res://Art/Characters/ChainbotRAM/reel 107x109 Grey.png"
var blue_body_skin_path = "res://Art/Characters/ChainbotRAM/upper&lower 107x109 Blue.png"
var blue_arm_skin_path = "res://Art/Characters/ChainbotRAM/reel 107x109 Blue.png"

var juggle_1 = preload("res://Sounds/SoundEffects/Tom/ChainBot/RAM_chainJuggle1.wav")
var juggle_2 = preload("res://Sounds/SoundEffects/Tom/ChainBot/RAM_chainJuggle2.wav")
var juggle_3 = preload("res://Sounds/SoundEffects/Tom/ChainBot/RAM_chainJuggle3.wav")
var juggle_finisher = preload("res://Sounds/SoundEffects/Tom/ChainBot/RAM_chainJuggleFinish.wav")
var juggle_array = [juggle_1, juggle_2, juggle_3, juggle_finisher]

var charge_sound = preload("res://Sounds/SoundEffects/Tom/ChainBot/RAM_chainbotMeleeChargeLoop.wav")
var attack_sound = preload("res://Sounds/SoundEffects/Tom/ChainBot/RAM_chainbotMeleeHit.wav")

var num_pellets = 5
var walk_speed
var shot_speedd
var charge_speed
var charge_damage
var grapple_hit_kb
var init_charge
var bullet_type = 'wave'

var walk_speed_levels = [130, 140, 150, 160, 180, 190, 200]
var charge_speed_levels = [1.0, 1.2, 1.4, 1.6, 2.0, 2.1, 2.2]
#var init_charge_levels = [0.3, 0.1, 0.2, 0.25, 0.3, 0.4, 0.5]
var charge_damage_levels = [40, 40, 50, 60, 70, 80, 90]
var grapple_hit_kb_levels = [500, 500, 520, 540, 560, 580, 600]
var quickstep_cooldown_levels = [5, 0.1, 3.5, 3, 2.66, 2.33, 2]
var grapple_force_levels = [15, 18, 20, 22, 24, 26, 28]

var kb_mult = 1
var damage_mult = 1

var speed_while_charging = 20

var grapple_launch_speed = 400


#--------------- UPGRADES ----------
var footwork = false
var reverse_grapple = false
var grapple_stun = 0
var whiplash = false

#--------------- End UPGRADES ----------

var charging = false
var charge_level = 0.0
var charge_time = 0.0
const MIN_CHARGE_TIME_TO_LAUNCH = 0.16
var min_charge_time_to_launch_mult = 1.0

var attack_direction : Vector2

var can_combo = false
var combo_buffered = false

var juggle_combo = 0
var juggle_timer = 0.0
var grapple_timer = 1.0

var toggle_grapple_mode := false
var double_tap_timer = 0.0
var grapple_stun_timer = 0.0
var tug_timer = 0.0
var grappled_entity_afterimage_timer = 0.0
var melee_hitbox_active = false
var allow_friendly_fire = false

var hit_entities = []


func _ready():
	enemy_type = EnemyType.CHAIN
	max_health = 100
	bullet_spawn_offset = 20
	flip_offset = -20
	super._ready()
	handle_skin()
	max_attack_cooldown = 0.6
	play_animation('Spawn')
	toggle_enhancement(false)


func toggle_playerhood(state):
	super.toggle_playerhood(state)
	if state and spawn_state == SpawnState.SPAWNED:
		punch_aim_indicator.visible = SaveManager.settings.deadlift_aiming_reticle
		launch_aim_indicator.visible = SaveManager.settings.deadlift_aiming_reticle
	else:
		punch_aim_indicator.visible = false
		launch_aim_indicator.visible = false

	
	if charging:
		if is_instance_valid(grapple.anchor_entity):
			aim_direction = (grapple.anchor_entity.global_position - global_position).normalized()
		begin_melee_attack()

func toggle_enhancement(state):
	attack_collider.scale = Vector2.ONE*(1.0 if state else 0.8)
	
	var level = 1 if is_player else 0
	walk_speed = walk_speed_levels[level]
	max_speed = walk_speed
	charge_speed = 1.0
	charge_damage = charge_damage_levels[level]
	grapple_hit_kb = grapple_hit_kb_levels[level]
	init_charge = 0.0
	max_special_cooldown = quickstep_cooldown_levels[level]
	grapple.retract_force = grapple_force_levels[level]
	grapple.segment_retract_interval = 0.03
	
	kb_mult = 1.0
	damage_mult = 1.0
	speed_while_charging = 20
	grapple_stun = 0
	grapple_launch_speed = 400
	footwork = false
	reverse_grapple = false
	var upgrades_to_apply = get_currently_applicable_upgrades()
	
	charge_damage *= 1.0 + 0.3*upgrades_to_apply['weakpoint_database']
	
	grapple_hit_kb *= 1.0 + 0.1*upgrades_to_apply['precompressed_hydraulics']
	
	grapple.retract_force *= 1.0 + 0.3*upgrades_to_apply['upgeared_winch']
	min_charge_time_to_launch_mult = 1.0 - 0.1*upgrades_to_apply['upgeared_winch']
	
	grapple_launch_speed *= 1.0 + upgrades_to_apply['cable_management']*0.5
	grapple.segment_retract_interval /= 1.0 + upgrades_to_apply['cable_management']*0.5
	
	footwork = upgrades_to_apply['footwork_scheduler'] > 0
	speed_while_charging += (walk_speed - speed_while_charging)*upgrades_to_apply['footwork_scheduler']*0.5
	
	max_speed *= 1.0 + 0.15*upgrades_to_apply['leg_day_hallucination']
	
	grapple_stun = upgrades_to_apply['frayed_wires']
	
	if upgrades_to_apply['yorikiri'] > 0:
		mass = 5.0
		grapple.retract_force *= 0.75 #compensates for grapple physics effects
		
	if upgrades_to_apply['hassotobi'] > 0:
		reverse_grapple = true
	
	whiplash = upgrades_to_apply['whiplash']
	super.toggle_enhancement(state)
	handle_skin()

func misc_update(delta):
	super.misc_update(delta)
	update_timers(delta)
	update_juggle_combo()
	update_grapple_stun(delta)
	
	if charging:
		charge_time += delta
		charge_level += delta*charge_speed
		
	elif melee_hitbox_active:
		process_melee_hits()

func player_action():
	if Input.is_action_pressed("attack1") and not can_combo and attack_cooldown < 0 and not attacking and not reviving:
		begin_charging()
		
	elif not Input.is_action_pressed("attack1") and charging:
		begin_melee_attack()
			
	if grapple.state == grapple.ANCHORED:
		if SaveManager.settings.toggle_grapple:
			if Input.is_action_just_pressed('attack2'):
				toggle_grapple_mode = !toggle_grapple_mode
			toggle_grapple_tug(toggle_grapple_mode)
		else:
			toggle_grapple_tug(Input.is_action_pressed('attack2'))
		if SaveManager.settings.auto_ungrapple:
			if grapple_timer < 0:
				grapple.retract(false)
		else:
			if Input.is_action_just_pressed('attack2'):
				if double_tap_timer > 0:
					grapple.retract(false)
				else:
					double_tap_timer = 0.2
				
	elif Input.is_action_just_pressed('attack2'):
		if grapple.state == grapple.LAUNCHED:
			grapple.retract(false)
		else:
			launch_grapple(aim_direction)
	if Input.is_action_pressed('attack2'):
		grapple_timer = 1.0
		
	update_aim_indicators()
			

func handle_skin():
	if not upgrades.is_empty():
		if 'whiplash' in upgrades:
			sprite.texture = load(blue_body_skin_path)
			arm_sprite.texture = load(blue_arm_skin_path)
			return
		if 'hassotobi' in upgrades:
			sprite.texture = load(gold_body_skin_path)
			arm_sprite.texture = load(gold_arm_skin_path)
			return
		if 'yorikiri' in upgrades:
			sprite.texture = load(grey_body_skin_path)
			arm_sprite.texture = load(grey_arm_skin_path)
			return
	elif is_player:
		skin_overlay.texture = load(GameManager.player_deadlift_skin_overlay_path["sprite_sheet_path_upperbody"])
		arm_overlay.texture = load(GameManager.player_deadlift_skin_overlay_path["sprite_sheet_path_arm"])
		if GameManager.player_deadlift_skin_path != "":
			sprite.texture = load(GameManager.player_deadlift_skin_path)
			if "Grey" in GameManager.player_deadlift_skin_path:
				arm_sprite.texture = load(grey_arm_skin_path)
			elif "Gold" in GameManager.player_deadlift_skin_path:
				arm_sprite.texture = load(gold_arm_skin_path)
			elif "Blue" in GameManager.player_deadlift_skin_path:
				arm_sprite.texture = load(blue_arm_skin_path)
			return
	sprite.texture = load(default_body_skin_path)
	arm_sprite.texture = load(default_arm_skin_path)
	skin_overlay.texture = load("")
	arm_overlay.texture = load("")

func animate():
	super.animate()
	arm_sprite.frame = sprite.frame
	if grapple.state != grapple.INACTIVE:
		arm_sprite.visible = false
	else:
		arm_sprite.visible = true
	if aim_direction.x > 0:
		arm_sprite.flip_h = false
		arm_sprite.offset.x = 0
		grapple.position.x = -10
	else:
		arm_sprite.flip_h = true
		arm_sprite.offset.x = flip_offset
		grapple.position.x = 10
	arm_overlay.frame = arm_sprite.frame
	arm_overlay.visible = arm_sprite.visible
	arm_overlay.flip_h = arm_sprite.flip_h
	arm_overlay.offset.x = arm_sprite.offset.x
	arm_overlay.position.x = arm_sprite.position.x

#func play_animation(anim_name, force_restart = true):
#	if not dead and not stunned:
#		#this is super weird, if the player swaps in the animations are desycned.
#		#arms_animation.play(anim_name)
#		animplayer.play(anim_name)

func update_timers(delta):
	double_tap_timer -= delta
	juggle_timer -= delta
	grappled_entity_afterimage_timer -= delta
	if grapple.state == grapple.ANCHORED:
		grapple_timer -= delta
	
	if not grapple.tugged:
		tug_timer -= delta

func update_juggle_combo():
	if juggle_timer < 0:
		juggle_combo = 0
		
	elif juggle_combo > 0 and grappled_entity_afterimage_timer < 0 and has_grappled_entity():
		grappled_entity_afterimage_timer = 0.05
		spawn_grappled_entity_afterimage()

func update_grapple_stun(delta):
	if grapple_stun > 0 and is_instance_valid(grapple.anchor_entity):
		grapple_stun_timer -= delta
		if grapple_stun_timer < 0:
			grapple_stun_timer = 0.5
			var grapple_stun_attack = Attack.new(self, 0)
			grapple_stun_attack.stun = 1.0
			grapple_stun_attack.inflict_on(grapple.anchor_entity)

func launch_grapple(dir):
	grapple.launch(dir.normalized()*grapple_launch_speed)
	play_animation("Launch")
	attacking = true
	grapple_stun_timer = 0
	
func grapple_deactivated():
	pass
#	play_animation("Retract")
#	attacking = true

func toggle_grapple_tug(state):
	grapple.tugged = state
	if state == true: tug_timer = 0.1

func begin_charging():
	charging = true
	attacking = true
	lock_aim = not is_player
	attack_audio.stream = charge_sound
	attack_audio.play()
	apply_effect(EffectType.SPEED_OVERRIDE, self, speed_while_charging)
	#charge_started_during_quickstep = quickstep_timer > 0.3 and not charge_started_during_quickstep
	charge_level = init_charge
	charge_time = 0.0
	play_animation("Charge")
	if ControllerIcons._last_input_type == ControllerIcons.InputType.CONTROLLER and is_player:
		Input.start_joy_vibration(0, 0.2, 0, 4)

func begin_melee_attack(hit_allies = false):
	allow_friendly_fire = hit_allies
	hit_entities.clear()
	
	if not charging:
		charge_level = init_charge
	
	charging = false
	attacking = true
	melee_hitbox_active = true
	attack_cooldown = max_attack_cooldown# if combo else 0
	hit_entities.clear()

	if has_grappled_entity() and tug_timer > 0:
		attack_direction = global_position.direction_to(grapple.anchor_entity.global_position)
	else:
		attack_direction = aim_direction
	
	attack_area.rotation = attack_direction.angle()
	attack_audio.stream = attack_sound
	attack_audio.play()
	
	if is_player:
		GameManager.camera.set_trauma(min(0.3 + charge_level*0.2, 1))
	if ControllerIcons._last_input_type == ControllerIcons.InputType.CONTROLLER and is_player:
		Input.start_joy_vibration(0, 0, 1, 0.2)
		
	if footwork:
		velocity += attack_direction*300
	if whiplash:
		Violence.shoot_flak_bullet(self, global_position + aim_direction*bullet_spawn_offset, aim_direction*500, 20, 1, 4, bullet_type, 0, 0, 0, bullet_type)

# Called by animation trigger
func disable_melee_hitbox():
	melee_hitbox_active = false

#NEEDS REFACTOR
func process_melee_hits():
	charge_level = min(1.0, charge_level)
	var charged = charge_time >= MIN_CHARGE_TIME_TO_LAUNCH*min_charge_time_to_launch_mult #charge_level >= 0.16
	
	if ControllerIcons._last_input_type == ControllerIcons.InputType.CONTROLLER and is_player:
		Input.start_joy_vibration(0, 0, 0.5, 0.2)
		
	var melee_attack = Attack.new(self)
	melee_attack.damage = 10 + charge_damage*charge_level*damage_mult
	melee_attack.impulse = aim_direction*(200 + 500*charge_level)*kb_mult
	melee_attack.deflect_type = Attack.DeflectType.REPULSE
	melee_attack.deflect_speed_mult = 1.0 + charge_level
	melee_attack.hit_allies = allow_friendly_fire
	melee_attack.add_tag(Attack.Tag.MELEE)
	melee_attack.ignored = hit_entities
	melee_attack.ignored.append(self)
	
	if charged:
		play_animation('ChargedAttack')
		charged_attack_sprite.play()
	else:
		play_animation('Attack')
		attack_sprite.play()
	
	var hits = Violence.melee_attack(attack_collider, melee_attack)
	for entity in hits:
		hit_entities.append(entity)
		
	#If grappled entity is hit while being pulled in, the hit becomes a grapple boost
	if has_grappled_entity() and tug_timer > 0 and grapple.anchor_entity in hits:
		tug_timer = 0.0
		var grappled = grapple.anchor_entity
		var rel_speed = (velocity - (grappled.velocity - melee_attack.impulse/grappled.mass)).length()#.project(global_position - grapple.anchor_entity.global_position).length()
			
		attack_cooldown = 0.0
		var rebound_vel = Vector2.ZERO#-grappled_kb_vel
		var heavy_enemy = grappled.mass > mass*1.5
		
		var grappled_kb_vel = aim_direction
		if heavy_enemy:
			grappled_kb_vel = grappled_kb_vel.length()*aim_direction.normalized()#grappled_kb_vel = aim_direction.rotated(clamp(Util.unsigned_wrap(aim_direction.angle() - grappled_kb_vel.angle()), -PI/6, PI/6))*grappled_kb_vel.length()
		
		#Charged hits break the grappled state and launch the enemy
		if charged:
			handle_juggle_audio(3)
			var finisher_attack = Attack.new(self, pow(juggle_combo, 1.3))
			finisher_attack.damage *= (15 if heavy_enemy else 8)
			finisher_attack.inflict_on(grappled)
			if ControllerIcons._last_input_type == ControllerIcons.InputType.CONTROLLER and is_player:
				Input.start_joy_vibration(0, 0, 0.7, 0.2)
			grappled_kb_vel *= grapple_hit_kb*(1.0 + juggle_combo*0.3) + rel_speed*(0.25 if reverse_grapple else 0.1) 
			#print('1: ', grapple_hit_kb*(1.0 + juggle_combo*0.3))
			#print('2: ', rel_speed*(0.25 if reverse_grapple else 0.1) )
			
			launch_grappled_entity()
			if was_recently_player():
				GameManager.set_timescale(0.001, 0.2, 100)
			
		#Uncharged hits juggle the enemy and maintain grappled state	
		else:
			juggle_timer = 1.0
			juggle_combo = min(juggle_combo + 1, 3)
			handle_juggle_audio(min(juggle_combo, 2))
			grappled_kb_vel *= grapple_hit_kb*(1.0 + juggle_combo*0.1)*(0.8 if reverse_grapple else 1.0) + rel_speed*0.1
			GameManager.set_timescale(0.001, 0.05, 1000)
			
		rebound_vel = -grappled_kb_vel*0.3
		
		#If enemy is heavy, launch self backward	
		if heavy_enemy:
			if not charged:
				rebound_vel = -grappled_kb_vel
				grappled_kb_vel = -rebound_vel*0.5
			
		var effective_grappled_mass = grappled.mass if grappled.mass  <= 1.0 else (1.0 + (grappled.mass - 1.0)/mass)
		grappled.velocity = grappled_kb_vel / effective_grappled_mass
		velocity = rebound_vel / mass

func handle_juggle_audio(juggle_hit):
	juggle_audio_player.volume_db = juggle_hit + 1
	juggle_audio_player.stream = juggle_array[juggle_hit]
	juggle_audio_player.play()

func launch_grappled_entity():
	if not has_grappled_entity(): return
	
	var grappled = grapple.anchor_entity
	grapple.retract(false)
	toggle_grapple_tug(false)
	
	var projectilizer = Projectilizer.instantiate()
	projectilizer.initialize(self, inflict_grapple_launch_collision_damage)
	projectilizer.lifetime = 0.5
	projectilizer.override_accel = 1.0
	grappled.add_child(projectilizer)
	
func inflict_grapple_launch_collision_damage(collider, collidee):
	if collider == collidee: return
	var v1 = collider.velocity if 'velocity' in collider else Vector2.ZERO
	var v2 = collidee.velocity if 'velocity' in collidee else Vector2.ZERO
	if v1.is_zero_approx() and v2.is_zero_approx(): return
	
	var m1 = max(collider.mass, 0.1) if 'mass' in collider else 1.0
	var m2 = max(collidee.mass, 0.1) if 'mass' in collidee else 1.0
	
	# Canonical "direction" of collision is set to the direction of the faster moving entity
	# The slower entity's velocity is projected onto this direction to get its effective collision speed
	# The slower entity's speed will be negative if it's moving in a similar direction to the faster entity
	var v1_aligned = v1
	var v2_aligned = v2
	var s1
	var s2
	if v1.length_squared() > v2.length_squared():
		v2_aligned = v2.project(v1)
		s1 = v1_aligned.length()
		s2 = v2_aligned.length() * sign(v1.dot(v2))
	else:
		v1_aligned = v1.project(v2)
		s1 = v1_aligned.length() * sign(v1.dot(v2))
		s2 = v2_aligned.length()
	
	var force1 = m1*s1
	var force2 = m2*s2
	if force1 + force2 < 150: return
	
	var mass_ratio1 = m1/m2
	var mass_ratio2 = m2/m1
	var DAMAGE_PER_FORCE = 0.15
	
	var collidee_damage = (force1 + (mass_ratio1/(1 + mass_ratio1))*force2)*DAMAGE_PER_FORCE
	var collider_damage = ((mass_ratio2/(1 + mass_ratio2))*force1 + force2)*DAMAGE_PER_FORCE*0.5
	var blood_amount = (collider_damage + collidee_damage)*0.5
	var blood_origin = (collider.global_position + collidee.global_position)/2
	var blood_vel = 20*sqrt(s1 + s2)*v1_aligned.normalized().orthogonal()
	
	var collidee_attack = Attack.new(self, collidee_damage)
	collidee_attack.stun = grapple_stun
	collidee_attack.override_blood_amount = blood_amount
	collidee_attack.override_blood_origin = blood_origin
	collidee_attack.override_blood_velocity = blood_vel
	collidee_attack.add_tag(Attack.Tag.PHYSICS)
	collidee_attack.bonuses.append(Fitness.Bonus.LIVE_AMMO)
	
	var collider_attack = Attack.new(self, collider_damage)
	collider_attack.override_blood_amount = blood_amount
	collider_attack.override_blood_origin = blood_origin
	collider_attack.override_blood_velocity = -blood_vel
	collider_attack.add_tag(Attack.Tag.PHYSICS)
	collider_attack.bonuses.append(Fitness.Bonus.DEAD_AMMO)
	
	if not collidee_attack.inflict_on(collidee): return
	
	collider_attack.inflict_on(collider)
	collider.velocity = (m1 - m2)/(m1 + m2)*v1 + 2*m2/(m1 + m2)*v2
	if 'velocity' in collidee:
		collidee.velocity = (m2 - m1)/(m1 + m2)*v2 + 2*m1/(m1 + m2)*v1

func spawn_grappled_entity_afterimage():
	var ghost_sprite = grapple.anchor_entity.get('sprite')
	if not ghost_sprite: return
	
	var new_ghost = GhostImage.instantiate()
	get_parent().add_child(new_ghost)
	new_ghost.copy_sprite(ghost_sprite)
	new_ghost.set_lifetime(0.4)
	if juggle_combo > 0:
		var color = [Color.YELLOW, Color.ORANGE, Color.RED][clamp(juggle_combo - 1, 0, 2)]
		new_ghost.material.set_shader_parameter('color', color)
		new_ghost.material.set_shader_parameter('intensity', 0.5)
		
func update_aim_indicators():
	var angle = aim_direction.angle() + PI*0.5
	
	if has_grappled_entity():
		punch_aim_indicator.rotation = global_position.angle_to_point(grapple.anchor_entity.global_position) + PI*0.5
		if SaveManager.settings.deadlift_aiming_reticle:
			launch_aim_indicator.visible = true
			launch_aim_indicator.global_position = grapple.anchor_entity.global_position
			launch_aim_indicator.rotation = angle
	else:
		punch_aim_indicator.rotation = angle
		launch_aim_indicator.visible = false

func has_grappled_entity() -> bool:
	return is_instance_valid(grapple.anchor_entity)
	
func finish_spawning():
	super()
	if SaveManager.settings.deadlift_aiming_reticle and is_player:
		punch_aim_indicator.visible = true
		launch_aim_indicator.visible = true
	
func reset_body_state():
	charging = false
	grapple.deactivate()
	super()

func revive():
	reset_body_state()
	super.revive()
	if SaveManager.settings.deadlift_aiming_reticle and is_player:
		punch_aim_indicator.visible = true
		launch_aim_indicator.visible = true

func take_damage(attack):
	if has_grappled_entity() and tug_timer > 0.0 and is_instance_valid(attack.causality.original_source) and grapple.anchor_entity == attack.causality.original_source:
		attack.bonuses.append(Fitness.Bonus.JOUST)
	if not is_player:
		grapple.retract(false)
	super(attack)

func die(attack = null):
	grapple.retract(false)
	disable_melee_hitbox()
	punch_aim_indicator.visible = false
	launch_aim_indicator.visible = false
	super.die(attack)

func _on_animation_finished(anim_name):
	super(anim_name)
	if anim_name == "Launch" or anim_name == "Retract":
		attacking = false
	if anim_name == "Attack" or anim_name == "ChargedAttack":
		attacking = false
		lock_aim = false
		can_combo = false
		cancel_effect(EffectType.SPEED_OVERRIDE, self)

@onready var arm_overlay = $ArmOverlay
