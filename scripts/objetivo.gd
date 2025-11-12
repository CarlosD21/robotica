extends Area2D
class_name objetivo

var catched = 0.0
var start_position := Vector2.ZERO
var clayer = 0
var cmask = 0

func _ready() -> void:
	start_position = global_position
	clayer = collision_layer
	cmask = collision_mask

func reset():
	catched = 0.0
	visible = true
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	set_deferred("collision_layer", clayer)
	set_deferred("collision_mask", cmask)

func catch():
	catched = 1.0
	set_deferred("visible", false)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

func _on_body_entered(body: Node2D) -> void:
	if body is robot and catched == 0.0 and body.objetiveCatched == 0.0:
		body.add_reward(5.0)   # recompensa clara por capturar objetivo
		body.objetiveCatched = 1.0
		body.ball.set_deferred("visible", true)
		catch()
