extends Area2D
class_name objetivo
var catched= false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func reset():
	catched = false
	visible = true
	monitoring = true
	monitorable = true
	set_deferred("monitorable", true)

func catch():
	catched =true
	visible = false
	monitoring = false
	set_deferred("monitorable", false)


func _on_body_entered(body: Node2D) -> void:
	if body is robot && !catched && body.objetiveCatched == 0.0:
		body.ai_controller_2d.reward +=0.2
		body.objetiveCatched = 1.0
		print(body.name + " CAPTURA OBJETIVO")
		catch()
