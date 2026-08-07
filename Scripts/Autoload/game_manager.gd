extends Node

const P1_MAX_HEALTH = 3
const P2_MAX_HEALTH = 3
## Display frames via process_frame (not create_timer — arg order makes ignore_time_scale easy to get wrong).
const IMPACT_INVERT_FRAMES := 5
const IMPACT_BLACKOUT_FRAMES := 5
const IMPACT_TIME_SCALE := 0.05

var p1_health_anim: AnimatedSprite2D
var p2_health_anim: AnimatedSprite2D
var p1_health := 0
var p2_health := 0
var p1_total_damage : Label
var p2_total_damage : Label
var _impact_playing := false

func _ready() -> void:
	call_deferred("_init_health_ui")


func _init_health_ui() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	p1_total_damage = scene.get_node_or_null("UI/SubViewportContainer/SubViewport/P1_Percent") as Label
	p2_total_damage = scene.get_node_or_null("UI/SubViewportContainer/SubViewport/P2_Percent") as Label
	p1_health_anim = scene.get_node_or_null("UI/P1_Health") as AnimatedSprite2D
	p2_health_anim = scene.get_node_or_null("UI/P2_Health") as AnimatedSprite2D
	p1_health = P1_MAX_HEALTH
	p2_health = P2_MAX_HEALTH

	if is_instance_valid(p1_health_anim):
		p1_health_anim.frame = p1_health
	if is_instance_valid(p2_health_anim):
		p2_health_anim.frame = p2_health
	var p1 := scene.get_node_or_null("PlayerBody1")
	var p2 := scene.get_node_or_null("PlayerBody2")
	# Fresh players after reload — connect once each.
	if p1 and not p1.died.is_connected(_on_p1_died):
		p1.died.connect(_on_p1_died)
	if p2 and not p2.died.is_connected(_on_p2_died):
		p2.died.connect(_on_p2_died)
	if p1 and not p1.damage_changed.is_connected(_on_p1_damaged):
		p1.damage_changed.connect(_on_p1_damaged)
	if p2 and not p2.damage_changed.is_connected(_on_p2_damaged):
		p2.damage_changed.connect(_on_p2_damaged)

func _on_p1_damaged(amount):
	var t := clampf(amount / 100.0, 0.0, 1.0)
	var col: Color
	if t < 0.5:
		col = Color.WHITE.lerp(Color.YELLOW, t)
	else:
		col = Color.YELLOW.lerp(Color.RED, t)
	p1_total_damage.text = str(amount + 100) + "%"
	p1_total_damage.label_settings.font_color = col
func _on_p2_damaged(amount):
	var t := clampf(amount / 100.0, 0.0, 1.0)
	var col : Color
	if t < 0.5:
		col = Color.WHITE.lerp(Color.YELLOW, t / 0.5)
	else:
		col = Color.YELLOW.lerp(Color.RED, (t - 0.5) / 0.5)
	p2_total_damage.text = str(amount + 100) + "%"
	p2_total_damage.label_settings.font_color = col

func _on_p1_died() -> void:
	p1_health = maxi(0, p1_health - 1)
	if is_instance_valid(p1_health_anim):
		p1_health_anim.frame = p1_health
	if p1_health <= 0:
		await _reload_stage()


func _on_p2_died() -> void:
	p2_health = maxi(0, p2_health - 1)
	if is_instance_valid(p2_health_anim):
		p2_health_anim.frame = p2_health
	if p2_health <= 0:
		await _reload_stage()


func _reload_stage() -> void:
	var tree := get_tree()
	var path := tree.current_scene.scene_file_path
	tree.change_scene_to_file(path)
	# Wait until the new stage (and its UI) actually exists.
	for i in 10:
		await tree.process_frame
		var scene := tree.current_scene
		if scene and scene.get_node_or_null("UI/P1_Health"):
			_init_health_ui()
			return
	push_error("game_manager: stage failed to reload UI")


func play_impact() -> void:
	if _impact_playing:
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var rect := scene.get_node_or_null("VFX/ImpactRect") as CanvasItem
	if rect == null:
		return

	_impact_playing = true
	var mat := rect.material as ShaderMaterial
	var cam := scene.get_node_or_null("Camera2D") as Camera2D
	var base_zoom := Vector2.ONE
	if cam:
		base_zoom = cam.zoom
		cam.zoom = base_zoom * 1.06

	Engine.time_scale = IMPACT_TIME_SCALE
	if mat:
		mat.set_shader_parameter("style", 1)
	# Warm up screen_texture while invisible — first visible frame is often garbage.
	rect.modulate.a = 0.0
	rect.visible = true
	await get_tree().process_frame
	rect.modulate.a = 1.0
	await _wait_frames(IMPACT_INVERT_FRAMES)

	if mat:
		mat.set_shader_parameter("style", 2)
		mat.set_shader_parameter("scratch_seed", randf() * 1000.0)
	await _wait_frames(IMPACT_BLACKOUT_FRAMES)

	rect.visible = false
	rect.modulate.a = 1.0
	Engine.time_scale = 1.0
	if mat:
		mat.set_shader_parameter("style", 1)
	if cam:
		cam.zoom = base_zoom
	_impact_playing = false


func _wait_frames(frames: int) -> void:
	for i in maxi(frames, 1):
		await get_tree().process_frame
