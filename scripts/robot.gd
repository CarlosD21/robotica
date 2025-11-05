extends CharacterBody2D
class_name robot

@onready var ai_controller_2d: Node2D = $AIController2D
@onready var objetivo: objetivo = $"../Objetivo"
@onready var raycast_sensor_2d = $RaycastSensor2D
@onready var sprite: Sprite2D = $CharacterRobotIdle

const SPEED = 400.0
const JUMP_VELOCITY = -400.0

var myBase = null
var myBaseSide = -1.0
var objetiveCatched = 0.0
var win = false
var originalPosition = null

# Parámetros ajustables
const BASE_SMOOTH = 0.3      # suavizado base
const TURN_SMOOTH = 0.6      # suavizado extra al girar
const ACCELERATION = 1200.0  # qué tan rápido acelera
const DECELERATION = 1600.0  # qué tan rápido frena

# Variables internas
var smoothed_move := Vector2.ZERO
var desired_velocity := Vector2.ZERO


func _ready() -> void:
	originalPosition = self.position


func _physics_process(delta: float) -> void:
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

	var move_input = ai_controller_2d.move

	# elimina ruido o movimientos muy pequeños
	if move_input.length() < 0.05:
		move_input = Vector2.ZERO

	# calcula cuánto cambia la dirección actual
	var turn_angle = 0.0
	if smoothed_move.length() > 0.01 and move_input.length() > 0.01:
		turn_angle = rad_to_deg(smoothed_move.angle_to(move_input))

	# ajusta suavizado dinámico
	var smooth_factor = lerp(BASE_SMOOTH, TURN_SMOOTH, clamp(abs(turn_angle) / 180.0, 0.0, 1.0))

	# interpola la dirección suavizada
	smoothed_move = smoothed_move.lerp(move_input, smooth_factor)

	# velocidad deseada
	desired_velocity = smoothed_move * SPEED

	# aceleración/frenado
	if desired_velocity.length() > velocity.length():
		velocity = velocity.move_toward(desired_velocity, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(desired_velocity, DECELERATION * delta)

	velocity = smoothed_move * SPEED
	move_and_slide()


func reset() -> void:
	objetiveCatched = 0.0
	win = false
	# ⚠️ set_deferred() evita errores de acceso al árbol de físicas durante reseteos
	set_deferred("position", originalPosition)
	set_deferred("velocity", Vector2.ZERO)
	set_deferred("visible", true)
	set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)


func _get_observations() -> Array:
	var observations = []
	var enemyTouchedMy = 0.0

	for ray in raycast_sensor_2d.rays:
		var distance = 0.0
		if ray.is_colliding():
			distance = raycast_sensor_2d._get_raycast_distance(ray)
					
			if ray.get_collider() is objetivo:
				ai_controller_2d.reward += 1.0

			elif ray.get_collider() is robot:
				if distance >= 0.70:
					if objetiveCatched == 1.0:
						enemyTouchedMy = 1.0
						ai_controller_2d.reward -= 0.75
					elif objetiveCatched == 0.0 and objetivo.catched:
						ai_controller_2d.reward += 1.0
						win = true
						#print(name + " GANA")
						#print("HA ALCANZADO A " + ray.get_collider().name)
				elif objetivo.catched and objetiveCatched == 0.0:
					ai_controller_2d.reward += 1.0
				else:
					ai_controller_2d.reward -= 0.25

			elif ray.get_collider() is base and ray.get_collider() == myBase:
				if objetiveCatched == 1.0:
					ai_controller_2d.reward += 0.5
				else:
					ai_controller_2d.reward -= 0.25
			else:
				ai_controller_2d.reward -= 0.05
						
		observations.append(distance)

	observations.append(enemyTouchedMy)
	observations.append(myBaseSide)
	observations.append(objetiveCatched)
	return observations
