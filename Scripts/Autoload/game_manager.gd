extends Node


func play_impact() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var rect := scene.get_node_or_null("VFX/ImpactRect") as CanvasItem
	if rect == null:
		return

	rect.visible = true
	await get_tree().create_timer(0.05).timeout  # ~3 frames at 60fps
	rect.visible = false
	await get_tree().create_timer(0.025).timeout  # ~1.5 frames at 60fps
	rect.visible = true
	await get_tree().create_timer(0.05).timeout  # ~3 frames at 60fps
	rect.visible = false
