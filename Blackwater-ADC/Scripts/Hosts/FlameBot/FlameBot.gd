extends Enemy

const GasCloud = preload('res://Scenes/Hosts/FlameBot/GasCloud.tscn')
const TarPuddle = preload('res://Scenes/Violence/TarPuddle.tscn')

const flame_loop_audio = preload("res://Sounds/SoundEffects/Tom/FlameBot/RAM_flamebot_flamethrowerLoop.wav")
const flame_sputter_audio = preload("res://Sounds/SoundEffects/Tom/FlameBot/RAM_flamebot_flamethrowerRise.wav")
const tar_burning_audio = preload("res://Sounds/SoundEffects/Tom/FlameBot/RAM_flamebotBurningTarLoop.wav")

const explosion_types = {
	0: {
		num_explosions = [1],
		offsets = [0],
		sizes = [1.0],
		damages = [60],
		impulses = [1000],
	},
	1: {
		num_explosions = [1, 3],
		offsets = [0, 50],
		sizes = [1.2, 0.5],
		damages = [75, 20],
		impulses = [1100, 300],
		stagger = 0.1
	},
	2: {
		num_explosions = [1, 8],
		offsets = [0, 70],
		sizes = [1.3, 0.65],
		damages = [100, 50],
		impulses = [800, 500]
	},
	3: {
		num_explosions = [1, 6, 20],
		offsets = [0, 63, 105],
		sizes = [1.5, 0.9, 0.5],
		damages = [150, 80, 40],
		impulses = [800, 500, 300]
	}
}

var walk_speed
var base_flame_spread
var shot_speed 
var base_flame_emission_rate

var flame_damage = 3
var walk_speed_levels = [100, 110, 125, 135, 145, 155, 170]
var shot_speed_levels = [175, 225, 240, 255, 270, 285, 300]
var base_flame_spread_levels = [25, 20, 22, 24, 26, 28, 30]
var base_flame_emission_rate_levels = [15, 20, 23, 26, 30, 34, 38, 45]
var tar_pressure_levels = [3, 3, 3.5, 3.5, 4, 4.5, 5]

var flamethrower_active = false
var flame_emission_rate = 0.0
var time_since_flame_emission = 0.0

var sputter_count = 0
var sputter_delay = 0.2
var num_sputters_before_continuous_fire = 2

var pressure = 0
var pressure_increase_rate = 0.3

var tar_pressure_recharge_rate= 0.5
var tar_pressure_drop_rate = 0.4

var heat_buildup = 0.0
var heat_buildup_rate = 0.2
var cooling_rate = 0.3
var cooling_pause_timer = 0.0

var incoming_heat_source : Attack = null

var is_exploding = false
var self_destruct_triggered = false
var explosion_timer = 0.0
var explosion_countdown_time = 0.9
var explosion_damage = 60

var tar_cooldown = 0.066
var tar_timer = 0.0
var tar_pressure = 1.0
var tar_scale = 1.0
var tar_durability_mult = 1.0
var emitting_tar = false

var shot_timer = 0
var startup_lag = 0.1
var recoil = 0
var flame_lifetime = 0.8
var speed_while_attacking
var traction_loss_mult = 1.0

var tank_aeration_level = 0
var tank_aeration_max = 0
var tank_aeration_speed = 0.1

var exploded = false
var thermobaric_mode = false
var explosive_coolant = false

var last_clouds = []
#var ai_shoot = false
#var ai_shoot_timer = 0
#var ai_target_point = Vector2.ZERO
#var ai_retarget_timer = 0

@onready var flamethrower_audio = $Flamethrower
@onready var tar_audio = $TarAudio
@onready var explosion_audio = $ExplosionAudio
@onready var countdown = $Countdown
@onready var nozzle_sprite = $NozzleSprite
@onready var warning_audio = $WarningAudio
@onready var aim_indicator = $AimIndicator

