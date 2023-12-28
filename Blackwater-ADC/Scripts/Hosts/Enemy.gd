class_name Enemy
extends Host

class StartingConditions:
	var ai_starting_conditions : EnemyAI.StartingConditions
	var make_larger := false
	var swap_shield := false
	var swap_shield_health := 50
	var upgrades := []
	var is_elite := false
	var health_multiplier := 1.0

enum EnemyType {
	SHOTGUN,
	CHAIN,
	FLAME,
	WHEEL,
	ARCHER,
	EXTERMINATOR,
	SORCERER,
	SABER,
	BOSS1,
	UNKNOWN
}

const ENEMY_NAME = {
	EnemyType.SHOTGUN: 'Steeltoe',
	EnemyType.CHAIN: 'Deadlift',
	EnemyType.WHEEL: 'Router',
	EnemyType.FLAME: 'Aphid',
	EnemyType.UNKNOWN: ''
}

const PlayableEnemyType = [EnemyType.SHOTGUN, EnemyType.CHAIN, EnemyType.FLAME, EnemyType.WHEEL]

enum EffectType {
	SPEED_MULT,
	SPEED_OVERRIDE,
	ACCEL_MULT,
	ACCEL_OVERRIDE
}

class Effect :
	var type: EffectType
	var value
	var lifetime
	
	func _init(t: EffectType, v, l = -1):
		type = t
		value = v
		lifetime = l

enum SpawnState {
	SPAWNING_NON_INTERRUPTIBLE,
	SPAWNING_INTERRUPTIBLE,
	SPAWNED
}

const enemy_icon_paths = {
	Enemy.EnemyType.SHOTGUN: 'res://Art/Characters/ShotgunnerRAM/ShotgunnerIcon.png',
	Enemy.EnemyType.CHAIN: 'res://Art/Characters/ChainbotRAM/deadliftIcon.png',
	Enemy.EnemyType.WHEEL: 'res://Art/Characters/WheelbotRAM/wheelbotIcon.png',
	Enemy.EnemyType.FLAME: 'res://Art/Characters/FlamebotRAM/FlamebotIcon.png',
	Enemy.EnemyType.ARCHER: 'res://Art/Characters/Archer/icon.png',
	Enemy.EnemyType.EXTERMINATOR: 'res://Art/Characters/Exterminator/icon2.png',
	Enemy.EnemyType.SORCERER: 'res://Art/Characters/Sorcerer Bot/icon2.png',
	Enemy.EnemyType.SABER: 'res://Art/Characters/3 Saber dude/icon.png'
}

const DEATH_DURATION = 0.4

@onready var AI : EnemyAI = get_node_or_null('AI') 
@onready var healthbar = $EnemyFX/HealthBar
@onready var local_juice_bar = $EnemyFX/LocalJuice
@onready var damage_particles = $EnemyFX/DamageParticles
@onready var foot_particles = $EnemyFX/FootstepParticles
@onready var spark_particles = $EnemyFX/SparkParticles
@onready var EV_particles = $EnemyFX/EVParticles
@onready var shape = $CollisionShape2D
@onready var enemy_fx = $EnemyFX
@onready var light_circle = $EnemyFX/CharacterLights/Radial
@onready var light_beam = $EnemyFX/CharacterLights/Directed
@onready var gun_particles = $EnemyFX/GunParticles
@onready var onscreen_check = $EnemyFX/VisibleOnScreenNotifier2D
@onready var selected_sprite = $EnemyFX/SwapSelected
@onready var shadow_sprite = $EnemyFX/Shadow
@onready var animplayer = $AnimationPlayer
@onready var sprite = $Sprite
@onready var physics_collider = $CollisionShape2D
@onready var hitbox = get_node_or_null('Hitbox')

var swap_shield_node

@onready var default_material = sprite.material
@onready var flash_material = load('res://Shaders/EnemyFlash.tres')
@onready var boss_flash_material = load('res://Shaders/Flash.tres')

var initialized = false

var max_health := 100.0
var mass := 1.0
var max_speed = 100
var accel := 10.0
var stun_resist := 0.0

var health := max_health

var dead := false
var cause_of_death : Attack = null

var upgrades = {}

var enemy_type = EnemyType.UNKNOWN
var score = 0

var movement_effect_system := MovementEffectSystem.new()
var movement_effects = {}
var effect_immunities = []

