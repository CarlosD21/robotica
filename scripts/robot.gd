extends CharacterBody2D
class_name robot

@onready var ai_controller_2d: Node2D = $AIController2D
@onready var objetivo: objetivo = $"../Objetivo"
@onready var raycast_sensor_2d = $RaycastSensor2D
@onready var sprite: Sprite2D = $CharacterRobotIdle
@onready var reward_count: Label = $RewardCount
@onready var ball: Sprite2D = $ball

const SPEED = 400.0
const ACCELERATION = 1200.0
const DECELERATION = 1600.0
const BASE_SMOOTH = 0.3
const TURN_SMOOTH = 0.6

# --- Estados ---
var myBase = null
var myBaseSide = -1.0
var objetiveCatched = 0.0
var win = false
var originalPosition = null
var total_reward := 0.0
# --- Detector de estancamiento ---
const STUCK_RADIUS = 40.0
const STUCK_TIME_LIMIT = 1.5
var last_stuck_check_pos := Vector2.ZERO
var time_in_same_area := 0.0

# --- Movimiento ---
var smoothed_move := Vector2.ZERO
var desired_velocity := Vector2.ZERO


func _ready() -> void:
	originalPosition = position
	last_stuck_check_pos = position


func _physics_process(delta: float) -> void:
	moveAIController(delta)
	check_stuck(delta)
	reward_for_movement()
	update_label()
	move_and_slide()


func reset() -> void:
	objetiveCatched = 0.0
	win = false
	total_reward = 0.0
	set_deferred("position", originalPosition)
	set_deferred("velocity", Vector2.ZERO)
	ball.set_deferred("visible", false)
	time_in_same_area = 0.0
	last_stuck_check_pos = originalPosition


func _get_observations() -> Array:
	var observations = []
	# --- VARIABLES AUXILIARES ---
	var enemyTouchedMy = 0.0
	var reward_local = 0.0

	# --- PROCESO DE RAYOS ---
	for ray in raycast_sensor_2d.rays:
		var distance = 1.0  # Normalizado (1.0 = sin colisión)
		if ray.is_colliding():
			var collider = ray.get_collider()
			distance = raycast_sensor_2d._get_raycast_distance(ray)
			
			# ---- Objetivo detectado ----
			if collider is objetivo:
				reward_local += 0.01  # incentivo a buscar el objetivo
			
			# ---- Rival detectado ----
			if collider is robot:
				if distance <= 0.75:
					# contacto directo
					if objetiveCatched == 1.0:
						reward_local -= 1.0  # castigo por ser alcanzado con objetivo
						enemyTouchedMy = 1.0
					elif objetivo.catched == 1.0 and objetiveCatched == 0.0:
						reward_local += 2.0  # premio por interceptar rival con objetivo
						win = true
				elif objetiveCatched == 1.0:
					reward_local -= 0.05  # pequeña penalización por estar muy cerca sin propósito

			# ---- Base detectada ----
			#elif collider is base:
			#	if collider == myBase and objetiveCatched == 1.0:
			#		reward_local += 0.05  # incentivo a volver a base
			#else:
				#reward_local -= 0.05  # penalización leve por mirar zonas vacías

		observations.append(distance)
	observations.append(enemyTouchedMy)
	observations.append(myBaseSide)
	observations.append(objetiveCatched)
	observations.append(objetivo.catched)
	add_reward(reward_local)
	return observations


# ----------------------
#   COMPORTAMIENTOS
# ----------------------
func reward_for_movement() -> void:
	if velocity.length() > 10.0:
		add_reward(0.001)


func add_reward(value: float) -> void:
	ai_controller_2d.reward += value
	total_reward += value

func check_stuck(delta: float) -> void:
	var distance = position.distance_to(last_stuck_check_pos)
	if distance < STUCK_RADIUS:
		time_in_same_area += delta
		if time_in_same_area > STUCK_TIME_LIMIT:
			add_reward(-0.5*delta)  # fuerte castigo por quedarse quieto
			time_in_same_area = 0.0
	else:
		last_stuck_check_pos = position
		time_in_same_area = 0.0

func update_label() -> void:
	reward_count.text = str("%.2f" % total_reward)
	reward_count.modulate = Color(1, 1, 1) if total_reward >= 0 else Color(1, 0.3, 0.3)
func moveAIController(delta: float) -> void:
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
