extends Node2D
class_name campo

@onready var objetivo: objetivo = $Objetivo
@onready var robot: robot = $robot
@onready var robot_2: robot = $robot2

func _ready() -> void:
	pass


func _process(delta: float) -> void:
	# Usamos deferred para evitar conflictos durante señales de colisión
	if robot.win or robot_2.win:
		call_deferred("_reset_all")


func _reset_all() -> void:
	objetivo.reset()
	robot.reset()
	robot_2.reset()