#Lower side first
var on_left_to_right_stairs := false
var on_right_to_left_stairs := false

var home_room : DiscreteRoom = null

var stunned = false
var stun_timer = 0

# Timer for how long the player can be in a bot before it decays
var control_timer = 0

var damage_flash_active = false
var damage_flash_timer = 0

var facing_left = true
var flip_offset = 0

var spawn_state = SpawnState.SPAWNED
var death_timer = 0
var killed_by_player := false
var death_proxy_level := 0

var spawn_zone : SpawnZone

signal on_ready(_self)
signal on_damage_taken(_self, attack)
signal on_death(_self)

var player:
	get: return GameManager.player.apparent_host

var attacking = false
var attack_cooldown = 0
var max_attack_cooldown = 0
var attack_cooldown_audio_preempt = 0

var special_cooldown = 0
var max_special_cooldown = 0

# TODO: Reimplement SCORN
#var time_since_player_damage = 999

var lock_aim = false

var bullet_spawn_offset = 0
var vertical_bullet_spawn_offset = 0


var shoot_through = []

var flash_color = Color.WHITE

var force_swap = false

var berserk = false
var last_stand = false

var immobile = false
var grappleable = true
var in_stealth := false
var invincible = false
var invincibility_timer = 0
var reviving = false

var ai_starting_tactic : EnemyAI.Tactic
var ai_starting_state = null
var ai_starting_go_aggro_conditions
var ai_starting_keep_aggro_conditions

var ai_starting_conditions : EnemyAI.StartingConditions
var starting_conditions := StartingConditions.new()

#FOR LEGACY AI ONLY - REMOVE LATER
var player_pos:
	get: return GameManager.player.apparent_host.global_position if is_instance_valid(GameManager.player.apparent_host) else null
var player_host:
	get: return GameManager.player.apparent_host if is_instance_valid(GameManager.player.apparent_host) else null
# ---------------------------------

var elevation:
	get: return Util.elevation_from_z_index(z_index)
	set(value): Util.set_object_elevation(self, value)
	
var foot_position: Vector2:
	get: return (global_position + physics_collider.position) if physics_collider else global_position
	
var foot_offset: Vector2:
	get: return physics_collider.position if physics_collider else Vector2.ZERO
	
var target_velocity := Vector2.ZERO:
	get: return target_velocity
	set(value): target_velocity = value.normalized() 
	
var aim_direction = Vector2.ZERO:
	get: return aim_direction
	set(value): aim_direction= value.normalized() 

func _ready():
	if not initialized:
		swap_shield_node = get_node_or_null('EnemyFX/SwapShield')
		if not swap_shield_node:
			swap_shield_node = get_node_or_null('SwapShield')
			
		apply_enemy_modifications()
		calculate_score_value()
		init_healthbar()
		foot_offset = Vector2(0, get_node("CollisionShape2D").position.y)
		EV_particles.emitting = false
		foot_particles.emitting = false
		update_swap_shield()
		GameManager.on_swap.connect(on_swap)
		#add_child(movement_effect_system)
		start_spawn()
		initialized = true
		
	on_ready.emit(self)
	
func init_healthbar():
	max_health *= starting_conditions.health_multiplier
	health = max_health
	healthbar.max_value = health
	healthbar.value = health
	healthbar.scale.x = health / 200.0
	
func apply_enemy_modifications():
	if is_instance_valid(AI):
		AI.starting_conditions = starting_conditions.ai_starting_conditions
		AI.initialize(self)
	if starting_conditions.swap_shield:
		add_swap_shield(starting_conditions.swap_shield_health)
	if starting_conditions.is_elite and starting_conditions.make_larger:
		#TODO This does not work for chainbot
		scale = Vector2(1.4, 1.4)
		
	for upgrade in starting_conditions.upgrades:
		if not upgrade in Upgrades.upgrades: continue
		if upgrade in upgrades:
			upgrades[upgrade] += 1
		else:
			upgrades[upgrade] = 1
			
func calculate_score_value():
	var score_mult = 1.0
	score_mult += max_swap_shield_health/max_health
	if is_instance_valid(AI):
		score_mult += 0.25*AI.AI_level
	for upgrade in upgrades.keys():
		score_mult += 0.1*upgrades[upgrade]*(Upgrades.upgrades[upgrade].tier + 1)
		
	if starting_conditions.is_elite:
		score_mult = max(score_mult, 1.5)
	
	score = Util.round_to_nearest(Fitness.enemy_score_values[enemy_type]*score_mult, 10)
	
	

