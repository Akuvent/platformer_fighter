extends CharacterBody2D

# Movement
const SPEED = 150
const JUMP_VELOCITY = -350.0
@export var jump_charge := 1
var jump_charge_left = 0

# Coyote time
@export var coyote_time := 0.1
var coyote_timer := 0.0

# Combat state
var stunned := false
var attacking := false
var attack_startup := false
var hit = false
@onready var attack_area = $AttackArea
@onready var sprite = $CharSprite2D



func _ready():
	attack_area.monitoring = false

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
				sprite.flip_h = min(0, direction)
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
		else:
			# Startup locks horizontal control; clear leftover run speed from held A/D
			velocity.x = 0

		move_and_slide()
	if not (attacking or attack_startup): # Stop anims while attacking
		# Animations
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


func attack():
	attack_startup = true
	velocity.x = 0
	sprite.animation = "attack"
	sprite.frame = 0
	sprite.pause()

	# Blink until ready
	for i in 2:
		sprite.modulate = Color(1.5, 1.5, 1.5, 0.75)
		await get_tree().create_timer(0.04).timeout
		sprite.modulate = Color.WHITE
		await get_tree().create_timer(0.04).timeout
	sprite.modulate = Color(2, 2, 2)
	await get_tree().create_timer(0.08).timeout
	sprite.modulate = Color.WHITE
	## Add ready SFX later in development
	

	# Released during startup -> cancel
	if not Input.is_action_pressed("attack"):
		return

	# Ready: wait for release
	while Input.is_action_pressed("attack"):
		await get_tree().process_frame
		# optional: keep a “ready” pose / blink here

	# Released -> active
	attack_startup = false
	attacking = true
	sprite.animation = "attack"
	sprite.frame = 1
	sprite.pause()
	attack_area.monitoring = true
	await get_tree().create_timer(0.1).timeout
	attack_area.monitoring = false
	attacking = false
	if hit == true:
		jump_charge_left += 1


func heavy_attack():
	attack_startup = true
	velocity.x = 0
	sprite.animation = "heavy_attack"
	sprite.frame = 0
	sprite.pause()

	# Blink until ready
	for i in 2:
		sprite.modulate = Color(1.5, 1.5, 1.5, 0.75)
		await get_tree().create_timer(0.04).timeout
		sprite.modulate = Color.WHITE
		await get_tree().create_timer(0.04).timeout
	sprite.modulate = Color(2, 2, 2)
	await get_tree().create_timer(0.08).timeout
	sprite.modulate = Color.WHITE
	## Add ready SFX later in development
	

	# Released during startup -> cancel
	if not Input.is_action_pressed("heavy_attack"):
		return

	# Ready: wait for release
	while Input.is_action_pressed("heavy_attack"):
		await get_tree().process_frame
		# optional: keep a “ready” pose / blink here

	# Released -> active
	attack_startup = false
	attacking = true
	sprite.animation = "heavy_attack"
	sprite.frame = 1
	sprite.pause()
	attack_area.monitoring = true
	await get_tree().create_timer(0.1).timeout
	attack_area.monitoring = false
	attacking = false


func die():
	get_tree().reload_current_scene()
