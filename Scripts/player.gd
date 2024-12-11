class_name Player
extends CharacterBody2D

@onready var label = $Label
@onready var input = Vector2.ZERO
var direction = 0
var was_on_floor: bool = true   # to detect if player just slide out of floor at the and of move and slide.

## MOVEMENT SECTION

#setup Variables
@export var MAX_SPEED: int = 150
@export var acceleration: float = 20
@export var friction: float = 0.1

## JUMP SECTION:
@export var max_jump: int = 2
var jump_count : int = max_jump
var jump_pressed: bool = false

# variable jump
# min jump
@onready var min_jump_timer = $Timer/MinJumpTimer

# jump buffer
@onready var jump_buffer_timer: Timer = $Timer/JumpBufferTimer
var buffered_jump_enabled: bool = false

# coyote jump buffer
@onready var coyote_jump_timer = $Timer/CoyoteJumpTimer
var coyote_jump_enabled: bool = false

## WALL:
var wall_direction: int = 0  # 1 for right wall, -1 for left wall
var was_on_wall: bool = false
@onready var wall_detect_1 = $WallDetect/WallDetect1
@onready var wall_detect_2 = $WallDetect/WallDetect2

@export var WALL_SLIDE_SPEED: float = 80
@export var WALL_JUMP_VELOCITY_X: float = 80
@export var WALL_JUMP_VELOCITY_Y: float = -260

# setup Veriables
@export var jump_height: float = 40
@export var jump_time_to_peak: float = 0.3
@export var jump_time_to_decent: float = 0.3

# jump Calculation
@onready var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak ) * -1
@onready var jump_gravity: float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1
@onready var fall_gravity: float = ((-2.0 * jump_height) / (jump_time_to_decent * jump_time_to_decent)) * -1 



enum States  {IDLE, RUN, JUMP, FALL, WALL_SLIDE, WALL_CLIMB}

var state = States.IDLE


func _physics_process(delta):
	match state:
		States.IDLE:
			label.text = "IDEL"
			idel()
		States.RUN:
			label.text = "RUN"
			run()
		States.JUMP:
			label.text = "JUMP"
			jump()
		States.FALL:
			label.text = "FALL"
			fall()
		States.WALL_SLIDE:
			label.text = "WALL_SLIDE"
			wall_slide()
		States.WALL_CLIMB:
			label.text = "WALL_CLIMB"
			wall_climb()
	
	apply_gravity(delta)
	default_checks()
	player_input()
	
	move_and_slide()



## HELPER FUNCTIONS:
func change_state(newState: States) -> void:
	state = newState

func player_input():
	input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input.x != 0:
		direction = input.x

func default_checks():
	was_on_floor = true if is_on_floor() else false
	was_on_wall = true if (wall_detect_1.is_colliding() or wall_detect_2.is_colliding()) else false
	
	#if not is_on_floor() or (is_on_floor() and input.y != 0):
	#check_wall_contact()


## =========== STATES =============
## IDEL
func idel():
	velocity.x = move_toward(velocity.x, 0, friction)
	
	if is_on_floor():
		jump_count = max_jump
	
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
		change_state(States.RUN)
	if Input.is_action_just_pressed("jump") or (buffered_jump_enabled and is_on_floor()):
		change_state(States.JUMP)
	if wall_detect_1.is_colliding() or wall_detect_2.is_colliding():
		change_state(States.WALL_SLIDE)

## RUN
func run():
	velocity.x = move_toward(velocity.x, MAX_SPEED * input.x, acceleration)
	
	if is_on_floor():
		jump_count = max_jump
	
	if was_on_floor and not is_on_floor() and velocity.y > 0:
		coyote_jump_enabled = true
		coyote_jump_timer.start()
		## print('FALL')
	
	if velocity.x == 0:
		change_state(States.IDLE)
	#if velocity.y > 0 and not is_on_floor():
		#change_state(States.FALL)
	if Input.is_action_just_pressed("jump") or (buffered_jump_enabled and is_on_floor()):
		change_state(States.JUMP)
	if wall_detect_1.is_colliding() or wall_detect_2.is_colliding():
		change_state(States.WALL_SLIDE)

## JUMP
func can_jump():
	## jump if player is on floor or coyote jump is on going or
	## have already performed atleast 1 jump 
	if is_on_floor() or coyote_jump_enabled or (jump_count < max_jump and jump_count > 0):
		return true
	return false
	
