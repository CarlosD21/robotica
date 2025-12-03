extends CharacterBody2D
class_name robot

@onready var ai_controller_2d: Node2D = $AIController2D
@onready var objective: objetivo = $"../Objetivo"
@onready var raycast_sensor_2d = $RaycastSensor2D
@onready var sprite: Sprite2D = $CharacterRobotIdle
@onready var reward_count: Label = $RewardCount
@onready var ball: Sprite2D = $ball
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
var radius = 0 
var base_half_width = 0
signal sig_win
signal sig_end_epi
# Movimiento
const SPEED = 450.0
const BASE_SMOOTH = 0.15
var desired_velocity := Vector2.ZERO
var last_action := Vector2.ZERO
# Estado
var win := false
var objectiveCatched := false
var rival_contact := false

var myBase = null
var originalPosition = null

var dist_obj = 0.0
var dist_base = 0.0
var myBaseSide = -1.0
var total_reward := 0.0
var observations := []
# Tiempo del episiodio
var timestep_count := 0.0
const MAX_TIMESTEPS := 1000
# Anti estancamiento
var steps_without_progress := 0
const MAX_STEPS_WITHOUT_PROGRESS := 50 

# Contadores para recompensas discretas
var distance_objetive := 0.0
var last_distance_objetive  := 0.0
var distance_base := 0.0
var last_distance_base  := 0.0
var distance_rival := 0.0
var last_distance_rival  := 0.0

# Recompensas
const REWARD_DISTANCE := 0.25
const REWARD_WIN := 15
const REWARD_OBJETIVE := 10
#Penalizaciones
const PENALTY_LOSE:= -10
const PENALTY_PROGRESS := -0.2
const PENALTY_TIMEOUT := -2.5
func _ready():
	originalPosition = collision_shape_2d.global_position
	if collision_shape_2d.shape is CircleShape2D:
		radius = collision_shape_2d.shape.radius * collision_shape_2d.global_scale.x
	dist_obj = max(originalPosition.distance_to(objective.position) - radius, 0.0)
	_update_observations() 
	
func _physics_process(delta):
	
	if timestep_count > MAX_TIMESTEPS:
		emit_signal("sig_end_epi")
	#Movimiento
	moveAIController(delta)
	move_with_arrows(delta)	
	if ai_controller_2d.new_action:
		timestep_count += 1
		steps_without_progress += 1
		ai_controller_2d.new_action = false

	set_reward()
	_update_observations()
	update_label()
	if win:
		win_game()
	
# ---------------------------------------------------
# OBSERVACIONES
# ---------------------------------------------------
func _get_observations() -> Array:
	if observations.size() == 0:
		_update_observations() 
	return observations
func set_dist_base():
	dist_base = max(abs(myBase.position.x - objective.position.x) - (radius + base_half_width),0.0)
func _update_observations():
	observations = []
	rival_contact = false
	var  near_distance_rival = last_distance_rival
	distance_objetive = 1.0 - clamp((collision_shape_2d.global_position.distance_to(objective.position) - radius) / dist_obj, 0.0, 1.0)
	if objectiveCatched:
		distance_base = 1.0 - clamp((abs(collision_shape_2d.global_position.x - myBase.position.x) - (radius + base_half_width)) / dist_base, 0.0, 1.0)
	else: 
		distance_base = 0.0
	observations.append(distance_objetive)
	observations.append(distance_base)
	observations.append(myBaseSide)
	observations.append(float(objectiveCatched))
	observations.append(float(objective.catched))
	# -----------------------------
	#  RAYCASTS
	# -----------------------------
	for ray in raycast_sensor_2d.rays:
		var distance := 0.0
		var collide_with := 0.0
		 
		if ray.is_colliding():
			var collider = ray.get_collider()
			distance = raycast_sensor_2d._get_raycast_distance(ray)
			# Rival detectado
			if collider is robot:
				collide_with = 1.0
				if distance > near_distance_rival:
					near_distance_rival = distance
				if distance > 0.80 and objective.catched:
					rival_contact = true
											
		observations.append(distance)
		observations.append(collide_with)
	distance_rival = near_distance_rival


