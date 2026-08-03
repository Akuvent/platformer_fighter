extends Area2D
## Killbox under the level — falling off the map

func _on_body_entered(body):
	if body.has_method("die"):
		body.die()
