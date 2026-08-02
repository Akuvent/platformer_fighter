extends CharacterBody2D

# Movement
const SPEED = 150
const JUMP_VELOCITY = -350.0

# Coyote time
@export var coyote_time := 0.1
var coyote_timer := 0.0

# Combat state
var stunned := false
var attacking := false
var attack_startup := false
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
			if Input.is_action_just_pressed("jump") and (is_on_floor() or coyote_timer > 0):
				velocity.y = JUMP_VELOCITY
				coyote_timer = 0  # Prevents double jump

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


func attack():
	# Startup
	attack_startup = true
	velocity.x = 0
	sprite.animation = "attack"
	sprite.frame = 0 # Startup frame
	sprite.pause()
	for i in 2:  # 3 blinks during startup
		sprite.modulate = Color(1.5, 1.5, 1.5, 0.75)
		await get_tree().create_timer(0.04).timeout
		sprite.modulate = Color.WHITE
		await get_tree().create_timer(0.04).timeout
	# Ready blink
	sprite.modulate = Color(2, 2, 2)
	await get_tree().create_timer(0.16).timeout
	sprite.modulate = Color.WHITE
	attack_startup = false
	## Play sound attack ready later in development

	# Active
	attacking = true
	sprite.play("attack")
	attack_area.monitoring = true
	await get_tree().create_timer(0.1).timeout  # active window
	attacking = false
	attack_area.monitoring = false

	# Recovery
	recovery()



func heavy_attack():
	# Startup
	attack_startup = true
	sprite.animation = "heavy_attack"
	sprite.frame = 0  # Startup frame
	sprite.pause()
	attack_startup = false

	# Active
	attacking = true
	sprite.play("heavy_attack")
	attack_area.monitoring = true
	attacking = false
	attack_area.monitoring = false

	# Recovery
	recovery()

func recovery(): # WIP
	pass
