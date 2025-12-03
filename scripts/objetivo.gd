extends Area2D
class_name objetivo

var catched = false
var start_position := Vector2.ZERO
var original_layer := 0
var original_mask := 0

func _ready():
	start_position = global_position
	original_layer = collision_layer
	original_mask = collision_mask

func reset():
	catched = false
	set_deferred("visible", true)
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	set_deferred("collision_layer", original_layer)
	set_deferred("collision_mask", original_mask)
	global_position = start_position

func catch():
	catched = true
	set_deferred("visible", false)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

func _on_body_entered(body):
	if body is robot and not catched and not body.objectiveCatched:
		body.have_objetive()
		body.set_dist_base()
		catch()
