extends CharacterBody2D

# --- Movement ---
const SPEED = 150
const JUMP_VELOCITY = -350.0
@export var jump_charge := 1
var jump_charge_left = 0

# Coyote time
@export var coyote_time := 0.1
var coyote_timer := 0.0

# --- Combat state ---
enum AttackKind { LIGHT, HEAVY }

var stunned := false
var attacking := false
var attack_startup := false
var current_attack_kind: AttackKind = AttackKind.LIGHT

@onready var attack_area = $AttackArea
@onready var attack_collider = $AttackArea/AttackAreaCollider
@onready var sprite = $CharSprite2D

var facing_right := true
var _attack_collider_x := 0.0


func _ready():
	_attack_collider_x = absf(attack_collider.position.x)
	set_attack_hitbox_active(false)
	_apply_facing()


# --- Physics / input ---
func _physics_process(delta):
	if not (stunned or attacking): # No movement + gravity while in active part of attack
		# Gravity
		if not is_on_floor():
			velocity += get_gravity() * delta

		if not attack_startup: # No movement while preparing an attack
			# Attacks
			if Input.is_action_just_pressed("attack"):
				attack()
			if Input.is_action_just_pressed("heavy_attack"):
				heavy_attack()

			# Jump + coyote time
			if not is_on_floor():
				coyote_timer = coyote_timer - delta
			if Input.is_action_just_pressed("jump"):
				if is_on_floor() or coyote_timer > 0:
					velocity.y = JUMP_VELOCITY
					coyote_timer = 0  # Prevents unwanted double jump
				elif jump_charge_left > 0:
					velocity.y = JUMP_VELOCITY
					jump_charge_left -= 1
			# Horizontal movement
			var direction = Input.get_axis("move_left", "move_right")
			if direction and stunned == false:
				velocity.x = direction * SPEED
				facing_right = direction > 0
				_apply_facing()
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
		else:
			# Startup locks horizontal control; clear leftover run speed from held A/D
			velocity.x = 0

		move_and_slide()

	# --- Anims ---
	if not (attacking or attack_startup): # Stop anims while attacking
		if not is_on_floor() and velocity.y >= 0:
			sprite.animation = "jump"
			sprite.frame = 1  # Fall frame
			sprite.pause()
		elif not is_on_floor():
			sprite.animation = "jump"
			sprite.frame = 0  # Jump frame
			sprite.pause()
		elif is_on_floor() and velocity.x != 0:
			sprite.play("walk")
		else:
			sprite.play("idle")

	# Refresh coyote time while grounded
	if is_on_floor():
		coyote_timer = coyote_time
		jump_charge_left = jump_charge


# --- Attack flow ---
func attack():
	await start_attack(AttackKind.LIGHT, &"attack", &"attack")


func heavy_attack():
	await start_attack(AttackKind.HEAVY, &"heavy_attack", &"heavy_attack")


func start_attack(kind: AttackKind, action: StringName, anim: StringName) -> void:
	attack_startup = true
	current_attack_kind = kind
	velocity.x = 0
	sprite.animation = anim
	sprite.frame = 0
	sprite.pause()

	await _play_attack_startup_blink(kind)

	# Released during startup -> cancel
	if not Input.is_action_pressed(action):
		_cancel_attack_startup()
		return

	# Ready: wait for release
	while Input.is_action_pressed(action):
		await get_tree().process_frame

	# Released -> active
	attack_startup = false
	attacking = true
	sprite.animation = anim
	sprite.frame = 1
	sprite.pause()
	set_attack_hitbox_active(true)
	await get_tree().create_timer(0.1).timeout
	set_attack_hitbox_active(false)
	attacking = false


func set_attack_hitbox_active(active: bool) -> void:
	# Dummy HurtBox listens via area_entered, so it needs monitorable —
	# monitoring alone only affects AttackArea detecting others.
	# Must be deferred: toggling during area_entered is blocked by PhysicsServer2D.
	attack_area.set_deferred("monitoring", active)
	attack_area.set_deferred("monitorable", active)


func _apply_facing() -> void:
	# flip_h only mirrors the texture; move the hitbox to match facing.
	sprite.flip_h = not facing_right
	attack_collider.position.x = _attack_collider_x if facing_right else -_attack_collider_x


func _play_attack_startup_blink(kind: AttackKind) -> void:
	# Light ~0.14s, heavy ~0.24s telegraph before hold-to-release.
	var blinks := 1 if kind == AttackKind.LIGHT else 2
	var attack_ready := 0.06 if kind == AttackKind.LIGHT else 0.08

	for i in blinks:
		sprite.modulate = Color(1.5, 1.5, 1.5, 0.75)
		await get_tree().create_timer(0.04).timeout
		sprite.modulate = Color.WHITE
		await get_tree().create_timer(0.04).timeout
	sprite.modulate = Color(2, 2, 2)
	await get_tree().create_timer(attack_ready).timeout
	sprite.modulate = Color.WHITE
	## Add ready SFX later in development


func _cancel_attack_startup() -> void:
	attack_startup = false
	set_attack_hitbox_active(false)


# --- Hit callbacks ---
# Dummy owns taking damage; attacker owns juice on connect.
func notify_attack_landed(victim: Node = null) -> void:
	set_attack_hitbox_active(false)
	match current_attack_kind:
		AttackKind.HEAVY:
			game_manager.play_impact()
		AttackKind.LIGHT:
			if victim and victim.has_method("play_hit_blink"):
				victim.play_hit_blink()


func die():
	# Scene reload removes CollisionObjects; can't do that mid physics callback.
	get_tree().call_deferred("reload_current_scene")