var default_skin_path = "res://Art/Characters/FlamebotRAM/Flamebot 63x38.png"
var default_nozzle = "res://Art/Characters/FlamebotRAM/nozzle.png"
var blue_skin_path = "res://Art/Characters/FlamebotRAM/Flamebot 63x38 dark blue.png"
var blue_nozzle = "res://Art/Characters/FlamebotRAM/nozzle4.png"
var grey_skin_path = "res://Art/Characters/FlamebotRAM/Flamebot 63x38 Grey.png"
var grey_nozzle = "res://Art/Characters/FlamebotRAM/nozzle3.png"
var teal_skin_path = "res://Art/Characters/FlamebotRAM/Flamebot 63x38 teal.png"
var teal_nozzle = "res://Art/Characters/FlamebotRAM/nozzle2.png"

var flame_spread = base_flame_spread:
	get: return base_flame_spread*(1.0 + pow(pressure, 0.6))

# Called when the node enters the scene tree for the first time.
func _ready():
	enemy_type = EnemyType.FLAME
	max_health = 80
	mass = 1.25
	bullet_spawn_offset = 13
	flip_offset = -10
	max_attack_cooldown = 1
	countdown.hide()
	play_animation('Spawn')
	vertical_bullet_spawn_offset = 2
	if not initialized:
		nozzle_sprite.visible = false
	aim_indicator.visible = false
	super._ready()
	toggle_enhancement(false)
	handle_skin()
	

func toggle_playerhood(state):
	super(state)
	incoming_heat_source = null
	if state:
		cooling_pause_timer = 0.0
		if spawn_state == SpawnState.SPAWNED:
			aim_indicator.visible = SaveManager.settings.aphid_aiming_reticle
	else:
		aim_indicator.visible = false

func toggle_enhancement(state):
	var level = 1 if is_player else 0
	walk_speed = walk_speed_levels[level]
	max_speed = walk_speed
	shot_speed = shot_speed_levels[level]
	base_flame_spread = base_flame_spread_levels[level]
	base_flame_emission_rate = base_flame_emission_rate_levels[level]
	recoil = 400
	tar_pressure = tar_pressure_levels[level]
	tar_durability_mult = 1.0
	startup_lag = 0.5
	pressure_increase_rate = 0.3
	heat_buildup_rate = 0.2
	cooling_rate = 0.3 if state else 0.2
	speed_while_attacking = walk_speed*(0.85 if is_player else 0.6)
	traction_loss_mult = 1.0
	thermobaric_mode = false
	tank_aeration_max = 0.0
	handle_skin()
	var upgrades_to_apply = get_currently_applicable_upgrades()
	
	base_flame_emission_rate *= 1.0 + 0.1*upgrades_to_apply['overpressure']
	num_sputters_before_continuous_fire = max(0, num_sputters_before_continuous_fire - upgrades_to_apply['overpressure']) #weird interaction, could be tweaked

	pressure_increase_rate *= 1.0 + 0.25*upgrades_to_apply['exhaust_feedback'] 
	heat_buildup_rate *= 1.0 + 0.1*upgrades_to_apply['exhaust_feedback']
	
	heat_buildup_rate *= pow(0.8, upgrades_to_apply['laminar_outflow'])
		
	cooling_rate *= 1.0 + 0.4*upgrades_to_apply['overclocked_cooling']
	
	tar_durability_mult = 1.0 + 0.3*upgrades_to_apply['distended_spigot']
		
	max_speed *= 1.0 + 0.1*upgrades_to_apply['quadrupedal_optimization']
	traction_loss_mult *= pow(0.8, upgrades_to_apply['quadrupedal_optimization'])
	speed_while_attacking = max_speed*0.85
	
	if upgrades_to_apply['internal_combustion'] > 0:
		shot_speed *= 2.0
		base_flame_spread *= 0.5
		recoil += 100
		heat_buildup_rate *= 1.4
		
	thermobaric_mode = upgrades_to_apply['ultrasonic_nozzle'] > 0
		
	if upgrades_to_apply['aerated_fuel_tanks'] == 0:
		tank_aeration_max = 0.0
		tank_aeration_level = 0.0
	else:
		tank_aeration_level = upgrades_to_apply['aerated_fuel_tanks']
		tank_aeration_max = tank_aeration_level + 1.0
	
	explosive_coolant = upgrades_to_apply['alternative_coolant'] > 0
	
	if flamethrower_active:
		stop_attacking()
		attack_cooldown = 0
	super.toggle_enhancement(state)

