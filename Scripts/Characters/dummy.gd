extends CharacterBody2D

var health := 3

@onready var sprite: Sprite2D = $DummySprite


# Receive a hit from an overlapping attack area.
# Attacker handles juice (impact / blink request); dummy owns health.
func _on_hurt_box_area_entered(area: Area2D) -> void:
	var attacker := area.get_parent()
	if attacker.has_method("notify_attack_landed"):
		attacker.notify_attack_landed(self)
	health -= 1


func play_hit_blink() -> void:
	for i in 2:
		sprite.modulate = Color(1.5, 1.5, 1.5, 0.55)
		await get_tree().create_timer(0.04).timeout
		sprite.modulate = Color.WHITE
		await get_tree().create_timer(0.04).timeout
	sprite.modulate = Color.WHITE
