extends Enemy

const DustTrail = preload('res://Scenes/Particles/DustTrail.tscn')

@onready var dash_fx = $DashFX
@onready var throw_audio = $ThrowAudio
@onready var dash_audio = $Dash
@onready var charge_audio = $ChargeAudio
@onready var crash_audio = $CrashAudio
@onready var movement_raycast = $RayCast2D
@onready var drift_particles = $DriftParticles 
@onready var arm_sprite = $ArmSprite
@onready var arm_animation = $ArmAnimation
@onready var arc_preview = $ArcPreview

var default_skin_path = "res://Art/Characters/WheelbotRAM/wheelbot 58x118.png"
var red_skin_path = "res://Art/Characters/WheelbotRAM/wheelbot 58x118 red.png"
var grey_skin_path = "res://Art/Characters/WheelbotRAM/wheelbot 58x118 grey stipess.png"
var green_skin_path = "res://Art/Characters/WheelbotRAM/wheelbot 58x118 green.png"

var default_arm_skin = "res://Art/Characters/WheelbotRAM/arm__brick_58x118.png"
var shaped_charges_arm_skin = "res://Art/Characters/WheelbotRAM/arm__shapething_58x118.png"

var player_skin

var walk_speed
var reload_time

var walk_speed_levels = [230, 250, 275, 300, 325, 350, 375, 400]
var throw_cooldown_levels = [2.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]

var num_grenades_thrown := 1
var grenade_impact_damage_mult = 1.0
var grenade_explosion_damage = 30
var grenade_explosion_size_mult = 1.0
var grenade_bounciness = 1.0

var throw_spread := 0.0
var base_throw_speed : float
var throw_speed_variance := 0.0
var throw_recoil_mult = 1.0

var arm_flip_offset = 13

var shaped_charges = false
var killdozer_mode = false
var top_gear = false
var flow_state = false
var flow_state_damage_mult = 1.0
var flow_state_damage_bonus_per_hit = 0.25
var spin_control = false
var exhaust_blast = false
var exhaust_timer = 0

var max_dash_speed = 500
var dash_charge_timer = 0.0
var charging_dash = 0.0
var dash_start_point = Vector2.ZERO
var dash_i_frames = false

#var throw_recoil_force
var is_mid_throw = false
var throw_recoil_timer = 0.0
var throw_recoil_duration = 0.1
var cumulative_throw_speed = 0.0
var velocity_at_start_of_throw = Vector2.ZERO

var grenade_release_offset = Vector2(16, -12)

var ai_target_point = Vector2.ZERO
var ai_retarget_timer = 0
var can_shoot = false
var directional_input_held = false

var aimbot_candidates = []
var aimbot_target = null

var throw_release_point:
	get: return global_position + Vector2(grenade_release_offset.x * (-1 if facing_left else 1), grenade_release_offset.y)
	
var throw_aim_direction:
	get: return throw_release_point.direction_to(get_global_mouse_position())
		

# Called when the node enters the scene tree for the first time.
func _ready():
	enemy_type = EnemyType.WHEEL
	max_health = 50
	mass = 0.75
	accel = 2.5
	bullet_spawn_offset = 10
	vertical_bullet_spawn_offset = 10
	flip_offset = 7
	max_attack_cooldown = 1
	max_special_cooldown = 0.75
	arm_sprite.texture = load(default_arm_skin)
	arc_preview.visible = false
	play_animation('Spawn')
	super._ready()
	toggle_enhancement(false)
	handle_skin()
	
func toggle_playerhood(state):
	super(state)
	if state and spawn_state == SpawnState.SPAWNED:
		arc_preview.visible = SaveManager.settings.router_aiming_reticle
	else:
		arc_preview.visible = false
	