func _physics_process(delta):
	if not is_player:
		delta *= GameManager.dm_game_speed_mod
	
	super._physics_process(delta)
	movement_effect_system.update(delta)
	update_flash(delta)
	update_healthbar()
	
	if spawn_state == SpawnState.SPAWNED:
		if is_player:
			player_process(delta)
		else:
			ai_process(delta)
	#		time_since_player_damage += delta
	#		if GameManager.player.upgrades['scorn'] > 0 and GameManager.player.host_known and swap_shield_health < 1 and time_since_player_damage > 2:
	#			max_swap_shield_health = max(max_swap_shield_health, 1)
	#			swap_shield_health = 1
	#			update_swap_shield()
			
	if not dead and not stunned:
		misc_update(delta)
	
	attack_cooldown -= delta
	special_cooldown -= delta
	invincibility_timer -= delta
	
	if stunned:
		stun_timer -= delta
		update_stun_effect(delta)
		if stun_timer < 0:
			stunned = false
			animplayer.play()
			
	elif spawn_state == SpawnState.SPAWNED:
			animate()
	
	if not immobile:
		move(delta)
	else:
		velocity = Vector2.ZERO

func toggle_playerhood(state):
	super.toggle_playerhood(state)
	if is_instance_valid(hitbox):
		hitbox.scale = Vector2(0.5, 0.6) if state else Vector2.ONE
	#toggle_light(state)
	
	if spawn_state == SpawnState.SPAWNING_INTERRUPTIBLE:
		finish_spawning()
	
	if state == true:
		toggle_enhancement(true)
		control_timer = 10
		attack_cooldown = -1
		special_cooldown = -1
		EV_particles.emitting = true
		if is_instance_valid(AI):
			AI.is_aggro = false
		if GameManager.game_mode == GameManager.GameMode.CAMPAIGN or GameManager.game_mode == GameManager.GameMode.TEST:
			healthbar.visible = true
			if SaveManager.settings.local_juice_above_host:
				local_juice_bar.visible = true
	else:
		EV_particles.emitting = false
		local_juice_bar.visible = false
		attack_cooldown = max(attack_cooldown, 1)
		special_cooldown = max(special_cooldown, 1)
		
func move(delta):
	var cur_speed = movement_effect_system.apply_speed_effects(max_speed)
	var cur_accel = movement_effect_system.apply_accel_effects(accel)
	handle_stair_movement(velocity)
	velocity = velocity.lerp(target_velocity*cur_speed, cur_accel*delta)
	
	velocity += applied_velocity
	
	# move_and_slide() uses its own delta for some reason so the game speed modifier has to be hacked in like this
	var true_velocity = velocity
	
	if not is_player:
		velocity *= GameManager.dm_game_speed_mod
		
	move_and_slide()
	
	if not is_player:
		velocity /= GameManager.dm_game_speed_mod
		
	velocity -= applied_velocity
	
	var col_count = get_slide_collision_count()
	if col_count > 0:
		var cols = []
		for i in range(col_count):
			cols.append(get_slide_collision(i))
		on_body_collision(cols)

func handle_stair_movement(cur_vel):
	if on_left_to_right_stairs:
		if abs(cur_vel.x) > 40:
			velocity.y = -cur_vel.x
	if on_right_to_left_stairs:
		if abs(cur_vel.x) > 40:
			velocity.y = cur_vel.x
 

func player_process(delta):
	if GameManager.in_cutscene:
		target_velocity = Vector2.ZERO
		return
	update_juice_bar()
	control_timer -= delta
	if control_timer < 0 and GameManager.decay:
		decay(delta)
	if dead:
		player_death(delta)
	elif not GameManager.player.swap_manager.making_dramatic_swap:
		if not dead and not stunned and can_move:
			player_move(delta)
			if not lock_aim:
				aim_direction = (get_global_mouse_position() - global_position).normalized()
				if light_beam:
					light_beam.rotation = aim_direction.angle() - PI/2
			if not GameManager.player.swap_manager.in_swap_targeting_mode and can_act:
				player_action()

