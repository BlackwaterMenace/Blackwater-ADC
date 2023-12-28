extends Enemy

@onready var muzzle_flash = $MuzzleFlash
@onready var audio = $StepAudio
@onready var gun_audio = $GunAudio
@onready var spawn_audio = $SpawnAudio
@onready var reload = $Reload
@onready var melee_audio = $MeleeAudio
@onready var melee_collider = $MeleeCollider
@onready var melee_collider_shape = $MeleeCollider/CollisionShape2D
@onready var melee_sprite = $SpecialSprite
@onready var aim_indicator = $AimIndicator

var shot_speed
var num_pellets
var melee_damage

var walk_speed_level = [110, 120, 130, 140, 150, 160, 180]
var shot_speed_level = [175, 500, 500, 500, 500, 500, 500]
var num_pellets_level = [5, 6, 7, 8, 9, 10, 11, 13]
var reload_time_level = [1.5, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
var melee_damage_level = [20, 20, 25, 30, 35, 40, 45]

var max_shells = 1
var loaded_shells = max_shells
var bullet_spread = 15
var bullet_kb = 0.3
var bullet_type = 'pellet'
var bullet_damage = 9
var recoil = 180
var melee_stun = 0
var melee_boost_window_mult

var default_skin_path = "res://Art/Characters/ShotgunnerRAM/OG 63x113.png"
var red_skin_path = "res://Art/Characters/ShotgunnerRAM/Red 63x113.png"
var blue_skin_path = "res://Art/Characters/ShotgunnerRAM/blue 63x113.png"
var yellow_skin_path = "res://Art/Characters/ShotgunnerRAM/yellow 63x113.png"

#---------Upgrades-------------

var full_auto = false
var flak_mode = false
var butt_stock = false

#---------End Upgrades-------------
var max_range = 250
var ai_can_shoot = false
var ai_move_timer = 0
var ai_shoot_timer = 0
var ai_target_point = Vector2.ZERO

var self_parry_damage_due = false

var charging_melee := false
var melee_charge_duration = 0.3
var melee_charge_timer := 0.0

var reload_audio_preempt_interval = 0.25
var reload_audio_has_played = false


# Called when the node enters the scene tree for the first time.
func _ready():
	enemy_type = EnemyType.SHOTGUN
	max_health = 75
	accel = 10
	bullet_spawn_offset = 10
	vertical_bullet_spawn_offset = -3
	flip_offset = 24
	max_special_cooldown = 1.5
	attack_cooldown_audio_preempt = 0.2
	aim_indicator.visible = false
	play_animation('Spawn')
	super._ready()
	toggle_enhancement(false)
	handle_skin()
	
func toggle_playerhood(state):
	super(state)
	if state and spawn_state == SpawnState.SPAWNED:
		aim_indicator.visible = SaveManager.settings.steeltoe_aiming_reticle
	else:
		aim_indicator.visible = false
# As far as I can tell here state is really is_player?
func toggle_enhancement(state):
	var level = 1 if is_player else 0
	max_speed = walk_speed_level[level]
	shot_speed = shot_speed_level[level]
	num_pellets = num_pellets_level[level]
	max_attack_cooldown = reload_time_level[level]
	bullet_damage = 9
	melee_damage = 30#melee_damage_level[level]
	melee_stun = 0.5
	melee_collider.scale = Vector2.ONE
	melee_boost_window_mult = 1.0
	
	max_shells = 1
	bullet_type = 'pellet'
	bullet_kb = 0.3
	bullet_spread = 15
	melee_stun = 0
	recoil = 180
	full_auto = false
	flak_mode = false
	handle_skin()
	var upgrades_to_apply = get_currently_applicable_upgrades()

	#aggroed = false

	for i in range(upgrades_to_apply['ammo_conservation']):
		num_pellets += 1
		shot_speed *= 0.9
	
	shot_speed *= 1.0 + 0.15*upgrades_to_apply['impulse_chamber']
	bullet_damage += upgrades_to_apply['impulse_chamber']
		
	for i in range(upgrades_to_apply['recoil_compensation']):
		bullet_spread *= 0.7
		
	melee_collider.scale *= 1.0 + 0.25*upgrades_to_apply['bass_boost']
	melee_sprite.scale = Vector2(1 ,1)
	melee_sprite.scale *= 1.0 + 0.25*upgrades_to_apply['bass_boost']
	
	max_speed *= 1.0 + 0.15*upgrades_to_apply['digitigrade_optimization']
		
	melee_stun += upgrades_to_apply['resonance']
	
	melee_boost_window_mult += 0.7*upgrades_to_apply['metronome_heartbeat']
		
	full_auto = (upgrades_to_apply['reload_coroutine'] > 0 or SaveManager.settings.auto_shotgun)
	for i in range(upgrades_to_apply['reload_coroutine']):
		max_attack_cooldown *= 0.8
		
	max_shells += upgrades_to_apply['stacked_shells']
#	bullet_spread *= 1.0 + upgrades_to_apply['stacked_shells']
#	max_attack_cooldown *= 1.0 + 0.5*pow(upgrades_to_apply['stacked_shells'], 0.8)
#	recoil *= 1.0 + 1.0*upgrades_to_apply['stacked_shells']
		
	if upgrades_to_apply['induction_barrel'] > 0:
		bullet_type = 'flame'
		bullet_kb = 0.15
		bullet_damage *= 0.9
		
	flak_mode = upgrades_to_apply['soldering_fingers'] > 0
	
	loaded_shells = max_shells
	super.toggle_enhancement(state)
	
func misc_update(delta):
	super.misc_update(delta)
	melee_collider.rotation = aim_direction.angle()
	melee_charge_timer -= delta
	
	if loaded_shells < max_shells:
		if not reload_audio_has_played and attack_cooldown < reload_audio_preempt_interval:
			reload_audio_has_played = true
			reload.play()
		if attack_cooldown < 0:
			reload_audio_has_played = false
			if loaded_shells < max_shells - 1:
				attack_cooldown = max_attack_cooldown*pow(0.75, min(loaded_shells, 3))
			loaded_shells += 1
			
		
func player_action():
	if (Input.is_action_just_pressed("attack1") or (full_auto and Input.is_action_pressed("attack1"))) and loaded_shells > 0:
		shoot()
		
	if Input.is_action_just_pressed("attack2") and special_cooldown < 0:
		start_melee()
		
	update_aim_indicators()
		
func handle_skin():
	print("Piss")
	if not upgrades.is_empty():
		if 'induction_barrel' in upgrades:
			sprite.texture = load(red_skin_path)
			return
		if "soldering_fingers" in upgrades:
			sprite.texture = load(blue_skin_path)
			return
			#TODO Maybe pick a better upgrade?
		if "reload_coroutine" in upgrades:
			sprite.texture = load(yellow_skin_path)
			return
	elif is_player:
		if GameManager.player_steeltoe_skin_path != "":
			sprite.texture = load(GameManager.player_steeltoe_skin_path)
			skin_overlay.texture = load(GameManager.player_steeltoe_skin_overlay_path["sprite_sheet_path"])
			return
	sprite.texture = load(default_skin_path)
	skin_overlay.texture = load("")

	
func finish_spawning():
	super()
	if SaveManager.settings.steeltoe_aiming_reticle and is_player:
		aim_indicator.visible = true
		
func shoot():
	gun_audio.play()
	attacking = true
	attack_cooldown = max_attack_cooldown
	show_muzzle_flash()
	
	if not charging_melee:
		play_animation("Shoot")
	
	velocity -= aim_direction*recoil*loaded_shells
	
	var melee_boost = clamp(1.0 - abs(melee_charge_timer)*5.0, 0.0, 1.0)
	#print('Unmodified melee boost: ', melee_boost)
	if melee_boost < 0.3:
		melee_boost = 0.0
	else:
		melee_boost = min(1.0, melee_boost + 0.1*(melee_boost_window_mult - 1.0))
	#print('Modified melee boost: ', melee_boost)
	
	if ControllerIcons._last_input_type == ControllerIcons.InputType.CONTROLLER and is_player:
		Input.start_joy_vibration(0, 1, 1, 0.1)
	velocity -= aim_direction*recoil
	var damage = bullet_damage
	var spread = bullet_spread*loaded_shells
	var speed = shot_speed
	var tint = Color(1.15, 1.15, 1.15)
	
	if melee_boost > 0:
		damage *= 1.65
		
		#perfect boost
		if melee_boost > 0.9:
			spread*= 0.33
			speed *= 2
			tint = Color('ff7af9')
			
		#imperfect_boost
		else:
			spread *= 2.0
			speed *= 1.5
			tint = Color.YELLOW
	
	if is_player:
		GameManager.camera.set_trauma(0.55, 5)
	if flak_mode:
		for i in range(loaded_shells):
			var slug_spread = max(0, (spread - 15))
			var dir = aim_direction.rotated((randf()-0.5)*deg_to_rad(slug_spread))
			var frag_amount = num_pellets*1.5 #if not bullet_type == 'flame' else num_pellets 
			var bullet = Violence.shoot_flak_bullet(self, global_position + aim_direction*bullet_spawn_offset, dir*speed, damage*4, bullet_kb*4, 4, bullet_type, frag_amount, damage, speed*0.66, bullet_type)
			bullet.modulate = tint
			bullet.pierce_decay = 0.33
			
			if melee_boost > 0.0:
				bullet.frag_spread = PI/2
				if melee_boost < 0.9:
					bullet.lifetime = 0.1
	else:
		for i in range(num_pellets*loaded_shells):
			var pellet_dir = aim_direction.rotated((randf()-0.5)*deg_to_rad(spread))
			var pellet_speed = speed * (1 + 0.5*(randf()-0.5))
			var bullet = shoot_bullet(pellet_dir*pellet_speed, damage, bullet_kb, 4, bullet_type)
			bullet.modulate = tint
			bullet.pierce_decay = 0.25
			
		
	loaded_shells = 0		
	if melee_boost > 0:
		apply_melee_boost_aftereffects(melee_boost)
				
func apply_melee_boost_aftereffects(boost):
	apply_effect(EffectType.ACCEL_MULT, self, 0.3, 0.25 if boost > 0.9 else 0.15)
	velocity -= aim_direction.normalized()*100*boost
	if boost > 0.9:
		GameManager.set_timescale(0.001, 0.15, 100)
				

func show_muzzle_flash():
	muzzle_flash.rotation = aim_direction.angle();
	melee_sprite.rotation = aim_direction.angle()
	muzzle_flash.show_behind_parent = muzzle_flash.rotation < deg_to_rad(-30) and muzzle_flash.rotation > deg_to_rad(-150)
	muzzle_flash.frame = 0
	muzzle_flash.play("Flash")
	gun_particles.position.x = -13 if facing_left else 13
	gun_particles.rotation = muzzle_flash.rotation
	gun_particles.emitting = true
	
func start_melee():
	attacking = true
	charging_melee = true
	melee_charge_timer = melee_charge_duration
	#lock_aim = true
	special_cooldown = max_special_cooldown
	play_animation('Special')
	melee_audio.play()
	melee_sprite.show_behind_parent = melee_sprite.rotation < deg_to_rad(-30) and melee_sprite.rotation > deg_to_rad(-150)
	apply_effect(EffectType.SPEED_OVERRIDE, self, 50)
	velocity += 250*(aim_direction if target_velocity.length() < 0.5 else velocity.normalized())
		
func inflict_self_parry_damage():
	if not self_parry_damage_due: return
	self_parry_damage_due = false
	
	attacking = false
	lock_aim = false
	
	
	var self_attack = Attack.new(self, 15, -aim_direction*400)
	self_attack.hit_allies = true
	self_attack.stun = 1.0
	self_attack.inflict_on(self)
	
func melee():
	if is_player:
		GameManager.camera.set_trauma(0.6)
	velocity -= 250*aim_direction.normalized()
	var melee_attack = Attack.new(self, melee_damage)
	melee_attack.stun = melee_stun
	melee_attack.impulse = 1000
	melee_attack.deflect_type = Attack.DeflectType.TARGET_SOURCE
	melee_attack.deflect_speed_mult = 3.0
	melee_attack.deflect_damage_mult = 2.0
	melee_attack.deflect_added_stun = melee_stun
	melee_attack.bonuses.append(Fitness.Bonus.MELEE)
	melee_sprite.rotation = aim_direction.angle()
	melee_sprite.play()
	Violence.melee_attack(melee_collider_shape, melee_attack)
	
func die(attack):
	super(attack)
	aim_indicator.visible = false

func revive():
	super()
	if SaveManager.settings.steeltoe_aiming_reticle and is_player:
		aim_indicator.visible = true

	
func update_aim_indicators():
	aim_indicator.set_spread(deg_to_rad(bullet_spread*loaded_shells))
	aim_indicator.set_direction(aim_direction)
	
func _on_animation_finished(anim_name):
	super(anim_name)
	if anim_name == "Shoot":
		attacking = false
	elif anim_name == 'Special':
		attacking = false
		lock_aim = false
		charging_melee = false
		cancel_effect(EffectType.SPEED_OVERRIDE, self)

func _on_Timer_timeout():
	invincible = false
