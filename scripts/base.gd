extends Area2D
class_name base

func _on_body_exited(body: Node2D) -> void:
	if body is robot and body.myBase == null:
		body.set_deferred("myBase", self)
		body.ai_controller_2d.reward += 0.5

		if body.position.x > self.position.x:
			body.set_deferred("myBaseSide", 0.0)
			body.sprite.set_deferred("modulate", Color(1.0, 0.329, 0.322, 0.98))
		else:
			body.set_deferred("myBaseSide", 1.0)
			body.sprite.set_deferred("modulate", Color(0.0, 0.514, 1.0, 1.0))

func _on_body_entered(body: Node2D) -> void:
	if body is robot:
		if body.objetiveCatched == 1.0 and body.myBase == self:
			body.add_reward(10.0)  # llegar con objetivo a casa = victoria
			body.ai_controller_2d.set_deferred("done", true)
			body.set_deferred("win", true)
		elif body.objetiveCatched == 0.0 or body.myBase != self:
			body.add_reward(-0.5)   # vuelve sin objetivo = penalización