func misc_update(delta):
	super.misc_update(delta)
	update_timers(delta)
	if flamethrower_active:
		update_flamethrower(delta)
	
	if not flamethrower_active:
		pressure = max(pressure*0.95 - delta*0.5, 0.0)
		if cooling_pause_timer <= 0:
			heat_buildup = max(heat_buildup - cooling_rate*delta, 0)
		else:
			cooling_pause_timer -= delta
	
	if emitting_tar:
		while_emitting_tar(delta)
	else:
		tar_pressure = min(tar_pressure + delta*tar_pressure_recharge_rate, 1.0)
		
	if is_exploding:
		update_explosion_countdown(delta)
	elif heat_buildup >= 1.0:
		begin_explosion_countdown()
	
	tank_aeration_level = min(tank_aeration_level + delta*tank_aeration_speed, tank_aeration_max)
		
	update_nozzle_position()
	update_overheat_visual()

func player_action():
	if Input.is_action_pressed("attack1") and not flamethrower_active and not reviving and attack_cooldown < 0:
		begin_attacking()
		
	elif not Input.is_action_pressed("attack1") and flamethrower_active:
		stop_attacking()
		attack_cooldown = 0.5
		
	if Input.is_action_just_pressed("attack2") and tar_pressure > 0.2:
		begin_emitting_tar()
		
	elif Input.is_action_just_released("attack2") and emitting_tar:
		stop_emitting_tar()
		
	update_aim_indicators()
		
func update_nozzle_position():
	nozzle_sprite.rotation = aim_direction.angle();
	nozzle_sprite.show_behind_parent = nozzle_sprite.rotation < deg_to_rad(-30) and nozzle_sprite.rotation > deg_to_rad(-150)

func handle_skin():
	if not upgrades.is_empty():
		if "aerated_fuel_tanks" in upgrades:
			sprite.texture = load(grey_skin_path)
			nozzle_sprite.texture = load(grey_nozzle)
			return
		if 'distended_spigot' in upgrades:
			sprite.texture = load(teal_skin_path)
			nozzle_sprite.texture = load(teal_nozzle)
			return
			#TODO Pick a better upgrade for this
		if 'self-laminar_outflow' in upgrades:
			sprite.texture = load(blue_skin_path)
			nozzle_sprite.texture = load(blue_nozzle)
			return
	elif is_player:
		skin_overlay.texture = load(GameManager.player_aphid_skin_overlay_path["sprite_sheet_path"])
		if GameManager.player_aphid_skin_path != "":
			sprite.texture = load(GameManager.player_aphid_skin_path)
			if "Grey" in GameManager.player_aphid_skin_path:
				nozzle_sprite.texture = load(grey_nozzle)
			elif "teal" in GameManager.player_aphid_skin_path:
				nozzle_sprite.texture = load(teal_nozzle)
			elif "blue" in GameManager.player_aphid_skin_path:
				nozzle_sprite.texture = load(blue_nozzle)
			return
	sprite.texture = load(default_skin_path)
	nozzle_sprite.texture = load(default_nozzle)
	skin_overlay.texture = load("")

func update_timers(delta):
#	ai_retarget_timer -= delta
#	ai_shoot_timer -= delta
	tar_timer -= delta
	shot_timer -= delta
	time_since_flame_emission += delta
	