func toggle_enhancement(state):
	var level = 1 if is_player else 0
	walk_speed = walk_speed_levels[level]
	max_attack_cooldown = throw_cooldown_levels[level]
	max_speed = walk_speed
	base_throw_speed = walk_speed * (0.75 if state else 0.5)
	throw_speed_variance = 0.0
	num_grenades_thrown = 1
	grenade_impact_damage_mult = 1.0
	grenade_explosion_damage = 30
	grenade_explosion_size_mult = 1.0
	grenade_bounciness = 1.0
	flow_state_damage_mult = 1.0
	throw_spread = 0.0
	throw_recoil_mult = 1.0 if state else 0.66
	reload_time = 1.0 if state else 1.6
	accel = 2.5
	shaped_charges = false
	killdozer_mode = false
	top_gear = false
	spin_control = false
	exhaust_blast = false
	handle_skin()
	var upgrades_to_apply = get_currently_applicable_upgrades()
	
	base_throw_speed *= 1.0 + 0.1*upgrades_to_apply['express_delivery']
	throw_recoil_mult += 0.3*upgrades_to_apply['express_delivery']
	
	if upgrades_to_apply['shaped_charges'] == 0:
		grenade_explosion_damage *= 1.0 + 0.1*upgrades_to_apply['careful_packing']
		grenade_explosion_size_mult *= 1.0 + 0.2*upgrades_to_apply['careful_packing']
	else:
		grenade_bounciness += 0.3*upgrades_to_apply['careful_packing']
	
	accel *= 1.0 + 0.30*upgrades_to_apply['predictive_suspension']
	
	max_speed *= 1.0 + 0.15*upgrades_to_apply['voltage_ramp_bypass']
	accel *= pow(1.0 - 0.1, upgrades_to_apply['voltage_ramp_bypass'])

	for i in range(upgrades_to_apply['bulk_delivery']):
		num_grenades_thrown += 1
		grenade_impact_damage_mult *= 0.66
		reload_time += 0.33
		throw_spread += PI/10
		throw_speed_variance += 0.25
		base_throw_speed *= 0.75
		throw_recoil_mult += 0.5/throw_recoil_mult
		
	flow_state = upgrades_to_apply['flow_state'] > 0
		
	if upgrades_to_apply['top_gear'] > 0:
		max_speed *= 1.33
		top_gear = true
		
	if upgrades_to_apply['self-preservation_override'] > 0:
		killdozer_mode = true
		
	if upgrades_to_apply['shaped_charges'] > 0:
		shaped_charges = true
		grenade_impact_damage_mult *= 1.5
		arm_sprite.texture = load(shaped_charges_arm_skin)
		
	if upgrades_to_apply['spin_control'] > 0:
		spin_control = true
		for i in range(upgrades_to_apply['spin_control'] - 1):
			grenade_bounciness += 1.0
		
	dash_charge_timer = 0.0
	if charging_dash:
		dash()
	charging_dash = false
	movement_raycast.enabled = !state
	super.toggle_enhancement(state)
	if upgrades_to_apply['shaped_charges'] > 0:
		arm_overlay.texture = load(GameManager.player_router_skin_overlay_path["sprite_sheet_path_arm_shaped"])
	
func misc_update(delta):
	super.misc_update(delta)
	update_timers(delta)
	
	continue_throw(delta)
	
	if charging_dash:
		dash_charge_timer += delta*1.5
		var g = max(0.1, 1.0 - pow(dash_charge_timer, 2))
		drift_particles.set('color', Color(1.0, g, 0.0, 1.0))
		if is_player:
			GameManager.camera.set_trauma(0.15)
		#drift_particles.amount = velocity.length()/20
	if exhaust_blast:
		var speed = velocity.length()
		if speed > 100:
			exhaust_timer -= delta*(speed/100.0)
			if exhaust_timer < 0:
				exhaust_timer = 0.35
				Violence.shoot_bullet(self, global_position, -velocity.rotated(PI/6*(randf()-0.5)), 5, 0.25, 1.5, 'flame')
	if flow_state:
		flow_state_damage_mult = max(1.0, flow_state_damage_mult - delta*flow_state_damage_bonus_per_hit/max_attack_cooldown)
		if flow_state_damage_mult > 1:
			arm_sprite.modulate = Color.RED
		else:
			arm_sprite.modulate = Color(1,1,1,1)
	if dash_i_frames:
		if invincibility_timer > 0:
			sprite.modulate = Color.hex(0x888888)
		else:
			dash_i_frames = false
			sprite.modulate = Color(1,1,1,1)
	if flow_state:
		if flow_state_damage_mult > 1:
			arm_overlay.modulate = Color.RED
		else:
			arm_overlay.modulate = Color(1,1,1,1)

func update_timers(delta):
	ai_retarget_timer -= delta
	throw_recoil_timer += delta
	
func player_move(_delta):
	var prev_move_vector = target_velocity
	super(_delta)
	directional_input_held = not target_velocity.is_zero_approx()
	if top_gear and not directional_input_held:
		target_velocity = prev_move_vector
	
