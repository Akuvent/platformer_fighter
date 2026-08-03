extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func play_impact() -> void:
	var rect := get_tree().current_scene.get_node("VFX/ImpactRect") # adjust path
	rect.visible = true
	await get_tree().create_timer(0.05).timeout  # ~3 frames at 60fps
	rect.visible = false
	await get_tree().create_timer(0.025).timeout  # ~1.5 frames at 60fps
	rect.visible = true
	await get_tree().create_timer(0.05).timeout  # ~3 frames at 60fps
	rect.visible = false
