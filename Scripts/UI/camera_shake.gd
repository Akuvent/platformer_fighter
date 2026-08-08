extends Camera2D
var cam := self
var trauma : float = 0
var time := 0.0
var strength := 0 
var attack_type : String

func add_trauma(amount, kind):
	trauma = clampf(trauma + amount, 0.0, 1.0)
	attack_type = kind
func _process(delta):
	if attack_type == "light":
		strength = (trauma * trauma) * 10
	elif attack_type == "heavy":
		strength = (trauma * trauma) * 100
	time += delta
	cam.offset.x = sin(time * 35) * strength
	cam.offset.y = sin(time * 20) * strength
	trauma = maxf(trauma - 1.2 * delta, 0.0)