func jump():
	if can_jump():
		min_jump_timer.start()
		jump_count -= 1
		velocity.y = jump_velocity
		## if (coyote_jump_enabled): print('COYOTE JUMP')
	
	else:
		if not buffered_jump_enabled:
			buffered_jump_enabled = true
			jump_buffer_timer.start()
	
	if velocity.x == 0:
		change_state(States.IDLE)
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
		change_state(States.RUN)
	if wall_detect_1.is_colliding() or wall_detect_2.is_colliding():
		change_state(States.WALL_SLIDE)
	
	# Always check for fall state when in jump state
	if velocity.y >= 0 or (not is_on_floor() and not is_on_wall()):
		change_state(States.FALL)

## FALL
func fall():
	if is_on_floor():
		change_state(States.IDLE)
	if Input.is_action_just_pressed("jump") or (buffered_jump_enabled and is_on_floor()):
		change_state(States.JUMP)
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
		change_state(States.RUN)
	if wall_detect_1.is_colliding() or wall_detect_2.is_colliding():
		change_state(States.WALL_SLIDE)

## WALL
func wall_slide():
	# Slow down vertical movement
	velocity.y = min(velocity.y, WALL_SLIDE_SPEED)
	
	if was_on_wall and (!wall_detect_1.is_colliding() or !wall_detect_2.is_colliding()):
		print('JABBAAAAA SLIDE')
		change_state(States.FALL)
	
	# Wall climb up or down
	if input.y != 0:
		change_state(States.WALL_CLIMB)
	
	# Wall jump conditions
	if Input.is_action_just_pressed("jump"):
		if not is_on_floor():
			wall_jump()
		else: 
			change_state(States.JUMP)
	
	if input.y == 0 and (Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right")):
		change_state(States.RUN)

## WALL CLIMB
func wall_climb():
	# Slow vertical movement while climbing
	velocity.y = input.y * (WALL_SLIDE_SPEED * 0.5)
	
	if was_on_wall and (!wall_detect_1.is_colliding() or !wall_detect_2.is_colliding()):
		print('JABBAAAAA CLIMB')
		change_state(States.FALL)
	
	# Return to wall slide if no input
	if input.y == 0:
		change_state(States.WALL_SLIDE)
	
	# Wall jump conditions
	if Input.is_action_just_pressed("jump"):
		if not is_on_floor():
			wall_jump()
		else: 
			change_state(States.JUMP)
	
	if velocity.y > 0 and !Input.is_action_pressed("ui_down"):
		change_state(States.WALL_SLIDE)

## WALL MECHANICS
func check_wall_contact():
	## Always check for wall state validity
	#if state in [States.WALL_SLIDE, States.WALL_CLIMB]:
		#if !is_on_wall():
			#change_state(States.FALL)
			#return
	
	#if state not in [States.WALL_SLIDE, States.WALL_CLIMB]:
		if is_on_wall():
			## Detect which wall we're touching
			if test_move(transform, Vector2(1, 0)):
				wall_direction = 1  # Right wall
			elif test_move(transform, Vector2(-1, 0)):
				wall_direction = -1  # Left wall
			
			## Change to wall slide state
			if velocity.y > 0:
				change_state(States.WALL_SLIDE)
		else:
			wall_direction = 0
			#if not is_on_floor():
				#change_state(States.FALL)


func wall_jump():
	if test_move(transform, Vector2(1, 0)):
		wall_direction = 1  # Right wall
	elif test_move(transform, Vector2(-1, 0)):
		wall_direction = -1  # Left wall
	else:
		wall_direction = 0
	
	# Reset jump count
	jump_count = max_jump - 1
	
	# Wall jump based on wall direction
	if wall_direction == 1:  # Right wall
		velocity.x = -WALL_JUMP_VELOCITY_X
	elif wall_direction == -1:  # Left wall
		velocity.x = WALL_JUMP_VELOCITY_X
	
	# Vertical jump velocity
	velocity.y = WALL_JUMP_VELOCITY_Y
	
	# Return to fall state
	change_state(States.FALL)


func get_gravity() -> float:
	if state in [States.WALL_SLIDE, States.WALL_CLIMB]:
		return jump_gravity * 0.5
	
	return jump_gravity if velocity.y < 0.0 else fall_gravity

func apply_gravity(delta):
	velocity.y += get_gravity() * delta


## Timer function =================

func _on_jump_buffer_timer_timeout():
	buffered_jump_enabled = false

func _on_coyote_jump_timer_timeout():
	coyote_jump_enabled = false

func _on_min_jump_timer_timeout():
	## check if player has released jump button early
	if !Input.is_action_pressed("jump"):
		if velocity.y < -10:
			velocity.y = -10