func ai_process(delta):
	if is_instance_valid(GameManager.player) and GameManager.player.swap_manager.apparent_host_known() and not dead and not stunned:
		if is_instance_valid(AI):
			AI.update(self, delta)
		else:
			if can_move:
				ai_move()
			if can_act:
				ai_action()

func player_move(_delta):
	var input = Vector2()
	if Input.is_action_pressed("move_right"):
		input.x += 1
	if Input.is_action_pressed("move_left"):
		input.x -= 1
	if Input.is_action_pressed("move_down"):
		input.y += 1
	if Input.is_action_pressed("move_up"):
		input.y -= 1
		
	target_velocity = input
	
func misc_update(_delta):
	pass

func player_action():
	pass

func ai_move():
	target_velocity = Vector2.ZERO

func ai_action():
	pass

func on_swap():
	pass
	
func reset_body_state():
	cancel_all_effects()
	attack_cooldown = -1.0
	special_cooldown = -1.0
	in_stealth = false
	invincible = false
	attacking = false
	immobile = false
	lock_aim = false
	invincibility_timer = 1.0
	stunned = false
	stun_timer = -1.0
	
func start_spawn(interruptible = false):
	if not animplayer.has_animation("Spawn"):
		finish_spawning()
		return
	
	spawn_state = SpawnState.SPAWNING_NON_INTERRUPTIBLE
	invincible = true
	grappleable = false
	can_be_swapped_to = false
	if interruptible:
		allow_spawn_interruption()
		
	animplayer.play('Spawn')
	
func allow_spawn_interruption():
	if spawn_state == SpawnState.SPAWNING_NON_INTERRUPTIBLE:
		spawn_state = SpawnState.SPAWNING_INTERRUPTIBLE
		invincible = false
		grappleable = true
		can_be_swapped_to = true
		enemy_fx.visible = true
		
func finish_spawning():
	spawn_state = SpawnState.SPAWNED
	animplayer.play('Idle')
	foot_particles.emitting = false
	sprite.modulate.a = 1.0
	invincible = false
	grappleable = true
	can_be_swapped_to = true
	enemy_fx.visible = true
	
func animate():
	update_look_direction(aim_direction.x)

	if abs(velocity.x) < 20 and abs(velocity.y) < 20 and !attacking:
		play_animation("Idle")
	elif !attacking:
		#TODO hacky visual fix for conveyors
		if target_velocity:
			play_animation("Walk")
		else:
			play_animation("Idle")
			
func update_look_direction(dir):
	if dir > 0:
		facing_left = false
		sprite.flip_h = false
		sprite.offset.x = 0
	else:
		facing_left = true
		sprite.flip_h = true
		sprite.offset.x = flip_offset
	if dir > 0:
		skin_overlay.flip_h = false
		skin_overlay.offset.x = 0
	else:
		skin_overlay.flip_h = true
		skin_overlay.offset.x = flip_offset
			
func play_animation(anim_name, force_restart = false):
	if not dead and not stunned:
		if force_restart:
			animplayer.stop()
		animplayer.play(anim_name)
		
func shoot_bullet(vel, damage = 10, mass_ = 0.25, lifetime = 10, type = "pellet", stun = 0, size = Vector2.ONE):
	var bullet_position = global_position
	bullet_position.y -= vertical_bullet_spawn_offset
	bullet_position += aim_direction*bullet_spawn_offset
	var bullet = Violence.shoot_bullet(self, bullet_position, vel, damage, mass_, lifetime, type, stun, size)
	bullet.ignored = shoot_through
	return bullet
	
func is_valid_swap_target():
	if dead or inhibitors.size() > 0 or spawn_state == SpawnState.SPAWNING_NON_INTERRUPTIBLE: return false
	return super()

func can_be_hit(_attack):
	return not (invincible or invincibility_timer > 0 or dead)

func take_damage(attack):
	on_damage_taken.emit(self, attack)
	flash()
	if is_player:
		GameManager.camera.set_trauma(0.4)
	elif is_instance_valid(AI):
		AI.add_frame_event([AI.EnemyEvent.DAMAGED, attack])
		
	if spawn_state == SpawnState.SPAWNING_INTERRUPTIBLE:
		finish_spawning()
		
