extends CharacterBody2D

#region Movement
const SPEED = 150
const JUMP_VELOCITY = -350.0
## Soft air influence vs knockback (px/s^2). Ground stays instant - do not use this on floor.
const AIR_DI := 280.0
## Horizontal snap when spending an air jump (jump charge) while holding a direction.
const AIR_JUMP_X_BOOST := 150.0
@export var jump_charge := 1
var jump_charge_left = 0

# Coyote time
@export var coyote_time := 0.1
var coyote_timer := 0.0

var spawn_pos: Vector2

# Per-player Input Map actions (defaults = Player 1).
@export var action_move_left: StringName = &"p1_move_left"
@export var action_move_right: StringName = &"p1_move_right"
@export var action_jump: StringName = &"p1_jump"
@export var action_attack: StringName = &"p1_attack"
@export var action_heavy_attack: StringName = &"p1_heavy_attack"
#endregion


#region Combat state
enum AttackKind { LIGHT, HEAVY }

## Brief post-hit lock on left/right only so snappy ground move doesn't eat launch velocity.
const MOVE_LOCK_ON_HIT := 0.12
const ATTACK_CHARGE_MAX := 3
const LIGHT_HITSTOP := 0.1
const HIT_SPARK := preload("res://Scenes/VFX/HitSpark.tscn")

var attacking := false
var attack_startup := false
## True when this swing began airborne - hang in place for startup + active.
var _aerial_attack_hover := false
## Bumped to cancel an in-flight start_attack() after hurt interrupt.
var _attack_id := 0
var move_lock_timer := 0.0
var current_attack_kind: AttackKind = AttackKind.LIGHT
var current_hit: HitData
var total_damage := 0.0
var hit_lock := false
var attack_charge := 0
signal died
signal damage_changed
#endregion


#region Node refs
@onready var attack_area = $AttackArea
@onready var attack_collider = $AttackArea/AttackAreaCollider
@onready var sprite = $CharSprite2D

@export var facing_right := true
var _attack_collider_x := 0.0
#endregion


#region Lifecycle
func _ready() -> void:
	spawn_pos = global_position
	_attack_collider_x = absf(attack_collider.position.x)
	set_attack_hitbox_active(false)
	_apply_facing()


func _physics_process(delta) -> void:
	_tick_move_lock(delta)

	# Always resolve velocity, then move_and_slide. Never skip physics for attack or lock.
	if _aerial_attack_hover and attacking:
		_physics_aerial_hover()
	elif attack_startup or attacking:
		_physics_while_attacking(delta)
	elif move_lock_timer > 0.0:
		_physics_move_locked(delta)
	else:
		_physics_free_control(delta)

	move_and_slide()

	# Skip locomotion anims during startup telegraph (sprite is held on frame 0).
	if not attack_startup or attacking:
		_update_anims()

	if is_on_floor():
		coyote_timer = coyote_time
		jump_charge_left = jump_charge
#endregion


#region Physics branches
# Named branches keep the state machine readable. Order and side effects must match the old inline body.

func _tick_move_lock(delta) -> void:
	if move_lock_timer > 0.0:
		move_lock_timer = maxf(0.0, move_lock_timer - delta)


func _physics_aerial_hover() -> void:
	# Hang at swing height: gravity off + kill leftover velocity (Y drifts otherwise).
	velocity = Vector2.ZERO


func _physics_while_attacking(delta) -> void:
	_apply_gravity(delta)
	# Plant only on floor - airborne swing must not cancel launch X.
	if is_on_floor():
		velocity.x = 0


func _physics_move_locked(delta) -> void:
	# Hitstun: skip move/DI only so launch X isn't overwritten. Jump + attack stay free.
	_apply_gravity(delta)
	_handle_jump(delta)
	_try_start_attacks()


func _physics_free_control(delta) -> void:
	_apply_gravity(delta)
	_handle_air_di(delta)
	_handle_jump(delta)
	_handle_move(delta)
	# Attack after move so a same-frame plant isn't overwritten by run speed.
	_try_start_attacks()


func _try_start_attacks() -> void:
	if Input.is_action_just_pressed(action_attack):
		attack()
	if Input.is_action_just_pressed(action_heavy_attack):
		heavy_attack()
#endregion


#region Movement helpers
func _apply_gravity(delta) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta


