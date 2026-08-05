extends CharacterBody2D
var health := 3

func _on_hurt_box_area_entered(area):
	game_manager.play_impact()
	health -= 1
