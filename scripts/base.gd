class_name base
extends Area2D


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass


func _on_body_exited(body: Node2D) -> void:
	if body is robot and body.myBase == null:
		# Asignamos la base de forma diferida por seguridad
		body.set_deferred("myBase", self)
		body.ai_controller_2d.reward += 0.5

		# Determinar lado y color
		if body.position.x > self.position.x:
			body.set_deferred("myBaseSide", 0.0)
			body.sprite.set_deferred("modulate", Color(1.0, 0.251, 0.267, 1.0))  # rojo
		else:
			body.set_deferred("myBaseSide", 1.0)
			body.sprite.set_deferred("modulate", Color(0.0, 0.514, 1.0, 1.0))  # azul

		#print(body.name + " SALE DE BASE  " + str(body.myBaseSide))


func _on_body_entered(body: Node2D) -> void:
	if body is robot:
		if body.objetiveCatched == 1.0 and body.myBase == self:
			body.ai_controller_2d.reward += 1.0
			# Estos cambios se hacen de forma diferida
			body.ai_controller_2d.set_deferred("done", true)
			body.set_deferred("win", true)
			#print(body.name + " GANA")
		elif body.objetiveCatched == 0.0 or body.myBase != self:
			body.ai_controller_2d.reward -= 0.25