func player_action():
	if Input.is_action_pressed("attack1") and attack_cooldown < 0:
		begin_throw()
	if Input.is_action_just_pressed("attack2") and special_cooldown < 0 and not charging_dash:
		begin_charging_dash()
	elif (Input.is_action_just_released('attack2') and charging_dash) || dash_charge_timer > 1.3:
		special_cooldown = max_special_cooldown
		dash()
	
	if charging_dash:
		GameManager.camera.offset = GameManager.camera.offset.lerp(target_velocity.normalized()*100, 0.025)
	else:	
		GameManager.camera.offset = GameManager.camera.offset.lerp(velocity.normalized()*min(velocity.length()/3, 100), 0.05)
		
	update_arc_preview()

func update_look_direction(dir):
	super.update_look_direction(dir)
	if dir > 0:
		arm_sprite.flip_h = false
		arm_sprite.offset.x = 0
		arm_sprite.position.x = -8
	else:
		arm_sprite.flip_h = true
		arm_sprite.offset.x = arm_flip_offset
		arm_sprite.position.x = -6
	if dir > 0:
		arm_overlay.flip_h = false
		arm_overlay.offset.x = 0
		arm_overlay.position.x = -8
	else:
		arm_overlay.flip_h = true
		arm_overlay.offset.x = arm_flip_offset
		arm_overlay.position.x = -6

func handle_skin():
	if not upgrades.is_empty():
		if "careful_packing" in upgrades:
			sprite.texture = load(red_skin_path)
			return
		if 'bulk_delivery' in upgrades:
			sprite.texture = load(green_skin_path)
			return
		if 'self-preservation_override' in upgrades:
			sprite.texture = load(grey_skin_path)
			return
	elif is_player:
		if GameManager.player_router_skin_path != "":
			sprite.texture = load(GameManager.player_router_skin_path)
			skin_overlay.texture = load(GameManager.player_router_skin_overlay_path["sprite_sheet_path_main"])
			arm_overlay.texture = load(GameManager.player_router_skin_overlay_path["sprite_sheet_path_arm"])
			return
	sprite.texture = load(default_skin_path)
	skin_overlay.texture = load("")
	arm_overlay.texture = load("")

	
	
func animate():
	update_look_direction(aim_direction.x)
	if abs(velocity.x) < 20 and abs(velocity.y) < 20 and !attacking:
		play_animation("Idle")
	elif !attacking:
		#TODO hacky visual fix for conveyors
		if aim_direction.x > 0:
			
			if target_velocity.x > 0:
				play_animation("WalkForward")
			elif target_velocity.x < 0:
				play_animation("WalkBackward")
			else:
				play_animation("Idle")
		if aim_direction.x < 0:
			if target_velocity.x > 0:
				play_animation("WalkBackward")
			elif target_velocity.x < 0:
				play_animation("WalkForward")  
			else:
				play_animation("Idle")

func play_animation(anim_name, force_restart = false):
	if not dead and not stunned:
		if force_restart:
			animplayer.stop()
			arm_animation.stop()
		animplayer.play(anim_name)
		arm_animation.play(anim_name)
		
func begin_throw():
	is_mid_throw = true
	throw_recoil_timer = 0.0
	attacking = true
	attack_cooldown = max_attack_cooldown
	apply_effect(EffectType.ACCEL_MULT, self, 0.5)
	velocity_at_start_of_throw = velocity
	
	play_animation("Attack")
	if ControllerIcons._last_input_type == ControllerIcons.InputType.CONTROLLER:
		Input.start_joy_vibration(0, 0.5, 0.3, 0.3)
	animplayer.seek(0)
	throw_audio.play()

func continue_throw(delta):
	if not is_mid_throw: return
	
	var t = min(throw_recoil_timer/throw_recoil_duration, 1.0)
	var p = 0.7
	var impulse = base_throw_speed*throw_recoil_mult*(p + 1)*pow(t, p)*delta
	
	cumulative_throw_speed += impulse
	velocity -= 6*aim_direction.normalized()*impulse
	
	if t == 1.0: end_throw()
	