func begin_attacking():
	flamethrower_active = true
	attacking = true
	shot_timer = -1
	#pressure = 0.0
	sputter_count = 0
	time_since_flame_emission = sputter_delay
	
	#apply_effect(EffectType.SPEED_OVERRIDE, self, speed_while_attacking)
	play_animation("Charge")
	
func begin_emitting_tar():
	emitting_tar = true
	tar_timer = -1.0
	tar_audio.play()
	
func while_emitting_tar(delta):
	tar_pressure = max(tar_pressure - delta*tar_pressure_drop_rate, 0.0)
		
#	if tar_pressure <= 0:
#		stop_emitting_tar()
	
	if tar_timer < 0:
		emit_tar()
		
func stop_emitting_tar():
	emitting_tar = false
	tar_audio.stop()
		

func update_flamethrower(delta):
	var sputtering = sputter_count < num_sputters_before_continuous_fire
	if not sputtering:
		pressure = pressure + pressure_increase_rate*delta/(1.0 + max(0, pressure - 1.0))
		heat_buildup = min(heat_buildup + heat_buildup_rate*delta, 1.0)
		update_flamemethrower_recoil(delta)
	flame_emission_rate = base_flame_emission_rate * (1 + 1.5*pow(pressure, 1.0))
	
	if shot_timer < 0:# && ((pressure > 0 && pressure < 0.1) || (pressure > 0.15 && pressure < 0.25) || pressure > 0.3):
		if sputtering:
			shot_timer = sputter_delay
			sputter_count += 1
			flamethrower_audio.stream = flame_sputter_audio
			flamethrower_audio.play()
		else:
			if !flamethrower_audio.is_playing():
				flamethrower_audio.stream = flame_loop_audio
				flamethrower_audio.play()
			shot_timer = 0.066
		emit_flames()

# The following wall of vector math achieves the following behaviour when the flamethrower is active:
# Case 1 - If the bot is moving against or perpendicular to the recoil, ignore the recoil but
# move with a speed penalty proportional to pressure
# Case 2 - If the bot is moving with the recoil, gain a speed boost proportional to pessure
# Case 3 - If movement input is zero, cancel part of the recoil but still get pushed by the remainder
func update_flamemethrower_recoil(_delta):
	var effective_pressure = max(pressure, 0.25)
	var recoil_accel = -aim_direction.normalized()*recoil*pow(effective_pressure, 0.5)
	var recoil_dir = recoil_accel.normalized()
	
	if target_velocity.is_zero_approx():
		target_velocity = recoil_dir
		recoil_accel -= recoil_accel.limit_length(min(recoil_accel.length()*0.9, recoil*0.5))
		
	var velocity_alignment = target_velocity.dot(recoil_dir)
	var sliding = velocity_alignment > 0.3

	var parallel_movement = recoil_accel.normalized() if sliding else target_velocity.project(recoil_accel)
	var perp_movement = target_velocity.project(recoil_accel.orthogonal())

	var speed_against_thrust = speed_while_attacking*(1.0 - pow(pressure, 0.7)*0.4*traction_loss_mult)
	var speed_with_thrust = recoil_accel.length()

	parallel_movement *= speed_with_thrust if parallel_movement.dot(recoil_accel) > 0 else speed_against_thrust
	perp_movement *= speed_with_thrust*0.5 if sliding else speed_against_thrust

	var net_vel = parallel_movement + perp_movement
	target_velocity = net_vel.normalized()
	
	apply_effect(EffectType.SPEED_OVERRIDE, self, net_vel.length())
	if sliding:
		apply_effect(EffectType.ACCEL_MULT, self, max(0.2, 1.0 - pressure*0.75))
	else:
		apply_effect(EffectType.ACCEL_MULT, self, max(0.5, 1.0 - pressure*0.45*traction_loss_mult))
		