#	elif attack.caused_by_player:
#		time_since_player_damage = 0
#		if not GameManager.player.controlling_boss and GameManager.player.berserk:
#			GameManager.player.swap_timer = max(GameManager.player.swap_timer - attack.damage/20.0, 15)
		
	if swap_shield_health > 0:
		var shield_damage = min(swap_shield_health, attack.damage)
		swap_shield_health -= shield_damage
		attack.damage -= shield_damage
		if swap_shield_health <= 1:
			swap_shield_health = 0
			
		update_swap_shield()
	
	velocity += attack.get_impulse_on(self)
		
	attack.stun -= stun_resist
	if attack.stun > 0:
		stun(attack.stun)
		
	emit_blood(attack)
	
	health -= attack.damage
	
	if health <= 0:
		healthbar.value = 0
		die(attack)
		
func stun(duration):
	stunned = true
	stun_timer = max(stun_timer, duration)
	target_velocity = Vector2.ZERO
	animplayer.stop()
	

func update_healthbar():
	healthbar.value = health
	if health > max_health*0.66:
		damage_particles.emitting = false
	if health < max_health*0.66:
		damage_particles.emitting = true
	if health < max_health*0.33:
		damage_particles.process_material.hue_variation_max = 0.25
	if not is_player:
		if health == max_health:
			healthbar.visible = false
		elif health <= 0:
			healthbar.visible = false
		else:
			healthbar.visible = true

func update_juice_bar():
	local_juice_bar.value = GameManager.player.swap_manager.juice_system.local_juice

func flash(duration = 0.066):
	damage_flash_timer = duration
	sprite.material = flash_material

func update_flash(delta):
	damage_flash_timer -= delta
	if damage_flash_timer < 0 and sprite.material == flash_material:
		sprite.material = default_material
		
func emit_blood(attack):
	var amount = attack.damage if attack.override_blood_amount == null else attack.override_blood_amount
	if amount == 0: return
	
	var impulse = attack.get_impulse_on(self)*(mass if mass > 0.0 else 1.0)
	var vel = (impulse.normalized() * max(400, pow(impulse.length(), 0.43)*35)) if attack.override_blood_velocity == null else attack.override_blood_velocity
	var spread = attack.blood_spread
	
	VFX.spawn_blood(global_position, z_index, vel, amount, spread)
	
func set_intangible(state):
	hitbox.monitorable = not state
	
func toggle_enhancement(state):
	if state == true:
		animplayer.speed_scale = 1.0
		invincibility_timer = 0.5
	else:
		animplayer.speed_scale = GameManager.dm_game_speed_mod
		
#	if state:
#		if GameManager.player.upgrades['revelry'] > 0 and GameManager.player.swap_timer >= 15:
#			max_speed *= 1.33
#			max_attack_cooldown *= 0.66
#			max_special_cooldown *= 0.66

func get_currently_applicable_upgrades():
	var to_apply = {}
	for upgrade in Upgrades.upgrades.keys():
		if Upgrades.upgrades[upgrade].type == enemy_type or Upgrades.upgrades[upgrade].type == EnemyType.UNKNOWN:
			to_apply[upgrade] = 0
			
			if upgrade in upgrades:
				to_apply[upgrade] += upgrades[upgrade]
				
			if is_player and upgrade in GameManager.player.upgrades:
				to_apply[upgrade] += GameManager.player.upgrades[upgrade]
				
	return to_apply
			

func toggle_light(lights_active):
	if not light_circle or not light_beam:
		return
	
	if lights_active:
		light_circle.get_parent().visible = true
		if true:#player_light:
			#light_circle.texture_scale = 10
			light_circle.energy = 0.8
			light_circle.color = Color.WHITE
			
			light_beam.visible = false
			light_beam.texture_scale = 0.6
			light_beam.energy = 0.5
			light_beam.color = Color.WHITE
		else:
			light_circle.get_parent().visible = false
			#light.texture_scale = 3
			#light.energy = 0.6
	else:
		light_circle.get_parent().visible = false

func apply_effect(type, source: Node, value, time = -1):
	movement_effect_system.apply_effect(type, source, value, time)

func cancel_effect(type, source):
	movement_effect_system.cancel_effect(type, source)
	
func cancel_all_effects():
	movement_effect_system.cancel_all_effects()

func has_active_effects(type):
	return movement_effect_system.has_active_effects(type)

