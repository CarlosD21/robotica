extends Node2D
class_name campo

@onready var objetivo: objetivo = $Objetivo
@onready var base_1: base = $base1
@onready var base_2: base = $base2


func _process(delta):
	pass
func _reset_all():
	objetivo.reset()
	for child in get_children():
		if child is robot:
			#swap_robot_bases(child)
			child.reset()
func _on_timer_timeout() -> void:
	for child in get_children():
			if child is robot:
				child.end_episode_timeout()
	call_deferred("_reset_all")
				
	
func swap_robot_bases(robot):
	if robot.myBaseSide == 0.0:
		robot.originalPosition = base_2.position
		robot.myBaseSide = 1.0
		robot.myBase = base_2
	else:
		robot.originalPosition = base_1.position
		robot.myBaseSide = 0.0
		robot.myBase = base_1

		#print("Intercambiadas bases entre: ", r1.name, " ↔ ", r2.name)


func _on_robot_sig_game_over() -> void:
	call_deferred("_reset_all")
func _on_robot_sig_end_epi() -> void:
	_on_timer_timeout()


func _on_dummy_sig_game_over() -> void:
	call_deferred("_reset_all")
