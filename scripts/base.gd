extends Area2D
class_name base

func _on_body_exited(body):
	if body is robot and body.myBase == null:
		body.set_deferred("myBase", self)
		body.add_reward(0.5)

		if body.position.x > position.x:
			body.myBaseSide = 0.0
			body.sprite.modulate = Color(1.0, 0.32, 0.32)
		else:
			body.myBaseSide = 1.0
			body.sprite.modulate = Color(0.0, 0.51, 1.0)

func _on_body_entered(body):
	if body is robot:
		if body.objetiveCatched == 1.0 and body.myBase == self:
			body.add_reward(3.0)
			body.ai_controller_2d.done = true
			body.win = true
		elif body.objetiveCatched == 0.0:
			body.add_reward(-0.3)