#	var movement_alignment_with_recoil = 1.0
#	if target_velocity.length() > 0:
#		movement_alignment_with_recoil = pow((1 + target_velocity.normalized().dot(recoil_accel.normalized()))/2, 2)
#
#		var target_velocity = (target_velocity.project(recoil_accel)*speed_with_thrust + target_velocity.project(recoil_accel.orthogonal())*speed_against_thrust).normalized()
#
#	
#		apply_effect(EffectType.SPEED_OVERRIDE, self, movement_alignment_with_recoil*speed_with_thrust + (1 - movement_alignment_with_recoil)*speed_against_thrust)
#		#velocity += recoil_accel*movement_alignment_with_recoil*delta

func stop_attacking():
	flamethrower_active = false
	cancel_effect(EffectType.SPEED_OVERRIDE, self)
	cancel_effect(EffectType.ACCEL_MULT, self)
	attack_cooldown = 0.5
#	if is_player:
#		animplayer.speed_scale = 0.5 / startup_lag
	play_animation("Cooldown")
	flamethrower_audio.stop()
	if ControllerIcons._last_input_type == ControllerIcons.InputType.CONTROLLER and is_player and not is_exploding and not exploded:
		Input.stop_joy_vibration(0)
	
	if thermobaric_mode:
			detonate_gas_clouds()

func emit_flames():
	#var limited_aim_direction = Util.limit_horizontal_angle(aim_direction, PI/6)
	# Simulate fractional numbers of flames per emission with probability
	var num_flames = flame_emission_rate * time_since_flame_emission
	num_flames = int(num_flames) + (1 if randf() < (num_flames - int(num_flames)) else 0)
	time_since_flame_emission = 0.0
	var current_flame_damage = flame_damage
	var effective_pressure = pow(pressure, 0.6)
	var clouds = []
	if ControllerIcons._last_input_type == ControllerIcons.InputType.CONTROLLER and is_player:
		Input.start_joy_vibration(0, 0.2, min(num_flames/5, 0.5), 5)
	for i in range(num_flames):
		var pellet_dir = aim_direction.rotated((randf()-0.5)*deg_to_rad(flame_spread))
		
		if thermobaric_mode:
			var pellet_speed = shot_speed*1.25*(0.4 + 0.6*effective_pressure) * (1 + 0.25*(randf()-0.5))
			clouds.append(shoot_gas_cloud(pellet_dir*pellet_speed))
		else:
			var pellet_speed = shot_speed * (0.7 + 0.3*effective_pressure) * (1 + 0.5*(randf()-0.5))
			var bullet = shoot_bullet(pellet_dir*pellet_speed, current_flame_damage, 0.01, flame_lifetime, "flame")
			bullet.pierce_decay = 0.0
			
	if thermobaric_mode and len(clouds) > 0:
		clouds[0].next_in_chain = last_clouds
		last_clouds = clouds

func emit_tar(offset = Vector2.ZERO, spawn_ignited = false):
	tar_timer = tar_cooldown / max(pow(tar_pressure, 1.5), 0.1)
	
	var tar = TarPuddle.instantiate()
	tar.causality.set_source(self)
	tar.global_position = physics_collider.global_position + offset
	tar.lifetime *= tar_durability_mult
	tar.burn_duration *= 1.0 + (tar_durability_mult - 1.0)*2.0
	tar.z_index = z_index - 1
	get_parent().add_child(tar)
	
	if spawn_ignited: tar.ignite(null, false)
	
	if flamethrower_active and not is_exploding:
		self_destruct_triggered = true
		heat_buildup = max(heat_buildup, 1.0)
		cooling_pause_timer = 2.0
		Input.start_joy_vibration(0, 0.1, 0, 0.15)
		#Violence.spawn_explosion(global_position, Attack.new(self, 20, 200), 0.5)

func shoot_gas_cloud(vel):
	var cloud = GasCloud.instantiate()
	cloud.global_position = global_position + Vector2.UP*vertical_bullet_spawn_offset + aim_direction*bullet_spawn_offset
	cloud.causality.set_source(self)
	cloud.damage = 12
	cloud.set_vel(vel)
	Util.set_object_elevation(cloud, elevation)
	GameManager.objects_node.add_child(cloud)
	return cloud