func end_throw():
	is_mid_throw = false
	cancel_effect(EffectType.ACCEL_MULT, self)
	
	if is_player:
		GameManager.camera.set_trauma(0.4)

	for i in num_grenades_thrown: 
		var grenade_speed = calculate_grenade_speed(velocity_at_start_of_throw, throw_aim_direction) - randf()*throw_speed_variance
		var throw_dir = throw_aim_direction if is_player else aim_direction
		var grenade_dir = throw_dir.rotated(throw_spread*(20/sqrt(grenade_speed))*(randf() - 0.5))
		var grenade_vel = grenade_dir*grenade_speed*(1 - randf()*throw_speed_variance)
		if is_player:
			grenade_vel += calculate_grenade_inherited_perpendicular_velocity(velocity_at_start_of_throw)

		var grenade = Violence.shoot_grenade(self, throw_release_point, grenade_vel, shaped_charges)
		grenade.damage *= grenade_impact_damage_mult*flow_state_damage_mult
		grenade.explosion_damage = grenade_explosion_damage
		grenade.explosion_size *= grenade_explosion_size_mult
		grenade.bounciness = grenade_bounciness
		if spin_control:
			grenade.homing_bounces = 999
			grenade.angular_velocity *= 6
		
		if flow_state:
			grenade.on_hit.connect(apply_direct_hit_buff)
		
		if not was_recently_player():
			grenade.collision_mask = 0 
	#cumulative_throw_speed = 0.0
	
func predict_grenade_velocity(body_vel, throw_dir):
	var grenade_speed = calculate_grenade_speed(body_vel, throw_dir)
	var grenade_vel = grenade_speed*throw_dir + Vector2.DOWN*Grenade.INIT_FALLING_VEL
	if is_player:
		grenade_vel += calculate_grenade_inherited_perpendicular_velocity(velocity)
		
	return grenade_vel
	
func calculate_grenade_speed(body_vel, throw_dir):
	#velocity + velocity.normalized()*cumulative_throw_speed
	var cur_throw_speed = base_throw_speed if (is_player or AI.tactic != AI.Tactic.CAMP) else base_throw_speed*1.5
	var body_speed = body_vel.length()
	var alignment = throw_dir.dot(body_vel.normalized())
	var speed_bonus = body_speed*(0.25 + 0.75*alignment) #*sqrt(sin((alignment + 1)*PI/4)) #Taper off added speed if velocity is highly misaligned with throw direction
	return cur_throw_speed + speed_bonus

func calculate_grenade_inherited_perpendicular_velocity(effective_vel):
	var perpendicular = effective_vel.project(throw_aim_direction.orthogonal())
	return perpendicular*0.5

func begin_charging_dash():
	charge_audio.play()
	if ControllerIcons._last_input_type == ControllerIcons.InputType.CONTROLLER and is_player:
		Input.start_joy_vibration(0, 0.2, 0.5, 3)
	dash_charge_timer = 0.0
	apply_effect(EffectType.ACCEL_OVERRIDE, self, 0.5)
	drift_particles.emitting = true
	charging_dash = true
	
func dash():
	if dead: return
	charging_dash= false
	cancel_effect(EffectType.ACCEL_OVERRIDE, self)
	drift_particles.emitting = false
	var dash_dir = target_velocity.normalized() if directional_input_held else aim_direction.normalized()
	target_velocity = dash_dir
	velocity = dash_dir*max_dash_speed*pow(min(dash_charge_timer, 1.0), 1)
	
	if is_player:
		invincibility_timer = 0.4*pow(dash_charge_timer, 0.5)
		dash_i_frames = true
		GameManager.camera.set_trauma(0.5)
		
	dash_charge_timer = 0
	dash_audio.play()
	if ControllerIcons._last_input_type == ControllerIcons.InputType.CONTROLLER and is_player:
		Input.stop_joy_vibration(0)
		Input.start_joy_vibration(0, 0, 0.7, 0.2)
