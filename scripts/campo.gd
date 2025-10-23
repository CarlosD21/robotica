extends Node2D
class_name campo
@onready var objetivo: objetivo = $Objetivo
@onready var robot: robot = $robot
@onready var robot_2: robot = $robot2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if robot.win ||  robot_2.win:
		objetivo.reset()
		robot.reset()
		robot_2.reset()