func detonate_gas_clouds():
	var delay = 0.3
	for cloud in last_clouds:
		if is_instance_valid(cloud):
			cloud.detonate_after_delay(delay)
	last_clouds = []
	
func deploy_explosive_coolant(heat_to_vent):
	if heat_buildup < 0.15: return
	if self_destruct_triggered: return
	var self_attack = Attack.new(self, heat_to_vent*35/(cooling_rate/0.3))
	if self_attack.damage >= health: return
	
	heat_buildup = 0
	is_exploding = false
	countdown.visible =false
	
	var explosion_attack = Attack.new(self, 20 + heat_to_vent*80)
	explosion_attack.impulse = 100 + heat_to_vent*1400
	explosion_attack.deflect_type = Attack.DeflectType.REPULSE
	explosion_attack.add_tag(Attack.Tag.FIRE)
	explosion_attack.bonuses.append(Fitness.Bonus.KAMIKAZE)
	Violence.spawn_explosion(foot_position, explosion_attack, 0.8 + heat_to_vent, 0, true, 'flamebot')
	
	self_attack.hit_allies = true
	self_attack.inflict_on(self)
	
	emit_tar(Vector2.ZERO, true)

func update_overheat_visual():
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
		
		sprite.material.set_shader_parameter('intensity', intensity)
		nozzle_sprite.material.set_shader_parameter('intensity', intensity)
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

func begin_explosion_countdown():
	is_exploding = true
	if is_player:
		warning_audio.play()
	countdown.visible = true
	explosion_timer = explosion_countdown_time

func update_explosion_countdown(delta):
	explosion_timer -= delta
	if explosion_timer > 0:
		countdown.text = str(int(3*explosion_timer/explosion_countdown_time))
	else:
		if not exploded:
			warning_audio.stop()
			countdown.visible = false
			explode()

func explode():
	if exploded: return
	exploded = true
	if incoming_heat_source:
		incoming_heat_source.bonuses.append(Fitness.Bonus.OVERHEAT)
	
	if not dead: die(incoming_heat_source)
	play_animation('Explode')
	if ControllerIcons._last_input_type == ControllerIcons.InputType.CONTROLLER and is_player:
		Input.start_joy_vibration(0, 1, 1, 0.5)
	explosion_audio.play()
	for i in range(6):
		tar_audio.stream = tar_burning_audio
		tar_audio.play
		emit_tar(randf()*30*Vector2.RIGHT.rotated(randf()*2*PI), true)
		
	var source = self#GameManager.player.true_host if killed_by_player else self
	var current_explosion_damage = explosion_damage
	var explosion_attack = Attack.new(self, current_explosion_damage, 1000)
	explosion_attack.deflect_type = Attack.DeflectType.REPULSE
	explosion_attack.hit_allies = true
	if cause_of_death:
		explosion_attack.causality.add_to_causality_chain(cause_of_death.causality)
		
	if was_recently_player():
		explosion_attack.bonuses.append(Fitness.Bonus.KAMIKAZE)
	else: 
		explosion_attack.proxy_level += 1
		
	var explosion_type = explosion_types[clamp(int(tank_aeration_level), 0, 3)]
	var num_explosions = explosion_type.num_explosions
	var offsets = explosion_type.offsets
	var sizes = explosion_type.sizes
	var damages = explosion_type.damages
	var impulses = explosion_type.impulses
	
	for ring in range(offsets.size()):
		var sub_explosion = explosion_attack.duplicate()
		sub_explosion.damage = damages[ring]
		sub_explosion.impulse = impulses[ring]
			
		var offset = Vector2(offsets[ring], 0)
		var stagger = explosion_type.stagger if 'stagger' in explosion_type else 0.0
		for i in range(num_explosions[ring]):
			Violence.spawn_explosion(global_position + offset, sub_explosion, sizes[ring], ring*(0.25 + (stagger*randf() - stagger*0.5)), true, 'flamebot')
			offset = offset.rotated(2*PI/num_explosions[ring])
				
