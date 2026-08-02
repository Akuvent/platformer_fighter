extends CharacterBody2D

const SPEED = 150
const JUMP_VELOCITY = -350.0
@export var coyote_time := 0.1
var coyote_timer := 0.0
@onready var sprite = $AnimatedSprite2D
var stunned := false

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if not is_on_floor():
		coyote_timer = coyote_timer - delta
	if Input.is_action_just_pressed("jump") and (is_on_floor() or coyote_timer > 0) :
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("move_left", "move_right")
	if direction and stunned == false:
		velocity.x = direction * SPEED
		sprite.flip_h = min(0, direction)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	

	
	move_and_slide()
	#animations
	if not is_on_floor() and velocity.y >= 0:
		sprite.animation = "jump"
		sprite.frame = 1
		sprite.pause()   
	elif not is_on_floor():
		sprite.animation = "jump"
		sprite.frame = 0
		sprite.pause() 
	elif is_on_floor() and velocity.x != 0:
		sprite.play("walk")
	else:
		sprite.play("idle")
	if is_on_floor():
		coyote_timer = coyote_time
