extends Node2D
class_name campo

@onready var objetivo: objetivo = $Objetivo
var episode_time := 0.0
const EPISODE_TIME_LIMIT := 12.0

func _process(delta):
	episode_time += delta

	# Timeout
	#if episode_time >= EPISODE_TIME_LIMIT:
		

	# Si alguno gana
	#for child in get_children():
		#if child is robot:
			#if child.win:
				#call_deferred("_reset_all")

func _reset_all():
	#episode_time = 0.0
	objetivo.reset()
	for child in get_children():
		if child is robot:
			child.reset()


func _on_timer_timeout() -> void:
	for child in get_children():
			if child is robot:
				child.end_episode_timeout()
				call_deferred("_reset_all")


func _on_robot_sig_win() -> void:
	call_deferred("_reset_all")
