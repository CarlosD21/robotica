extends CharacterBody2D
class_name robot

@onready var ai_controller_2d: Node2D = $AIController2D
@onready var objetivo: objetivo = $"../Objetivo"
@onready var raycast_sensor_2d = $RaycastSensor2D



const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var myBase = null
var myBaseSide = -1.0
var objetiveCatched = 0.0
var enemyTouchedMy = 0.0
var win = false
var originalPosition= null

func _physics_process(delta: float) -> void:
	if originalPosition == null:
		originalPosition = self.position
	# Add the gravity.
	 #if not is_on_floor():
	#	velocity += get_gravity() * delta

	# Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
	#	velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var directionX := Input.get_axis("ui_left", "ui_right")
	if directionX:
		velocity.x = directionX * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	var directionY := Input.get_axis("ui_up", "ui_down")
	if directionY:
		velocity.y = directionY * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)
	
	velocity.x = ai_controller_2d.move.x * SPEED
	velocity.y = ai_controller_2d.move.y * SPEED
	
	move_and_slide()

func reset() -> void:
	objetiveCatched = 0.0
	enemyTouchedMy = 0.0
	win = false
	self.position = originalPosition
	
func _get_observations() -> Array:
	var observations = []
	var isCollider = 0.0
		
	for ray in raycast_sensor_2d.rays:
		var distance = 0.0
		if ray.is_colliding():
			distance= raycast_sensor_2d._get_raycast_distance(ray)
			if ray.get_collider() is robot || ray.get_collider() is objetivo:
				print(name + " A DISTANCIA "+ str(distance) +" DE "+ ray.get_collider().name)
			if ray.get_collider() is robot && distance >= 0.9:
				print(name + " Ha sido Tocado por " + ray.get_collider().name)
				enemyTouchedMy=1.0
				enemyTouchedMy=1.0
				if objetiveCatched == 1.0:
					ai_controller_2d.reward -=0.1
				if  objetivo.catched && objetiveCatched == 0.0:
					ai_controller_2d.reward +=0.1
					win = true
					
			if ray.get_collider() is objetivo:
				ai_controller_2d.reward +=0.1
				print(name + " A DISTANCIA "+ str(distance) +" DE "+ ray.get_collider().name)

			if ray.get_collider() is robot && objetivo.catched && !objetiveCatched:
				ai_controller_2d.reward +=0.1
				
			if ray.get_collider() is base && ray.get_collider() == myBase && objetiveCatched:
				ai_controller_2d.reward +=0.1
				
			if ray.get_collider() is base && ray.get_collider() == myBase && !objetiveCatched:
				ai_controller_2d.reward -=0.1
				
		observations.append(distance)
	observations.append(enemyTouchedMy)
	observations.append(myBaseSide)
	observations.append(objetiveCatched)
	return observations
