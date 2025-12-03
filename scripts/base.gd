extends Area2D
class_name base

func _on_body_exited(body):
	if body is robot:	
		if body.myBase == null:
			body.myBase = self
			if body.myBase.get_node("CollisionShape2D").shape is RectangleShape2D:
				body.base_half_width = body.myBase.get_node("CollisionShape2D").shape.extents.x * body.myBase.global_scale.x
			if body.position.x > position.x:
				body.myBaseSide = 0.0
				body.sprite.modulate = Color(1.0, 0.32, 0.32)
			else:
				body.myBaseSide = 1.0
				body.sprite.modulate = Color(0.0, 0.51, 1.0)
		
func _on_body_entered(body):
	if body is robot:
		if body.objectiveCatched and body.myBase == self:
			body.win = true
		
		#elif body.objetiveCatched == 0.0 or body.myBase != self:
			#body.add_reward(-0.3)