func _handle_jump(delta) -> void:
	if not is_on_floor():
		coyote_timer = coyote_timer - delta
	if Input.is_action_just_pressed(action_jump):
		if is_on_floor() or coyote_timer > 0:
			velocity.y = JUMP_VELOCITY
			coyote_timer = 0  # Prevents unwanted double jump
		elif jump_charge_left > 0:
			velocity.y = JUMP_VELOCITY
			jump_charge_left -= 1
			# Spend the air jump for a snappy mid-air redirect without buffing free-fall DI.
			var direction = Input.get_axis(action_move_left, action_move_right)
			if direction:
				velocity.x = direction * AIR_JUMP_X_BOOST
				facing_right = direction > 0
				_apply_facing()


func _handle_move(delta) -> void:
	var direction = Input.get_axis(action_move_left, action_move_right)
	if is_on_floor():
		# Snappy ground: instant reverse / instant stop. No accel, no ice.
		if direction:
			velocity.x = direction * SPEED
			facing_right = direction > 0
			_apply_facing()
		else:
			velocity.x = 0
	else:
		_handle_air_di(delta)


func _handle_air_di(delta) -> void:
	# Weak fight against launch only - never hard-set to walk speed.
	var direction = Input.get_axis(action_move_left, action_move_right)
	if direction:
		velocity.x = move_toward(velocity.x, direction * SPEED, AIR_DI * delta)
		facing_right = direction > 0
		_apply_facing()


func _apply_facing() -> void:
	# flip_h only mirrors the texture; move the hitbox to match facing.
	sprite.flip_h = not facing_right
	attack_collider.position.x = _attack_collider_x if facing_right else -_attack_collider_x
#endregion


#region Animation
func _update_anims() -> void:
	if not is_on_floor():
		if velocity.y >= 0:
			_set_anim(&"fall_anim")
		else:
			_set_anim(&"jump_anim")
	elif absf(velocity.x) > 0.1:
		_set_anim(&"walk_anim")
	else:
		_set_anim(&"idle_anim")


func _set_anim(anim_name: StringName) -> void:
	if sprite.animation != anim_name:
		sprite.play(anim_name)
#endregion


#region Attack flow
func attack() -> void:
	await start_attack(AttackKind.LIGHT, action_attack, &"attack_anim")


func heavy_attack() -> void:
	if attack_charge < ATTACK_CHARGE_MAX:
		return
	attack_charge = maxi(0, attack_charge - 3)
	await start_attack(AttackKind.HEAVY, action_heavy_attack, &"heavy_attack_anim")


func start_attack(kind: AttackKind, action: StringName, anim: StringName) -> void:
	_attack_id += 1
	var attack_id := _attack_id
	attack_startup = true
	current_attack_kind = kind
	# Ground plant only - don't eat airborne knockback by starting a swing.
	if is_on_floor():
		velocity.x = 0
	sprite.animation = anim
	sprite.frame = 0
	sprite.pause()

	await _play_attack_startup_blink(kind)
	if attack_id != _attack_id:
		return

	# Hold-to-release: stay on telegraph until the button is up (or hurt cancels).
	if not await _wait_attack_hold_release(action, attack_id):
		return

	# Released -> active
	attack_startup = false
	attacking = true
	_aerial_attack_hover = not is_on_floor()
	if _aerial_attack_hover:
		velocity = Vector2.ZERO
	sprite.animation = anim
	sprite.frame = 1
	sprite.pause()
	_fill_current_hit(kind)
	set_attack_hitbox_active(true)
	await get_tree().create_timer(0.1).timeout
	if attack_id != _attack_id:
		return
	_end_attack_active()


func _wait_attack_hold_release(action: StringName, attack_id: int) -> bool:
	# False if hurt bumped _attack_id and cancelled this coroutine.
	if Input.is_action_pressed(action):
		while Input.is_action_pressed(action):
			await get_tree().process_frame
			if attack_id != _attack_id:
				return false
	return true


func _fill_current_hit(kind: AttackKind) -> void:
	current_hit = HitData.new()
	hit_lock = false
	if kind == AttackKind.LIGHT:
		current_hit.damage = 3.0
		current_hit.attack_power = 1.0
	else:
		current_hit.damage = 12.0
		current_hit.attack_power = 1.2
	current_hit.base_knockback = 100.0


