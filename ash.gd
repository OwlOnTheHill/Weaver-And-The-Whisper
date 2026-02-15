extends CharacterBody2D

#STATE MACHINE SETUP
enum State { IDLE, MOVE, JUMP, ATTACK, COMBAT_IDLE, COMBAT_MOVE }

#MOVEMENT SETTINGS
const SPEED = 4.5
const SPRINT = 10.0
const JUMP_VELOCITY = 5.5
const WALL_GRAVITY = Vector2(0, -5.5, 0)

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
	apply_gravity(delta)
	handle_coyote_time()
	