func update_aim_indicators():
	aim_indicator.set_spread(deg_to_rad(flame_spread))
	aim_indicator.set_direction(aim_direction)

func take_damage(attack):
	if Attack.Tag.FIRE in attack.tags:
		if swap_shield_health > 0:
			var shield_damage = min(swap_shield_health, attack.damage)
			swap_shield_health -= shield_damage
			update_swap_shield()
			attack.damage -= shield_damage
			
		heat_buildup += attack.damage*0.0075
		if not is_player:
			cooling_pause_timer = clamp(0.8*attack.damage, cooling_pause_timer, 2.0)
		
		if is_instance_valid(attack.causality.original_source) and attack.causality.original_source != self:
			incoming_heat_source = attack
	else:
		super(attack)
		
func revive():
	flamethrower_active = false
	exploded = false
	is_exploding = false
	heat_buildup = 0
	cancel_effect(EffectType.SPEED_OVERRIDE, self)
	cancel_effect(EffectType.ACCEL_MULT, self)
	flamethrower_audio.stop()
	if SaveManager.settings.aphid_aiming_reticle and is_player:
		aim_indicator.visible = true
	super.revive()
	
func reset_body_state():
	super()
	heat_buildup = 0.0
	exploded = false
	is_exploding = false
	emitting_tar = false
	flamethrower_audio.stop()
	tar_audio.stop()
	
func finish_spawning():
	super.finish_spawning()
	nozzle_sprite.visible = true
	if SaveManager.settings.aphid_aiming_reticle and is_player:
		aim_indicator.visible = true
	
func die(attack):
	super(attack)
	if warning_audio.is_playing():
		warning_audio.stop()
		countdown.visible = false
	nozzle_sprite.visible = false
	aim_indicator.visible = false
	
func _on_hitbox_area_entered(area):
	super(area)
	if heat_buildup < 0.5: return
	
	if area.is_in_group("hitbox"):
		var entity = area.get_parent()
		if entity is Enemy:
			var burn_attack = Attack.new(self, 50*heat_buildup)
			burn_attack.add_tag(Attack.Tag.FIRE)
			burn_attack.impulse = 400*heat_buildup
			burn_attack.bonuses.append(Fitness.Bonus.SEARED)
			if burn_attack.inflict_on(entity):
				heat_buildup *= 0.8
#			var rel_speed = (velocity - entity.velocity).length()
#			var new_vel = (global_position + entity.global_position).normalized() * velocity.length()
#			var delta_vel = new_vel - velocity
			
#			var collision_attack = Attack.new(self)
#			collision_attack.damage = pow(rel_speed, 0.75)
#			collision_attack.impulse = delta_vel*2/entity.mass
#			var attack_hit = collision_attack.inflict_on(entity)
#			print('rel speed ', rel_speed)
#			if attack_hit:
#				velocity = new_vel*0.7
#
#				if rel_speed > 100:
#					if rel_speed < walk_speed*0.9:
#						GameManager.set_timescale(0.9 - rel_speed/walk_speed)

func _on_animation_finished(anim_name):
	super(anim_name)
	if anim_name == "Charge":
		play_animation("Attack")
		if is_player:
			animplayer.speed_scale = 1 + 0.1
		else:
			animplayer.speed_scale = 1
			
	if anim_name == "Cooldown":
		attacking = false
		cancel_effect(EffectType.SPEED_OVERRIDE, self)
		if explosive_coolant:
			countdown.visible = false
			warning_audio.stop()
			deploy_explosive_coolant(heat_buildup)
		
	if anim_name == "Die":
		countdown.visible = false
		warning_audio.stop()
		
		detonate_gas_clouds()
	if anim_name == "Revive":
		nozzle_sprite.visible = true

