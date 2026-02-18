extends Camera2D

#settings
const LOOK_AHEAD_DIST = 40.0
const SHIFT_SPEED = 2.0

func _physics_process(delta: float) -> void:
	var target_offset = Vector2.ZERO
	var player = get_parent()
	
	#check if player is moving
	if abs(player.velocity.x) > 10.0:
		#set target to left or right based on direction
		target_offset.x = sign(player.velocity.x) * LOOK_AHEAD_DIST
	
	#smoothing
	offset = offset.lerp(target_offset, SHIFT_SPEED * delta)