# ---------------------------------------------------
# RECOMPENSAS
# ---------------------------------------------------
func set_reward():
	var reward_local := 0.0
	var threshold := 0.05
	# -------------------------------
	# Delta de distancia al objective
	# -------------------------------
	if not objectiveCatched and not objective.catched:
		var delta_obj = distance_objetive - last_distance_objetive
		if abs(delta_obj) > threshold:
			var plus =  REWARD_DISTANCE  * 0.5 * distance_objetive
			# positivo si se acerca, negativo si se aleja
			delta_obj = 1.0 if delta_obj > 0.0 else -1.0
			reward_local += delta_obj * (REWARD_DISTANCE + plus)
			last_distance_objetive = distance_objetive
			
	# -------------------------------
	# Delta de distancia a la base
	# -------------------------------
	if objectiveCatched:
		var delta_base = distance_base - last_distance_base
		if abs(delta_base) > threshold:
			var plus =  REWARD_DISTANCE  * 0.5 *  distance_base
			# positivo si se acerca, negativo si se aleja
			delta_base = 1.0 if delta_base > 0.0 else -1.0
			reward_local += delta_base * (REWARD_DISTANCE + plus)
			last_distance_base = distance_base
			
	# -------------------------------
	# Delta de distancia al rival
	# -------------------------------
	var delta_rival = distance_rival - last_distance_rival
	if abs(delta_rival) > threshold:
		delta_rival = 1.0 if delta_rival > 0.0 else -1.0
		# Yo tengo el objetivo: evitar
		if objectiveCatched or distance_rival >= 0.30:
			var plus = REWARD_DISTANCE  * (1 - distance_rival)
			reward_local -= delta_rival * (REWARD_DISTANCE + plus)
		# El rival tiene el objetivo: perseguir
		elif objective.catched:
			var plus = REWARD_DISTANCE  * (distance_rival)
			reward_local += delta_rival * (REWARD_DISTANCE + plus)
		last_distance_rival = distance_rival
		
	# -------------------------------
	# Estancamiento
	# -------------------------------
	if reward_local>0.0:
		steps_without_progress = 0
	# Aplicar penalización si no progresa
	if steps_without_progress >= MAX_STEPS_WITHOUT_PROGRESS:
		reward_local+= PENALTY_PROGRESS
		steps_without_progress = 0
		
	# -------------------------------
	# Contacto con rival
	# -------------------------------
	if rival_contact:
		if objectiveCatched:
			reward_local += PENALTY_LOSE
		elif objective.catched:
			reward_local += REWARD_WIN
			win = true
		
	add_reward(reward_local)

func add_reward(value):
	ai_controller_2d.reward += value
	total_reward += value

func win_game():
	emit_signal("sig_win")
	ai_controller_2d.done = true

func have_objetive():
	add_reward(REWARD_OBJETIVE)
	objectiveCatched = true
	ball.set_deferred("visible", true)
	
func end_episode_timeout():
	add_reward(PENALTY_TIMEOUT)
	ai_controller_2d.done = true
	
func update_label():
	reward_count.text = str("%.2f" % total_reward)
	reward_count.modulate = Color(1, 1, 1) if total_reward >= 0 else Color(1, 0.3, 0.3)

# ---------------------------------------------------
# RESET
# ---------------------------------------------------
func reset():
	objectiveCatched = false
	win = false
	total_reward = 0.0
	timestep_count = 0
	steps_without_progress = 0
	observations = []
	set_deferred("position", originalPosition)
	set_deferred("velocity", Vector2.ZERO)
	ball.set_deferred("visible", false)

	distance_objetive = 0.0
	last_distance_objetive = 0.0
	distance_base = 0.0
	last_distance_base = 0.0
	distance_rival = 0.0
	last_distance_rival = 0.0

	rival_contact = false
	dist_obj = max(originalPosition.distance_to(objective.position) - radius, 0.0)
	dist_base = 0.0
# ---------------------------------------------------
# MOVIMIENTO
# ---------------------------------------------------
func moveAIController(delta:float):
	var move_input := Vector2.ZERO

	if ai_controller_2d.new_action:
		move_input = ai_controller_2d.move
		if move_input.length() > 0.05:
			last_action = move_input
	else: move_input = last_action

	if move_input.length() > 1.0:
		move_input = move_input.normalized()
	last_action = move_input
	desired_velocity = move_input * SPEED
	velocity = velocity.move_toward(desired_velocity, SPEED * 0.25 * delta)
	move_and_slide()

func move_with_arrows(delta: float):
	var direction := Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1

	if direction != Vector2.ZERO:
		direction = direction.normalized()

	velocity = direction * SPEED * delta
	move_and_slide()
