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
const BASE_SMOOTH = 0.15

# Estado
var myBase = null
var myBaseSide = -1.0
var objetiveCatched = 0.0
var win = false
var originalPosition
var total_reward := 0.0
signal sig_win

# Anti estancamiento
const STUCK_RADIUS = 40.0
const STUCK_TIME_LIMIT = 2.0
var last_stuck_check_pos := Vector2.ZERO
var time_in_same_area := 0.0

# Timeout llevando objetivo
var has_objetive_time := 0.0
const DELIVERY_TIME_LIMIT := 30.0

# Movimiento
var desired_velocity := Vector2.ZERO

# Asíncrono: acción anterior
var last_action := Vector2.ZERO

# ---- flags para recompensas discretas ----
var saw_objective_reward := 0.0
var saw_base_reward := 0.0
var saw_enemy_reward := 0.0

var saw_enemy_last := false
var exit_base:= false


func _ready():
	originalPosition = position
	last_stuck_check_pos = position


func _physics_process(delta):
	if win:
		win_game()

	moveAIController()
	check_stuck(delta)
	base_timeout(delta)
	update_label()

	move_and_slide()


# ---------------------------------------------------
# RESET
# ---------------------------------------------------
func reset():
	objetiveCatched = 0.0
	ai_controller_2d.done = true
	win = false
	total_reward = 0.0

	set_deferred("position", originalPosition)
	set_deferred("velocity", Vector2.ZERO)

	ball.set_deferred("visible", false)

	time_in_same_area = 0.0
	last_stuck_check_pos = originalPosition
	has_objetive_time = 0.0

	saw_objective_reward = 0.0
	saw_enemy_last = false
	saw_base_reward = false
	exit_base = false
# ---------------------------------------------------
# OBSERVACIONES Y RECOMPENSAS
# ---------------------------------------------------
func _get_observations() -> Array:
	var observations = []
	var reward_local := 0.0

	var saw_objective := false
	var saw_enemy := false
	var saw_own_base := false
	var enemy_contact := 0.0

	# Distancia al objetivo
	var dist_obj := position.distance_to(objetivo.position)
	observations.append(clamp(dist_obj / 1500.0, 0.0, 1.0))

	# -----------------------------
	#  RAYCASTS
	# -----------------------------
	for ray in raycast_sensor_2d.rays:
		var distance := 0.0

		if ray.is_colliding():
			var collider = ray.get_collider()
			distance = raycast_sensor_2d._get_raycast_distance(ray)

			# Objetivo detectado
			if collider is objetivo:
				saw_objective = true

			# Enemigo detectado
			elif collider is robot:
				saw_enemy = true
				if distance > 0.75:
					enemy_contact = 1.0

			# Base propia detectada
			elif collider is base:
				if collider == myBase:
					saw_own_base = true
			
			else: distance = 0.0
		observations.append(distance)

	observations.append(enemy_contact)
	observations.append(myBaseSide)
	observations.append(objetiveCatched)
	observations.append(objetivo.catched)


	# ---------------------------------------------------
	# RECOMPENSAS 
	# ---------------------------------------------------

	# ---- Ver objetivo por PRIMERA vez ----
	if saw_objective and  saw_objective_reward < 0.3:
		reward_local += 0.001
		saw_objective_reward += 0.001

	# ---- Ver enemigo ----
	if saw_enemy and not saw_enemy_last:

		# Enemigo sin objetivo: ignorar
		if objetivo.catched == 0.0:
			reward_local += 0.0

		# El enemigo tiene el objetivo: perseguir
		elif objetivo.catched == 1.0 and objetiveCatched == 0.0:
			reward_local += 0.3

		# Yo tengo el objetivo: evitar
		elif objetiveCatched == 1.0:
			reward_local -= 0.1
	if saw_enemy_last and not saw_enemy and objetiveCatched == 1.0:
			reward_local += 0.1	
			
	# ---- Ver tu base mientras llevas objetivo ----
	if saw_own_base and saw_base_reward < 0.3 and objetiveCatched == 1.0:
		reward_local += 0.001
		saw_base_reward+=0.001
		
	# ---- Contactos ----
	if enemy_contact == 1.0:
		if objetiveCatched == 1.0:
			reward_local -= 1.0 
		elif objetivo.catched == 1.0:
			win = true           

	# Guardar flags
	saw_enemy_last = saw_enemy

	add_reward(reward_local)
	return observations


# ---------------------------------------------------
# RECOMPENSAS
# ---------------------------------------------------
func check_stuck(delta):
	var moved := position.distance_to(last_stuck_check_pos)

	if moved < STUCK_RADIUS:
		time_in_same_area += delta
		if time_in_same_area > STUCK_TIME_LIMIT:
			add_reward(-0.2)
			time_in_same_area = 0.0
	else:
		time_in_same_area = 0.0
		last_stuck_check_pos = position


func add_reward(value):
	ai_controller_2d.reward += value
	total_reward += value


func win_game():
	add_reward(3.0)
	emit_signal("sig_win")


func have_objetive():
	add_reward(1.5)
	objetiveCatched = 1.0
	ball.set_deferred("visible", true)


func update_label():
	reward_count.text = str("%.2f" % total_reward)
	reward_count.modulate = Color(1, 1, 1) if total_reward >= 0 else Color(1, 0.3, 0.3)


func base_timeout(delta):
	if objetiveCatched == 1.0:
		has_objetive_time += delta

		if has_objetive_time > DELIVERY_TIME_LIMIT and total_reward > 1.5:
			add_reward(-0.001)


func end_episode_timeout():
	add_reward(-1.0)


# ---------------------------------------------------
# MOVIMIENTO
# ---------------------------------------------------
func moveAIController():
	var move_input := last_action

	if ai_controller_2d.new_action:
		move_input = ai_controller_2d.move
		last_action = move_input
		ai_controller_2d.new_action = false

	if move_input.length() < 0.05:
		move_input = Vector2.ZERO

	desired_velocity = move_input * SPEED

	velocity = velocity.move_toward(desired_velocity, SPEED * 0.25)
