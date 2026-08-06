extends CharacterBody2D

var total_damage := 0.0

@onready var sprite: Sprite2D = $DummySprite


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		# Bleed horizontal speed on the ground so launches don't slide forever.
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
	move_and_slide()


func _on_hurt_box_area_entered(area: Area2D) -> void:
	var attacker := area.get_parent()
	if attacker.has_method("notify_attack_landed"):
		attacker.notify_attack_landed(self)


func hurt(current_hit: HitData, attacker_x: float) -> void:
	total_damage += current_hit.damage
	# Base shove + percent^1.5 so high % launches ramp hard.
	var knockback_power: float = (
		current_hit.base_knockback + pow(total_damage, 1.5) * 0.25
	) * current_hit.attack_power

	var direction := signf(global_position.x - attacker_x)
	if direction == 0.0:
		direction = 1.0

	# Away on X, a bit of up so it reads as a hit.
	velocity = Vector2(direction * knockback_power * 0.8, -knockback_power * 1.5)


func play_hit_blink() -> void:
	for i in 2:
		sprite.modulate = Color(1.5, 1.5, 1.5, 0.55)
		await get_tree().create_timer(0.04).timeout
		sprite.modulate = Color.WHITE
		await get_tree().create_timer(0.04).timeout
	sprite.modulate = Color.WHITE
