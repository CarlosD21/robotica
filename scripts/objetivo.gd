extends Area2D
class_name objetivo

var catched = false
var start_position := Vector2.ZERO
var clayer = 0
var cmask = 0

func _ready() -> void:
	start_position = global_position
	clayer = collision_layer
	cmask = collision_mask


func _process(delta: float) -> void:
	pass


func reset():
	catched = false
	visible = true
	# Cambiar propiedades físicas con set_deferred para evitar conflictos
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	set_deferred("collision_layer", clayer)
	set_deferred("collision_mask", cmask)


func catch():
	catched = true
	# Estas llamadas son las que causaban el error, las cambiamos a diferidas
	set_deferred("visible", false)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)


func _on_body_entered(body: Node2D) -> void:
	if body is robot and not catched and body.objetiveCatched == 0.0:
		body.ai_controller_2d.reward +=1.0
		body.objetiveCatched = 1.0
		#print(body.name + " CAPTURA OBJETIVO")
		catch()
