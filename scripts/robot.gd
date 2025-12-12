extends CharacterBody2D
class_name robot

var ai_controller_2d: Node2D
var sprite: Sprite2D
var reward_count: Label 
var vision: Node2D
var proximity: RaycastSensor2D
var namelabel: Label

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var ball: Sprite2D = $ball

@export  var objective: objetivo
@export var myBase: base
@export var base_red: base
@export var base_blue: base

var radius = 0 
signal sig_game_over
signal sig_end_epi
# Movimiento
const SPEED = 450.0
const BASE_SMOOTH = 0.15
var desired_velocity := Vector2.ZERO
var last_action := Vector2.ZERO
# Estado
var win := false
var lose := false
var objectiveCatched := false
var rival_contact := false

var originalPosition = null

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
var distance_mate := 0.0
var last_distance_mate  := 0.0
# Recompensas
const REWARD_DISTANCE := 0.25
const REWARD_WIN := 15
const REWARD_OBJETIVE := 10
#Penalizaciones
const PENALTY_LOSE:= -10
const PENALTY_PROGRESS := -0.2
const PENALTY_TIMEOUT := -2.5
#Punto de colision
var colision_point = 0.65
#IDs
const OBJECTIVE:= 1
const MYBASE:= 2
const RIVAL:= 3
const MATE:= 4
const TEAM_1:= "equipo1"
const TEAM_2:= "equipo2"
var team = null
func _ready():
	ai_controller_2d = $AIController2D
	sprite = $CharacterRobotIdle
	reward_count = $RewardCount
	collision_shape_2d = $CollisionShape2D
	vision = $Vision
	proximity = $proximity
	namelabel = $name
	namelabel.text = str(self.name)
	if myBase == base_red:
		myBaseSide = 0.0
		team =TEAM_1
		sprite.modulate = Color(1.0, 0.32, 0.32)
	else:
		myBaseSide = 1.0
		team =TEAM_2
		sprite.modulate = Color(0.0, 0.51, 1.0)
	add_to_group(team)
	originalPosition = collision_shape_2d.global_position
		
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
	if win or lose:
		for r in get_tree().get_nodes_in_group(team):
			if r != self :  
				r.add_reward(REWARD_WIN if win else 0.0)
		game_over()
	
# ---------------------------------------------------
# OBSERVACIONES
# ---------------------------------------------------
func _get_observations() -> Array:
	if observations.size() == 0:
		_update_observations() 
	return observations

