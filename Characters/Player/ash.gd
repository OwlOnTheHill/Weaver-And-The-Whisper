extends CharacterBody2D

#STATE MACHINE SETUP
enum State { IDLE, MOVE, JUMP, FALL, ATTACK, COMBAT_IDLE, COMBAT_MOVE, DASH }
var current_state = State.IDLE
var state_just_changed = false

#MOVEMENT SETTINGS
const SPEED = 200.0
const DASH_SPEED = 500.0 
const DASH_DURATION = 0.2
const JUMP_VELOCITY = 300.0

# Wall Gravity (Slower fall for sliding)
const WALL_GRAVITY = Vector2(0, 500)

# Variable Gravity Settings
var fall_gravity_multiplier = 1.0
const MAX_GRAVITY_MULTIPLIER = 1.5 
const GRAVITY_RAMP_SPEED = 1.5 

# ABILITY UNLOCKS
var double_jump_unlocked = false 
var dash_unlocked = false # DASH IS NOW LOCKED BY DEFAULT
var current_jumps = 0
const MAX_JUMPS = 2

#GAMEPLAY FLAGS
var is_combat_mode = false
var was_on_floor = false
var is_attacking = false
var can_dash = true # Runtime flag (can I dash *right now*?)
var dash_direction = 0
var dash_time_left = 0.0

func _ready() -> void:
	add_to_group("Player")

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		$JumpBufferTimer.start()
	
	# Apply gravity only if NOT dashing
	if current_state != State.DASH:
		apply_gravity(delta)
	else:
		fall_gravity_multiplier = 1.0
	
	handle_coyote_time()
	
	# Reset abilities on floor
	if is_on_floor():
		can_dash = true
		current_jumps = 0
		fall_gravity_multiplier = 1.0 
	
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
		State.FALL:
			handle_fall_state(delta)
		State.ATTACK:
			handle_attack_state(delta)
		State.DASH:
			handle_dash_state(delta)

	#APPLY MOVEMENT
	move_and_slide()
	
	was_on_floor = is_on_floor()

#STATE HANDLERS
func handle_idle_state(_delta: float):
	velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if not is_on_floor():
		change_state(State.FALL)
		return

	if Input.get_axis("move_left", "move_right"):
		change_state(State.MOVE)
		
	if not $JumpBufferTimer.is_stopped():
		change_state(State.JUMP)
	
	if Input.is_action_just_pressed("attack") and is_combat_mode and not is_attacking:
		change_state(State.ATTACK)
	
	try_dash()

func handle_move_state(delta: float):
	var direction = Input.get_axis("move_left", "move_right")
	
	if not is_on_floor():
		change_state(State.FALL)
		return
	
	if direction == 0:
		change_state(State.IDLE)
		return
	
	if not $JumpBufferTimer.is_stopped():
		change_state(State.JUMP)
	
	if Input.is_action_just_pressed("attack") and is_combat_mode and not is_attacking:
		change_state(State.ATTACK)
		
	try_dash()
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

func handle_jump_state(delta: float):
	var direction = Input.get_axis("move_left", "move_right")
	velocity.x = direction * SPEED

	if state_just_changed:
		velocity.y = -JUMP_VELOCITY
		current_jumps += 1
		fall_gravity_multiplier = 1.0 
		state_just_changed = false
		$JumpBufferTimer.stop()
	
	if velocity.y > 0:
		change_state(State.FALL)
		
	if is_on_floor():
		change_state(State.IDLE)
	
	check_double_jump()
	try_dash()

func handle_fall_state(delta):
	var direction = Input.get_axis("move_left", "move_right")
	velocity.x = direction * SPEED
	
	if is_on_floor():
		change_state(State.IDLE)
		
	if not $JumpBufferTimer.is_stopped():
		if is_on_floor() or not $CoyoteTimer.is_stopped():
			change_state(State.JUMP)
	
	check_double_jump()
	try_dash()
	
	if Input.is_action_just_pressed("attack") and is_combat_mode:
		change_state(State.ATTACK)

func check_double_jump():
	if Input.is_action_just_pressed("jump") and double_jump_unlocked:
		if current_jumps < MAX_JUMPS:
			change_state(State.JUMP)

func handle_dash_state(delta: float):
	if state_just_changed:
		state_just_changed = false
		dash_time_left = DASH_DURATION
		$DashTimer.start()
		can_dash = false 
		
		var input_dir = Input.get_axis("move_left", "move_right")
		if input_dir != 0:
			dash_direction = input_dir
		else:
			dash_direction = sign(velocity.x) if velocity.x != 0 else 1
	
	velocity.x = dash_direction * DASH_SPEED
	velocity.y = 0 
	
	dash_time_left -= delta
	
	if dash_time_left <= 0:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if is_on_floor():
			change_state(State.IDLE)
		else:
			change_state(State.FALL)

func handle_attack_state(_delta: float):
	velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if state_just_changed:
		state_just_changed = false
		execute_attack_animation()

func execute_attack_animation():
	is_attacking = true
	pass

func handle_combat_idle_state(delta: float):
	if Input.get_axis("move_left", "move_right") != 0:
		change_state(State.COMBAT_MOVE)
	
	if not $JumpBufferTimer.is_stopped():
		if is_on_floor() or not $CoyoteTimer.is_stopped():
			change_state(State.JUMP)
	
	if Input.is_action_just_pressed("attack") and is_combat_mode:
		change_state(State.ATTACK)
		
	try_dash()

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

	try_dash()

func try_dash():
	# 1. Input Check
	# 2. Ability Unlocked Check (dash_unlocked)
	# 3. Runtime Check (can_dash, cooldown)
	# 4. Direction Check
	if Input.is_action_just_pressed("dash") and dash_unlocked and can_dash and $DashTimer.is_stopped():
		if Input.get_axis("move_left", "move_right") != 0:
			change_state(State.DASH)

func apply_gravity(delta):
	if not is_on_floor():
		if is_on_wall_only() and velocity.y > 0:
			velocity += WALL_GRAVITY * delta
			fall_gravity_multiplier = 1.0 
		else:
			if velocity.y > 0: 
				fall_gravity_multiplier = move_toward(fall_gravity_multiplier, MAX_GRAVITY_MULTIPLIER, GRAVITY_RAMP_SPEED * delta)
			else:
				fall_gravity_multiplier = 1.0
			
			velocity += get_gravity() * fall_gravity_multiplier * delta

func change_state(new_state: State):
	current_state = new_state
	state_just_changed = true

func handle_coyote_time():
	if was_on_floor and not is_on_floor() and velocity.y >= 0:
		$CoyoteTimer.start()
