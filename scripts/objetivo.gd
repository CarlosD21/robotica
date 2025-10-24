extends Area2D
class_name objetivo
var catched= false
var start_position := Vector2.ZERO
var clayer = 0
var cmask = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_position = global_position
	clayer=collision_layer
	cmask=collision_mask



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func reset():
	catched = false
	visible = true
	monitoring = true
	monitorable = true
	collision_layer = clayer
	collision_mask = cmask
	set_deferred("monitorable", true)

func catch():
	catched =true
	visible = false
	monitoring = false
	collision_layer = 0
	collision_mask = 0
	set_deferred("monitorable", false)

func _on_body_entered(body: Node2D) -> void:
	if body is robot && !catched && body.objetiveCatched == 0.0:
		body.ai_controller_2d.reward +=0.2
		body.objetiveCatched = 1.0
		print(body.name + " CAPTURA OBJETIVO")
		catch()
