extends CharacterBody2D
class_name robot

@onready var ai_controller_2d: Node2D = $AIController2D
@onready var objetivo: objetivo = $"../Objetivo"
@onready var raycast_sensor_2d = $RaycastSensor2D
@onready var sprite: Sprite2D = $CharacterRobotIdle
@onready var reward_count: Label = $RewardCount
@onready var ball: Sprite2D = $ball

# Movimiento
const SPEED = 400.0
const ACCELERATION = 1200.0
const DECELERATION = 1600.0
const BASE_SMOOTH = 0.3
const TURN_SMOOTH = 0.6

# Estado
var myBase = null
var myBaseSide = -1.0
var objetiveCatched = 0.0
var win = false
var originalPosition
var total_reward := 0.0

# Anti estancamiento
const STUCK_RADIUS = 40.0
const STUCK_TIME_LIMIT = 2.0
var last_stuck_check_pos := Vector2.ZERO
var time_in_same_area := 0.0

# Movimiento interno
var smoothed_move := Vector2.ZERO
var desired_velocity := Vector2.ZERO

func _ready():
	originalPosition = position
	last_stuck_check_pos = position

func _physics_process(delta):
	moveAIController(delta)
	check_stuck(delta)
	update_label()
	move_and_slide()

func reset():
	objetiveCatched = 0.0
	win = false
	total_reward = 0.0
	set_deferred("position", originalPosition)
	set_deferred("velocity", Vector2.ZERO)
	ball.set_deferred("visible", false)
	time_in_same_area = 0.0
	last_stuck_check_pos = originalPosition

func end_episode_timeout():
	add_reward(-2.0) 
	ai_controller_2d.done = true

# -------------------------------------------
# OBSERVACIONES Y RECOMPENSAS
# -------------------------------------------
#+---------------------------+-----------+---------------------------------------------+
#| Evento / Situación       | Recompensa| Qué enseña                                   |
#+---------------------------+-----------+---------------------------------------------+
#| Capturar objetivo         |   +1.0    | Buscar el objetivo, avanzar hacia él        |
#| Llevar objetivo a base    |   +3.0    | Convertir → misión terminada                |
#| Ver el objetivo           |  +0.01    | Orientar la cámara hacia el objetivo        |
#| Ver enemigo con objetivo  |   +2.0    | Interceptar, defender, anticipar            |
#| Acercarse a tu base con   |           |                                             |
#| el objetivo               |  +0.03    | Volver rápidamente con trayectorias óptimas |
#+---------------------------+-----------+---------------------------------------------+
#| Estancamiento             |  -0.4     | Nunca quedarse quieto                        |
#| Ver enemigo sin objetivo  | -0.1      | No perseguir sin sentido                     |
#| Entrar a base sin objetivo|  -0.3     | No regresar sin nada (“no aburrirse”)        |
#| Timeout                   |  -2.0     | Actuar rápido, no dar vueltas                |
#+---------------------------+-----------+---------------------------------------------+

func _get_observations() -> Array:
	var observations = []
	var enemy_contact = 0.0
	var reward_local = 0.0

	# Distancia al objetivo normalizada (info útil)
	if(objetivo.catch()==0.0):
		var dist_obj = position.distance_to(objetivo.position)
		observations.append(clamp(dist_obj / 1500.0, 0.0, 1.0))

	# RAYCASTS
	for ray in raycast_sensor_2d.rays:
		var distance = 1.0
		if ray.is_colliding():
			var collider = ray.get_collider()
			distance = raycast_sensor_2d._get_raycast_distance(ray)

			# Objetivo detectado
			if collider is objetivo:
				reward_local += 0.01  

			# Rival detectado
			if collider is robot:
				if distance < 0.75:
					if objetiveCatched == 1.0:
						reward_local -= 1.5
					elif objetivo.catched == 1.0 and objetiveCatched == 0.0:
						reward_local += 2.0
						win = true
					enemy_contact = 1.0
				else:
					reward_local -= 0.1

			# Base detectada
			if collider is base:
				if collider == myBase and objetiveCatched == 1.0:
					reward_local += 0.03

		observations.append(distance)

	# Estado propio y del rival
	observations.append(enemy_contact)
	observations.append(myBaseSide)
	observations.append(objetiveCatched)
	observations.append(objetivo.catched)

	add_reward(reward_local)
	return observations

# -------------------------------------------
# RECOMPENSAS AUXILIARES
# -------------------------------------------
func check_stuck(delta):
	var moved = position.distance_to(last_stuck_check_pos)
	if moved < STUCK_RADIUS:
		time_in_same_area += delta
		if time_in_same_area > STUCK_TIME_LIMIT:
			add_reward(-0.4)   
			time_in_same_area = 0.0
	else:
		last_stuck_check_pos = position
		time_in_same_area = 0.0

func add_reward(value):
	ai_controller_2d.reward += value
	total_reward += value

func update_label():
	reward_count.text = str("%.2f" % total_reward)
	reward_count.modulate = Color(1, 1, 1) if total_reward >= 0 else Color(1, 0.3, 0.3)

# -------------------------------------------
# MOVIMIENTO
# -------------------------------------------
func moveAIController(delta):
	var move_input = ai_controller_2d.move
	if move_input.length() < 0.05:
		move_input = Vector2.ZERO

	var turn_angle = 0.0
	if smoothed_move.length() > 0.01 and move_input.length() > 0.01:
		turn_angle = rad_to_deg(smoothed_move.angle_to(move_input))

	var smooth_factor = lerp(BASE_SMOOTH, TURN_SMOOTH, clamp(abs(turn_angle) / 180.0, 0.0, 1.0))
	smoothed_move = smoothed_move.lerp(move_input, smooth_factor)
	desired_velocity = smoothed_move * SPEED

	if desired_velocity.length() > velocity.length():
		velocity = velocity.move_toward(desired_velocity, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(desired_velocity, DECELERATION * delta)

	velocity = smoothed_move * SPEED
