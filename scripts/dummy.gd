extends robot
class_name dummy

# ---------------------------------------------------------
# COMPORTAMIENTOS PREFIJADOS
# ---------------------------------------------------------
enum BehaviorType {
	GO_OBJECTIVE_RETURN_BASE,          # 0 → Va al objetivo, lo captura y vuelve a base
	CHASE_ENEMY_IF_HAS_OBJECTIVE,      # 1 → Persigue al enemigo si tiene el objetivo (con ruta no recta)
	MOVE_UP_DOWN                       # 2 → Se mueve arriba y abajo
}

# ---------------------------------------------------------
# VARIABLES CONFIGURABLES DESDE EL INSPECTOR
# ---------------------------------------------------------
@export var behavior: BehaviorType = BehaviorType.MOVE_UP_DOWN
@export var speed := 250.0

@export var haveObjective: bool
@export var rival_robot: Node2D

# Límites verticales para movimiento arriba/abajo
@export var min_y := 100.0
@export var max_y := 550.0
@export var pos_x := 600.0
# ---------------------------------------------------------
# VARIABLES INTERNAS
# ---------------------------------------------------------
var up_down_direction := 1
var random_offset := Vector2.ZERO
@onready var character_round_yellow: Sprite2D = $CharacterRoundYellow


# ---------------------------------------------------------
# READY
# ---------------------------------------------------------
func _ready():
	originalPosition = collision_shape_2d.global_position
	sprite = character_round_yellow
	myBase = base
	if myBase.get_node("CollisionShape2D").shape is RectangleShape2D:
		if position.x > myBase.position.x:
			myBaseSide = 0.0
			#character_round_yellow.modulate = Color(1.0, 0.32, 0.32)
		else:
			myBaseSide = 1.0
			#character_round_yellow.modulate = Color(0.0, 0.51, 1.0)
	
	random_offset = Vector2(
		randf_range(-150, 150),
		randf_range(-150, 150)
	)

# ---------------------------------------------------------
# PHYSICS PROCESS
# ---------------------------------------------------------
func _physics_process(delta):
	if win:
		game_over()
	if haveObjective:
		have_objetive()
		objective.catch()
	if myBase.get_node("CollisionShape2D").shape is RectangleShape2D:
		if position.x > myBase.position.x:
			myBaseSide = 0.0
			character_round_yellow.modulate = Color(1.0, 0.32, 0.32)
		else:
			myBaseSide = 1.0
			character_round_yellow.modulate = Color(0.0, 0.51, 1.0)
	match behavior:

		BehaviorType.GO_OBJECTIVE_RETURN_BASE:
			run_go_objective_return_base(delta)

		BehaviorType.CHASE_ENEMY_IF_HAS_OBJECTIVE:
			run_chase_enemy(delta)

		BehaviorType.MOVE_UP_DOWN:
			position.x = pos_x
			run_up_down(delta)


# ---------------------------------------------------------
# 1. IR AL OBJETIVO → CAPTURAR → VOLVER A BASE
# ---------------------------------------------------------
func run_go_objective_return_base(delta):
	if objective == null or myBase == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var target := objective.position

	# Si el objetivo ya fue capturado → volver a base
	if objectiveCatched:
		target = myBase.position
	
	if objective.catched and not objectiveCatched:
		target = rival_robot.position
		
	var dir := (target - position).normalized()
	velocity = dir * speed

	move_and_slide()


# ---------------------------------------------------------
# 2. PERSEGUIR AL ENEMIGO SI TIENE EL OBJETIVO
#    (con movimiento NO recto, más natural)
# ---------------------------------------------------------
func run_chase_enemy(delta):
	if rival_robot == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Solo perseguir si el enemigo tiene el objetivo
	if rival_robot.objetiveCatched:
		# Movimiento no recto → se añade un offset que rota
		var time_rot := Time.get_ticks_msec() / 1000.0
		var target := rival_robot.position + random_offset.rotated(time_rot)

		var dir := (target - position).normalized()
		velocity = dir * speed

		move_and_slide()

	else:
		# Si no lo tiene → quedarse quieto
		velocity = Vector2.ZERO
		move_and_slide()


# ---------------------------------------------------------
# 3. MOVIMIENTO VERTICAL ARRIBA / ABAJO
# ---------------------------------------------------------
func run_up_down(delta):
	if position.y < min_y:
		up_down_direction = 1
	elif position.y > max_y:
		up_down_direction = -1

	velocity = Vector2(0, up_down_direction * speed * 0.9)
	move_and_slide()

# ---------------------------------------------------------
# FUNCIONES AUXILIARES
# ---------------------------------------------------------
func have_objetive():
	objectiveCatched = true
	ball.set_deferred("visible", true)
