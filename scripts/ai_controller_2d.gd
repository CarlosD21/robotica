extends AIController2D
var move = Vector2.ZERO
var new_action: bool = false

func get_obs() -> Dictionary:
	return {"obs": get_parent()._get_observations()}

func get_reward() -> float:
	var r = reward
	return r

func get_action_space() -> Dictionary:
	return {
		"move": {
			"size": 2,
			"action_type": "continuous"
		}
	}

func set_action(action) -> void:
	move.x = action["move"][0]
	move.y = action["move"][1]
	new_action = true
