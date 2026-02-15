extends CharacterBody2D

#STATE MACHINE SETUP
enum State { IDLE, MOVE, JUMP, ATTACK, COMBAT_IDLE, COMBAT_MOVE }
var current_state = State.IDLE
var state_just_changed = false

#MOVEMENT SETTINGS
const SPEED = 200.0
const SPRINT = 350.0
const JUMP_VELOCITY = 400.0
const WALL_GRAVITY = Vector2(0, 500)

#GAMEPLAY FLAGS
var is_combat_mode = false
var sprinting_before_jump = false
var was_on_floor = false
var is_attacking = false



func _ready() -> void:
	add_to_group("Player")



func _process(delta: float) -> void:
	pass



func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		$JumpBufferTimer.start()
	
	apply_gravity(delta)
	handle_coyote_time()
	
	#STATE MACHINE SWITCHER
	match current_state:
		State.IDLE:
			handle_idle_state(delta)
		State.MOVE:
			handle_move_state(delta)
		State.COMBAT_IDLE:
			handle_combat_idle_state(delta)
		State.COMBAT_MOVE:
			handle_combat_move_state(delta)
		State.JUMP:
			handle_jump_state(delta)
		State.ATTACK:
			handle_attack_state(delta)

	#APPLY MOVEMENT
	move_and_slide()



#STATE HANDLERS
func handle_idle_state(_delta: float):
	#slow down to a stop
	velocity.x = move_toward(velocity.x, 0, SPEED)
	
	#transitions
	if Input.get_axis("move_left", "move_right"):
		change_state(State.MOVE)
		
	if not $JumpBufferTimer.is_stopped():
		if is_on_floor() or not $CoyoteTimer.is_stopped():
			change_state(State.MOVE)
		
	if Input.is_action_just_pressed("attack") and is_combat_mode and not is_attacking:
		change_state(State.ATTACK)



func handle_move_state(delta: float):
	var direction = Input.get_axis("move_left", "move_right")
	
	if Input.is_action_pressed("down"):
		pass
	
	if direction == 0:
		change_state(State.IDLE)
		return
	
	if not $JumpBufferTimer.is_stopped():
		if is_on_floor() or not $CoyoteTimer.is_stopped():
			sprinting_before_jump = Input.is_action_just_pressed("sprint")
			change_state(State.JUMP)
	
	if Input.is_action_just_pressed("attack") and is_combat_mode and not is_attacking:
		change_state(State.ATTACK)
	
	var sprinting = Input.is_action_pressed("sprint")
	var target_speed = SPRINT if sprinting and (is_on_floor() or sprinting_before_jump) else SPEED
	
	if direction:
		velocity.x = direction * target_speed
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)



func handle_jump_state(delta: float):
	var direction = Input.get_axis("move_left", "move_right")
	
	var speed = SPRINT if sprinting_before_jump else SPEED
	velocity.x = direction * speed

	if state_just_changed:
		velocity.y = -JUMP_VELOCITY
		state_just_changed = false
		$JumpBufferTimer.stop()
	
	if is_on_floor():
		change_state(State.IDLE)



func handle_attack_state(_delta: float):
	#stops movement to give weight
	velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if state_just_changed:
		state_just_changed = false
		execute_attack_animation()

func execute_attack_animation():
	is_attacking = true
	#hitbox.monitoring = true
	#already_hit_targets.clear()
	
	#swing_audio.pitch_scale = randf_range(0.9, 1.1)
	#swing_audio.play()
	
	# Simple Procedural Animation (Rotating the weapon anchor)
	#var tween = create_tween()
	#tween.tween_property(weapon_anchor, "rotation:x", deg_to_rad(-90), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	#tween.tween_property(weapon_anchor, "rotation:x", deg_to_rad(0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	#tween.finished.connect(func(): 
		#is_attacking = false
		#hitbox.monitoring = false
		# Go back to IDLE once the sword is back in place
		#change_state(State.IDLE)
	#)



func handle_combat_idle_state(delta: float):
	if Input.get_axis("move_left", "move_right") != 0:
		change_state(State.COMBAT_MOVE)
	
	if not $JumpBufferTimer.is_stopped():
		if is_on_floor() or not $CoyoteTimer.is_stopped():
			change_state(State.JUMP)
	
	if Input.is_action_just_pressed("attack") and is_combat_mode:
		change_state(State.ATTACK)



func handle_combat_move_state(delta: float):
	var direction = Input.get_axis("move_left", "move_right")
	
	velocity.x = direction * SPEED
	
	if direction == 0:
		change_state(State.COMBAT_IDLE)
		
	if not $JumpBufferTimer.is_stopped():
		if is_on_floor() or not $CoyoteTimer.is_stopped():
			change_state(State.JUMP)
	
	if Input.is_action_just_pressed("attack") and is_combat_mode:
		change_state(State.ATTACK)



func apply_gravity(delta):
	if not is_on_floor():
		# Wall Slide Gravity (Slower fall)
		if is_on_wall_only() and velocity.y < 0:
			velocity += WALL_GRAVITY * delta
		else:
			velocity += get_gravity() * delta

func change_state(new_state: State):
	current_state = new_state
	state_just_changed = true

func handle_coyote_time():
	if was_on_floor and not is_on_floor() and velocity.y <= 0:
		$CoyoteTimer.start()