#	var dash_end_point = global_position + 83*dash_dir
#	var space_state = get_world_2d().direct_space_state
#
#	var query = PhysicsRayQueryParameters2D.new()
#	query.from = global_position + foot_offset
#	query.to = dash_end_point + foot_offset
#	query.exclude = [self]
#	query.collision_mask = collision_mask
#
#	var result = space_state.intersect_ray(query)
#	if result:
#		dash_end_point = result['position'] - foot_offset
#
#	var dust_trail = DustTrail.instantiate()
#	dust_trail.global_position = (0.9*global_position + 1.1*dash_end_point)/2 - Vector2.UP*10
#	dust_trail.process_material.emission_box_extents.x = (dash_end_point - global_position).length()*0.6
#	dust_trail.rotation = dash_dir.angle()
#	dust_trail.process_material.direction.y = 1 if abs(dust_trail.rotation) > PI/2 else -1
#	dust_trail.emitting = true
#	GameManager.objects_node.add_child(dust_trail)
#
#	var maintained_speed = walk_speed if top_gear else 150	
#	if killdozer_mode:
#		for offset in [Vector2(0, 7), Vector2(0, -7)]:
#			query.from = global_position + offset + dash_dir*20
#			query.to = dash_end_point
#			query.exclude = [self]
#			query.collision_mask = 4
#			result = space_state.intersect_ray(query)
#
#			if result and result['collider'].is_in_group('hitbox'):
#				dash_end_point = result['position'] - offset - (dash_end_point - global_position).normalized()*10
#				maintained_speed = walk_speed/2.1
#				break
#
#	if exhaust_blast:
#		for i in range(4 + burst_size/2):
#			var dir = -dash_dir.rotated((0.5 - randf())*PI/8)
#			var speed = walk_speed*(1.5 + randf())
#			shoot_bullet(speed*dir, 10, 0.3, 2, 'flame')
#
#	attacking = false
#	#burst_count = 0
#	lock_aim = true
#
#	velocity = maintained_speed*dash_dir
#
#	dash_start_point = global_position + Vector2((-70 if aim_direction.x < 0 else 0), 0)
#	global_position = dash_end_point
#	#set_dash_fx_position()
#
#	dash_audio.play()
#	#dash_fx.frame = 0
#	#dash_fx.flip_h = aim_direction.x < 0
#	#dash_fx.play("Swoosh")
#
#	aim_direction.x *= -1

func apply_direct_hit_buff(_projectile):
	flow_state_damage_mult = min(flow_state_damage_mult + flow_state_damage_bonus_per_hit, 2.0)

func inflict_collision_attack(entity):
	if not entity is Enemy or entity.invincible: return
	
	var rel_speed = (velocity - entity.velocity).length()
	if rel_speed < 100: return
	
	var new_vel = (global_position - entity.global_position).normalized() * velocity.length()
	var delta_vel = new_vel - velocity
	var collision_damage = rel_speed*0.18
	
	var collision_attack = Attack.new(self, collision_damage)
	collision_attack.impulse = -delta_vel/(entity.mass * 1.5)
	collision_attack.bonuses.append(Fitness.Bonus.BODIED)
	var attack_hit = collision_attack.inflict_on(entity)
	
	if attack_hit:
		velocity = new_vel*0.7
		
		if not entity.dead:
			invincibility_timer = 0.0
			Attack.new(entity, 1.5*sqrt(collision_damage)).inflict_on(self)
		
		var speed_ratio = rel_speed/max_speed
		GameManager.camera.set_trauma(min(0.3 + speed_ratio*0.2, 1))
		crash_audio.pitch_scale = 0.8 + 0.4*randf()
		crash_audio.play()
			
		if speed_ratio > 1.2:
			GameManager.set_timescale(0.001, 0.2, 100)
		elif speed_ratio > 0.9:
			GameManager.set_timescale(0.001, 0.05, 1000)
			
func update_arc_preview():
	var num_points = arc_preview.points.size()
	var simulated_interval = 0.5
	var delta_time = simulated_interval/(num_points - 1)
	var init_vel = predict_grenade_velocity(velocity, throw_aim_direction)
	
	for i in range(num_points):
		var t = i*delta_time
		arc_preview.points[i] = (throw_release_point - global_position) + init_vel*t + Vector2.DOWN*0.5*Grenade.GRAVITY*t*t

func _on_hitbox_area_entered(area):
	super(area)
	if killdozer_mode and area.is_in_group("hitbox"):
		var entity = area.get_parent()
		inflict_collision_attack(entity)
		
func set_dash_fx_position():
	dash_fx.global_position = dash_start_point
	
	
func finish_spawning():
	super()
	if SaveManager.settings.router_aiming_reticle and is_player:
		arc_preview.visible = true

func die(attack):
	super.die(attack)
	arm_animation.play("Die")
	arc_preview.visible = false
	
func revive():
	super()
	arm_animation.play("Revive")
	if SaveManager.settings.router_aiming_reticle and is_player:
		arc_preview.visible = true

func _on_animation_finished(anim_name):
	super(anim_name)
	if anim_name == "Attack":
		attacking = false


func _on_AimbotCollider_area_entered(area):
	if area.is_in_group('hitbox') and area.get_parent().is_in_group('enemy') and area.get_parent() != self:
		aimbot_candidates.append(area.get_parent())


func _on_AimbotCollider_area_exited(area):
	if area.is_in_group('hitbox') and area.get_parent().is_in_group('enemy') and area.get_parent() != self:
		aimbot_candidates.erase(area.get_parent())
		
@onready var arm_overlay = $ArmOverlay
