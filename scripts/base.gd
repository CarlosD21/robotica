class_name base
extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_body_exited(body: Node2D) -> void:
	if body is robot && body.myBase == null :
		body.myBase=self
		body.ai_controller_2d.reward+=0.1
		print(body.name + " SALE")
		if body.position.x > self.position.x:
			body.myBaseSide = 0.0
		if body.position.x < self.position.x:
			body.myBaseSide = 1.0
		

func _on_body_entered(body: Node2D) -> void:
	if body is robot:
		if body.objetiveCatched == 1.0 && body.myBase == self:
			body.ai_controller_2d.reward+=0.1
			body.ai_controller_2d.done = true
			print(body.name + " GANA")
			body.win = true
		if body.objetiveCatched == 0.0 || body.myBase != self:
			body.ai_controller_2d.reward-=0.1