func _end_attack_active() -> void:
	set_attack_hitbox_active(false)
	attacking = false
	_aerial_attack_hover = false


func set_attack_hitbox_active(state: bool) -> void:
	# Dummy HurtBox listens via area_entered, so it needs monitorable -
	# monitoring alone only affects AttackArea detecting others.
	# Must be deferred: toggling during area_entered is blocked by PhysicsServer2D.
	attack_area.set_deferred("monitoring", state)
	attack_area.set_deferred("monitorable", state)


func _play_attack_startup_blink(kind: AttackKind) -> void:
	# Light ~0.14s, heavy ~0.24s telegraph before hold-to-release.
	var blinks := 1 if kind == AttackKind.LIGHT else 4
	var attack_ready := 0.06 if kind == AttackKind.LIGHT else 0.16

	for i in blinks:
		sprite.modulate = Color(1.5, 1.5, 1.5, 0.75)
		await get_tree().create_timer(0.04).timeout
		sprite.modulate = Color.WHITE
		await get_tree().create_timer(0.04).timeout
	sprite.modulate = Color(2, 2, 2)
	await get_tree().create_timer(attack_ready).timeout
	sprite.modulate = Color.WHITE
	# Add ready SFX later in development
#endregion


#region Hit / death
func notify_attack_landed(victim: Node = null) -> void:
	if hit_lock or current_hit == null or victim == null or victim == self:
		return
	hit_lock = true
	set_attack_hitbox_active(false)
	# Lights only — heavies must not refill the heavy meter.
	if current_hit.damage <= 8.0:
		jump_charge_left += 1
		attack_charge += 1
		_light_freeze()
	if victim.has_method("hurt"):
		victim.hurt(current_hit, global_position.x, self.velocity.y)


func _on_hurt_box_area_entered(area: Area2D) -> void:
	var attacker := area.get_parent()
	# Own AttackArea overlaps this HurtBox - ignore self-hits.
	if attacker == null or attacker == self:
		return
	if attacker.has_method("notify_attack_landed"):
		attacker.notify_attack_landed(self)


func hurt(hit: HitData, attacker_x: float, attacker_velocity_y) -> void:
	if hit == null:
		return
	# Cancel any in-flight start_attack() so it cannot resume and fight knockback.
	_attack_id += 1
	attacking = false
	attack_startup = false
	_aerial_attack_hover = false
	set_attack_hitbox_active(false)
	if hit.damage <= 8:
		play_hit_blink()
		_light_freeze()
		game_manager.play_light_hit_fx("light")
	elif hit.damage >= 9:
		game_manager.play_impact()
	var spark := HIT_SPARK.instantiate()
	spark.lifetime = LIGHT_HITSTOP * 2
	get_tree().current_scene.add_child(spark)
	spark.global_position = $HurtBox/HurtBoxCollision.global_position
	spark.emitting = true  # only after position
	if absf(attacker_velocity_y) > 0:
		total_damage += hit.damage * 1.5
	else:
		total_damage += hit.damage
	damage_changed.emit(total_damage)
	var knockback_power: float = (
		hit.base_knockback + pow(total_damage, 1.5) * 0.25
	) * hit.attack_power

	var direction := signf(global_position.x - attacker_x)
	if direction == 0.0:
		direction = 1.0
	velocity = Vector2.ZERO
	velocity = Vector2(direction * knockback_power * 0.8, -knockback_power * 1.5)
	# Brief input lock only - physics still runs so launch X/Y persist.
	move_lock_timer = MOVE_LOCK_ON_HIT	

func play_hit_blink() -> void:
	for i in 2:
		sprite.modulate = Color(1.5, 1.5, 1.5, 0.55)
		await get_tree().create_timer(0.04).timeout
		sprite.modulate = Color.WHITE
		await get_tree().create_timer(0.04).timeout
	sprite.modulate = Color.WHITE

func die() -> void:
	total_damage = 0
	damage_changed.emit(total_damage)
	global_position = spawn_pos
	died.emit()
	velocity = Vector2.ZERO
#endregion

func _light_freeze():
	set_physics_process(false)
	await get_tree().create_timer(LIGHT_HITSTOP, true, false, true).timeout
	set_physics_process(true)
