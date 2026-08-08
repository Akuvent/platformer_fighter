extends Node
## Tiny one-shot pool for the hit lab. Call named helpers; pitch variance keeps repeats from feeling flat.

const POOL_SIZE := 10

const JUMP := preload("res://Sprites/Sounds/12_Player_Movement_SFX/30_Jump_03.wav")
const WHOOSH_LIGHT := preload("res://Sprites/Sounds/Other/whoosh_1.wav")
const WHOOSH_HEAVY := preload("res://Sprites/Sounds/Other/whoosh_2.wav")
const ATTACK_READY := preload("res://Sprites/Sounds/Weapons/weapon_equip_short.wav")
const HURT := preload("res://Sprites/Sounds/Retro/hurt.wav")
const FOOTSTEPS: Array[AudioStream] = [
	preload("res://Sprites/Sounds/Footsteps/digital/digital_footstep_wood_1.wav"),
	preload("res://Sprites/Sounds/Footsteps/digital/digital_footstep_wood_2.wav"),
	preload("res://Sprites/Sounds/Footsteps/digital/digital_footstep_wood_3.wav"),
	preload("res://Sprites/Sounds/Footsteps/digital/digital_footstep_wood_4.wav"),
]
const LIGHT_HITS: Array[AudioStream] = [
	preload("res://Sprites/Sounds/Combat and Gore/punch.wav"),
	preload("res://Sprites/Sounds/Combat and Gore/punch_2.wav"),
	preload("res://Sprites/Sounds/Combat and Gore/punch_3.wav"),
]
const HEAVY_HITS: Array[AudioStream] = [
	preload("res://Sprites/Sounds/Combat and Gore/kick.wav")
]
const HEAVY_BOOM := preload("res://Sprites/Sounds/Retro/explosion_quick.wav")

var _pool: Array[AudioStreamPlayer] = []


func _ready() -> void:
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = &"Master"
		add_child(player)
		_pool.append(player)


func play(stream: AudioStream, volume_db := 0.0, pitch := 1.0) -> void:
	if stream == null:
		return
	var player := _acquire()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()


func play_random(streams: Array[AudioStream], volume_db := 0.0, pitch_min := 0.94, pitch_max := 1.06) -> void:
	if streams.is_empty():
		return
	play(streams[randi() % streams.size()], volume_db, randf_range(pitch_min, pitch_max))


func jump(_airborne := false) -> void:
	play(JUMP, -4.0, randf_range(0.98, 1.05))


func attack_ready() -> void:
	play(ATTACK_READY, -16.0, randf_range(1.05, 1.15))


func swing(heavy := false) -> void:
	if heavy:
		play(WHOOSH_HEAVY, -2.0, randf_range(0.9, 1.0))
	else:
		play(WHOOSH_LIGHT, -7.0, randf_range(0.95, 1.08))


func light_hit() -> void:
	play_random(LIGHT_HITS, -5.0)


func heavy_hit() -> void:
	play_random(HEAVY_HITS, 0.0, 0.9, 1.02)
	play(HEAVY_BOOM, -6.0, randf_range(0.85, 1.0))


func hurt() -> void:
	play(HURT, -3.0, randf_range(0.95, 1.08))


func footstep() -> void:
	play_random(FOOTSTEPS, -10.0, 0.92, 1.08)


func _acquire() -> AudioStreamPlayer:
	for player in _pool:
		if not player.playing:
			return player
	return _pool[0]
