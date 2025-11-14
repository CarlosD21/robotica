extends Node2D
class_name campo

@onready var objetivo: objetivo = $Objetivo
@onready var robot := $robot
@onready var robot2 := $robot2

var episode_time := 0.0
const EPISODE_TIME_LIMIT := 12.0

func _process(delta):
	episode_time += delta

	# Timeout
	if episode_time >= EPISODE_TIME_LIMIT:
		robot.end_episode_timeout()
		robot2.end_episode_timeout()
		call_deferred("_reset_all")

	# Si alguno gana
	if robot.win or robot2.win:
		call_deferred("_reset_all")

func _reset_all():
	episode_time = 0.0
	objetivo.reset()
	robot.reset()
	robot2.reset()