func on_boss_capture():
	invincible = false
	var explosion_attack = Attack.new(self, 100, 1000)
	Violence.spawn_explosion(global_position + Vector2(0, 20), explosion_attack, 1.5)

func add_swap_shield(hp):
	max_swap_shield_health = hp
	swap_shield_health = hp
	update_swap_shield()

func update_swap_shield():
	if not swap_shield_node: return
	if swap_shield_health > 0:
		if not swap_shield_node.is_playing():
			swap_shield_node.play('dome')
		swap_shield_node.visible = true;
		var health_ratio = swap_shield_health/max_swap_shield_health
		swap_shield_node.modulate = Color(0.5+health_ratio*0.5, health_ratio, health_ratio, 0.3 + health_ratio*0.7)
	else:
		swap_shield_node.visible = false;

func toggle_selected_enemy(enemy_is_selected):
	if enemy_is_selected:
		emit_signal("toggle_selected_enemy")

func update_stun_effect(_delta):
	if randf() > 0.93:
		flash(0.066)

func decay(delta):
	if health > 1 and not GameManager.level_manager.tutorial:
		health -= delta * 3


func player_death(delta):
	death_timer -= delta
	if death_timer < 0:
		death_timer = 99999999
		GameManager.HUD.swap_warning.visible = false
		actually_die()

func die(attack):
	if dead: return
	dead = true
	cause_of_death = attack
	
	invincible = true
	target_velocity = Vector2.ZERO
	death_timer = DEATH_DURATION
	if attack:
		killed_by_player = attack.causality.caused_by_player
		death_proxy_level += attack.proxy_level
	animplayer.play("Die")

	attacking = true
	GameManager.enemy_count -= 1
	GameManager.hosts.erase(self)
	
	Fitness.calculate_kill_score(self, attack)
	var _killer = attack.causality.original_source if attack else null
	
#	TODO: This should probably be moved somewhere else
	if is_player:
		GameManager.camera.set_trauma(1, 16 if GameManager.timescale >= 1.0 else 4)
		GameManager.lerp_to_timescale(0.1)
		
		if GameManager.player.can_swap and not GameManager.level_manager.in_hub:
			GameManager.HUD.swap_warning.visible = true

		if not GameManager.player.swap_manager.can_swap():
			GameManager.player.can_swap = false
			death_timer = 0.3
			GameManager.HUD.death_menu.death_audio.play()
		#if is_instance_valid(killer) and killer.is_in_group('enemy') and killer.enemy_type != EnemyType.UNKNOWN:
			#Options.enemy_deaths[str(killer.enemy_type)] += 1
	var ai = get_node_or_null('AI')
	if is_instance_valid(ai):
		ai.is_aggro = false
		
	emit_signal('on_death', self)

func revive():
	health = 50
	reset_body_state()
	GameManager.enemy_count += 1
	GameManager.hosts.append(self)
	GameManager.lerp_to_timescale(1)
	GameManager.player.swap_manager.swap_cursor.speed_audio.play()
	animplayer.play('Revive')

func actually_die():
	if not is_player:
		queue_free()
	else:
		if GameManager.player.swap_manager.juice_system.global_juice > 0.1:
			GameManager.player.swap_manager.juice_system.spend_global_juice(min(2.0, GameManager.player.swap_manager.juice_system.global_juice))
			revive()
		else:
			dead = true
			GameManager.lerp_to_timescale(1)
			GameManager.game_over()
			
func on_body_collision(collisions):
	pass
#	if is_instance_valid(AI):
#		AI.add_frame_event([AI.EnemyEvent.COLLIDED_WITH_BODY, collisions[0]])
			
func _on_hitbox_area_entered(area):
	pass
#	if area.is_in_group('hitbox') and is_instance_valid(AI):
#		AI.add_frame_event([AI.EnemyEvent.ENTERED_HITBOX, area])
			
func _on_animation_finished(anim_name):
	if is_instance_valid(AI):
		AI.add_frame_event([AI.EnemyEvent.ANIMATION_FINISHED, anim_name])
		
	if anim_name == "Spawn":
		finish_spawning()
	elif anim_name == "Die":
		if not is_player:
			actually_die()
	elif anim_name == "Revive":
		dead = false
		invincibility_timer = 0.5

@onready var skin_overlay = $SkinOverlay