func _update_observations():
	observations = []
	rival_contact = false
	distance_rival = 0.0
	observations.append(myBaseSide)
	observations.append(float(objectiveCatched))
	observations.append(float(objective.catched))
	# -----------------------------
	#  RAYCASTS
	# -----------------------------
	#Vision
	var distance := 0.0
	for ray in vision.get_children():
		var id = 0
		var distance_collide := 0.0
		if ray is RaycastSensor2D:
			# Rival detectado
			if not objective.catched:
				distance_collide = get_max_distance_with(ray,
					func(a): return a is objetivo)
				if distance_collide != 0.0:
					distance = distance_collide if distance_collide > distance else distance
					distance_objetive = distance if distance != 0.0 else distance_objetive
					id = OBJECTIVE
			elif objectiveCatched:
				distance_collide = get_max_distance_with(ray,func(a): return a == myBase)
				if distance_collide == 0.0:
					distance_collide = get_max_distance_with(ray,
						func(a): return (a is robot and a.myBase == myBase))
					if distance_collide != 0.0:
						distance = distance_collide if distance_collide > distance else distance
						distance_mate = distance  if distance != 0.0 else distance_mate
						id = MATE
				else:
					distance = distance_collide if distance_collide > distance else distance
					distance_base = distance if distance != 0.0 else distance_base
					id = MYBASE
			elif objective.catched and not objectiveCatched:
				distance_collide = get_max_distance_with(ray,
				func(a): return a is robot and a.myBase != myBase and a.objectiveCatched)
				if distance_collide != 0.0:
					distance = distance_collide if distance_collide > distance else distance
					distance_rival = distance if distance != 0.0 else distance_rival
					id = RIVAL
			observations.append(float(id))
			observations.append(distance_collide)
		
	#Proximidad
	var max_dist = 0.0
	for ray in proximity.rays:
		distance = 0.0
		ray.enabled = true
		ray.force_raycast_update()
		var collider = ray.get_collider()
		# Rival detectado
		if collider is robot: 
			distance = proximity._get_raycast_distance(ray)
			if collider.myBase != myBase:
				max_dist = distance if distance > max_dist else max_dist
				if distance > colision_point and (collider.objectiveCatched or objectiveCatched) :
					rival_contact = true
			elif distance > colision_point and objectiveCatched:
				pass_objective(collider)	
		ray.enabled = false
		observations.append(distance)
	distance_rival = max_dist if distance_rival == 0.0 else distance_rival
	
	
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
	# Delta de distancia a al compañero
	# -------------------------------
	if objectiveCatched and distance_mate > distance_base and distance_rival >= 0.3 :
		var delta_mate = distance_mate - last_distance_mate
		if abs(delta_mate) > threshold:
			var plus =  REWARD_DISTANCE  * 0.5 *  distance_mate
			# positivo si se acerca, negativo si se aleja
			delta_mate = 1.0 if delta_mate > 0.0 else -1.0
			reward_local += delta_mate * (REWARD_DISTANCE + plus)
			last_distance_mate = distance_mate	
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
		if objectiveCatched or (distance_rival > 0.3 and not objective.catched):
			var plus = REWARD_DISTANCE  * (1 - distance_rival) * 1.2
			reward_local -= delta_rival * (REWARD_DISTANCE + plus)
		# El rival tiene el objetivo: perseguir
		elif objective.catched and not objectiveCatched:
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
			lose = true
		elif objective.catched:
			reward_local += REWARD_WIN
			win = true
		
	add_reward(reward_local)

func add_reward(value):
	if ai_controller_2d!=null:
		ai_controller_2d.reward += value
	total_reward += value

func have_objetive():
	add_reward(REWARD_OBJETIVE)
	objectiveCatched = true
	ball.set_deferred("visible", true)

func end_episode_timeout():
	add_reward(PENALTY_TIMEOUT)
	
func game_over():
	emit_signal("sig_game_over")
	

# ---------------------------------------------------
# FUNCIONES AUXILIARES
# ---------------------------------------------------
func pass_objective(mate: robot):
	objectiveCatched = false
	mate.objectiveCatched = true
	ball.set_deferred("visible", false)
	mate.ball.set_deferred("visible", true)		
	
func update_label():
	reward_count.text = str("%.2f" % total_reward)
	reward_count.modulate = Color(1, 1, 1) if total_reward >= 0 else Color(1, 0.3, 0.3)

func get_max_distance_with(raycast: RaycastSensor2D,callback: Callable) -> float:
	var  near_distance = 0.0
	for ray in raycast.rays:
		var distance := 0.0
		ray.enabled = true
		ray.force_raycast_update()
		var collider = ray.get_collider()
		distance = raycast._get_raycast_distance(ray)
		if callback.call(collider):
			if distance > near_distance:
				near_distance = distance
		ray.enabled = false					
	return near_distance
# ---------------------------------------------------
# RESET
# ---------------------------------------------------
func reset():
	if ai_controller_2d!=null:
		ai_controller_2d.done = true
	objectiveCatched = false
	win = false
	lose = false
	rival_contact = false
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
	distance_mate = 0.0
	last_distance_mate = 0.0
	
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
	velocity = velocity.move_toward(desired_velocity, SPEED * 0.25)
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

	velocity = direction * SPEED * delta *10
	move_and_slide()


func _on_timer_timeout() -> void:
	print()
	print(name)
	print("DISTANCIA A OBJETIVO ",distance_objetive)
	print("DISTANCIA A BASE ",distance_base)
	print("DISTANCIA A RIVAL ", distance_rival)
	print(observations)
