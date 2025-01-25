class_name Player
extends CharacterBody2D
@onready var label = $Label
@onready var input = Vector2.ZERO
@onready var pap: AnimationPlayer = $AnimationPlayer

@onready var sprite: Sprite2D = $Sprite2D

var direction = 0
var was_on_floor: bool = true   # to detect if player just slide out of floor at the and of move and slide.

## MOVEMENT SECTION

#setup Variables
#@export var MAX_SPEED: int = 150 # without delta, used when move_and_slide in physics process
@export var MAX_SPEED: int = 140
#@export var acceleration: float = 20 # without delta, , used when move_and_slide in physics process
@export var acceleration: float = 800
#@export var friction: float = 30 # without delta, , used when move_and_slide in physics process
@export var friction: float = 1400

## JUMP SECTION:
@export var max_jump: int = 2
var jump_count : int = max_jump
var jump_pressed: bool = false
@onready var jumpped = false

# variable jump
# min jump
@onready var min_jump_timer = $Timer/MinJumpTimer

# jump buffer
@onready var jump_buffer_timer: Timer = $Timer/JumpBufferTimer
var buffered_jump_enabled: bool = false # this is to keep track of jump_buffer_timer

# NOTE: right now, if player can't jump and even once presses jump,
# player will remain in jump state and will play else condition that will keep running buffer timer.
# but buffer timer should only run once, until player presses jump again.
var jump_buffer_checked: bool = false # if once jump_buffer_timer is finished then no need to enable it again if the player is in 


# coyote jump buffer
@onready var coyote_jump_timer = $Timer/CoyoteJumpTimer
var coyote_jump_enabled: bool = false

## WALL:
var wall_direction: Vector2 = Vector2.ZERO  # 1 for right wall, -1 for left wall
var was_on_wall: bool = false
@onready var wall_detect_ray_1 = $WallDetect/WallDetect1
@onready var wall_detect_ray_2 = $WallDetect/WallDetect2


@export var WALL_SLIDE_SPEED: float = 200
@export var WALL_JUMP_VELOCITY_X: float = 80
@export var WALL_JUMP_VELOCITY_Y: float = -260

# setup Veriables
@export var jump_height: float = 50
@export var jump_time_to_peak: float = 0.4
@export var jump_time_to_decent: float = 0.3

# jump Calculation
@onready var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak ) * -1
@onready var jump_gravity: float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1
@onready var fall_gravity: float = ((-2.0 * jump_height) / (jump_time_to_decent * jump_time_to_decent)) * -1 



enum States  {IDLE, RUN, JUMP, FALL, WALL_SLIDE, WALL_CLIMB}

var state = States.IDLE

func _process(delta):
	match state:
		States.IDLE:
			label.text = "IDLE"
			idel(delta)
			sprite.flip_v = false
			pap.play("idle")
		States.RUN:
			label.text = "RUN"
			run(delta)
			sprite.flip_v = false
			pap.play("walk")
		States.JUMP:
			label.text = "JUMP"
			jump(delta)
			sprite.flip_v = false
			pap.play("jump")
		States.FALL:
			label.text = "FALL"
			fall(delta)
			sprite.flip_v = false
			pap.play("fall")
		States.WALL_SLIDE:
			label.text = "WALL_SLIDE"
			wall_slide(delta)
		States.WALL_CLIMB:
			label.text = "WALL_CLIMB"
			wall_climb(delta)
			sprite.flip_v = false
	
	#player_input()
	default_checks()
	move_and_slide()
#var jumppoints = []
func _physics_process(delta):
	#if !is_on_floor():
		#jumppoints.append(global_position)
	apply_gravity(delta)
	player_input()
	#default_checks()
	#move_and_slide()

#func _notification(what):
	#if what == NOTIFICATION_WM_CLOSE_REQUEST:
		#print(jumppoints)
		#get_tree().quit()

## HELPER FUNCTIONS:
func change_state(newState: States) -> void:
	#print("old:", state)
	state = newState
	
	match state:
		States.IDLE:
			sprite.flip_v = false
			pap.play("idle")
		States.RUN:
			sprite.flip_v = false
			pap.play("walk")
		States.JUMP:
			sprite.flip_v = false
			pap.play("jump")
		States.FALL:
			sprite.flip_v = false
			pap.play("fall")
		States.WALL_SLIDE:
			pass
		States.WALL_CLIMB:
			sprite.flip_v = false
	
	#print("new:",state)
	

func player_input():
	input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input.x != 0:
		direction = input.x

func default_checks():
	was_on_floor = true if is_on_floor() else false
	was_on_wall = $WallCheck.is_colliding()
	#wall_direction = $WallCheck.get_collision_normal(0)
	#print(wall_direction)
	#if not is_on_floor() or (is_on_floor() and input.y != 0):
	#check_wall_contact()


## =========== STATES =============
## IDEL
func idel(delta):
	
	velocity.x = move_toward(velocity.x, 0, friction)
	
	if is_on_floor():
		jump_count = max_jump
		jumpped = false
	
	#if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
	if input.x != 0:
		change_state(States.RUN)
	if Input.is_action_just_pressed("jump") or (buffered_jump_enabled and is_on_floor()):
		change_state(States.JUMP)
	if $WallCheck.is_colliding() and input.y < 0:
		#if input.y != 0: 
		change_state(States.WALL_SLIDE)

## RUN
func run(delta):
	#pap.play("walk")
	if input.x > 0:
		sprite.flip_h = false
	else:
		sprite.flip_h = true
	velocity.x = move_toward(velocity.x, MAX_SPEED * input.x, acceleration)
	
	if is_on_floor():
		jump_count = max_jump
		jumpped = false
	
	if was_on_floor and not is_on_floor() and velocity.y > 0:
		coyote_jump_enabled = true
		coyote_jump_timer.start()
		## print('FALL')
	
	if input.x == 0:
		change_state(States.IDLE)
	if velocity.y > 0 and not is_on_floor() and not coyote_jump_enabled:
		jump_count = max_jump-1
		change_state(States.FALL)
	if Input.is_action_just_pressed("jump") or (buffered_jump_enabled and is_on_floor()):
		change_state(States.JUMP)
	if input.y != 0 and $WallCheck.is_colliding():
		#if input.y != 0: 
		change_state(States.WALL_SLIDE)

## JUMP
func can_jump():
	## jump if player is on floor or coyote jump is on going or
	## have already performed atleast 1 jump 
	if is_on_floor() or coyote_jump_enabled or (jump_count > 0 and jump_count < max_jump):
		return true
	return false
	
func jump(delta):
	#pap.play("jump")
	if !jumpped and can_jump():
		#print(coyote_jump_enabled)
		min_jump_timer.start()
		jumpped = true
		jump_count -= 1
		velocity.y = jump_velocity 
		#print('aldkfjlkjlkj')
		#print(jump_count)
		## if (coyote_jump_enabled): print('COYOTE JUMP')
	
	else:
		print(jump_count)
		if (not buffered_jump_enabled and not is_on_floor() and jump_count > 0 and not jump_buffer_checked):
			#print('JUMP BUFFER ENABLED')
			buffered_jump_enabled = true
			jump_buffer_checked = true
			jump_buffer_timer.start()
		if (is_on_floor()):
			#print('first jump')
			change_state(States.IDLE)
		
	#if (is_on_floor() and jump_count == max_jump) or (not is_on_floor() and was_on_floor):
	if can_jump():
		if Input.is_action_just_pressed("jump"):
			#print('AGAIN PRESSED JUMP.......')
			jumpped = false
			change_state(States.JUMP)
		elif velocity.y >= 0 and (not is_on_floor() and not coyote_jump_enabled) and (!any_wall_detect()):
			#print('chaning to fall')
			change_state(States.FALL)
	
	if velocity.y >= 0 and (not is_on_floor() and not coyote_jump_enabled) and (!any_wall_detect()):
		#print('chaning to fall')
		change_state(States.FALL)
	
	
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
		velocity.x = move_toward(velocity.x, MAX_SPEED * input.x, acceleration)
	else:
		print('sssssssssssss')
		if input.x == 0:
			velocity.x = move_toward(velocity.x, 0, 10)
	
	if not is_on_floor() and $WallCheck.is_colliding():
		#if input.y != 0:
			#change_state(States.WALL_CLIMB)
		#else:
			change_state(States.WALL_SLIDE)
	
	# Always check for fall state when in jump state
	#if velocity.y >= 0 and (not is_on_floor() and (!any_wall_detect()):
		#change_state(States.FALL)

## FALL
func fall(delta):
	#pap.play("fall")
	#if Input.is_action_just_pressed("jump") && jump_count>0:
		#change_state(States.JUMP)
		
	if is_on_floor():
		change_state(States.IDLE)
	if Input.is_action_just_pressed("jump") or (buffered_jump_enabled and is_on_floor()):
		if jumpped: jumpped = false
		if not jump_buffer_checked: jump_buffer_checked = false
		change_state(States.JUMP)
	if input.x != 0:
		velocity.x = move_toward(velocity.x, MAX_SPEED * input.x, acceleration)
	else:
		print('sssssssssssss')
		if input.x == 0:
			velocity.x = move_toward(velocity.x, 0, 10)
	if not is_on_floor() and $WallCheck.is_colliding():
		#if input.y != 0:
			#change_state(States.WALL_CLIMB)
		#else:
			change_state(States.WALL_SLIDE)

## WALL
func wall_slide(delta):
	$WallCheck.force_shapecast_update()
	if $WallCheck.is_colliding():
		sprite.flip_h = false if $WallCheck.get_collision_normal(0).x == -1 else true

	
	if not $WallCheck.is_colliding():
		change_state(States.FALL)
	
	if input.y == 0:
		velocity.y = min(velocity.y, WALL_SLIDE_SPEED)
		if is_on_floor():
			change_state(States.IDLE)
		else:
			sprite.flip_v = false
	else:
		velocity.y = input.y * (WALL_SLIDE_SPEED * 0.5)
		if is_on_floor():
			change_state(States.IDLE)
	
	#if was_on_wall and not is_on_floor() and (!any_wall_detect()):
	if !$WallCheck.is_colliding() and not is_on_floor():
		if input.y == 1 or input.y == 0:
			#print('JABBAAAAA SLIDE')
			change_state(States.FALL)
		
		# if wall is not colliding and player is pressing up arrow means, player is at the top of wall
		elif input.y == -1:  
			sprite.flip_v = false
			change_state(States.WALL_CLIMB)
			#print('yeeeee')
	
	if input.y == 0:
		pap.play("wallfall")
	else:
		pap.play("climb")
		if input.y > 0:
			sprite.flip_v = true
		else:
			sprite.flip_v = false
	
	if Input.is_action_just_pressed("jump"):
		if not is_on_floor() and $WallCheck.is_colliding():
			#print('WALLL JUMP')
			sprite.flip_v = false
			wall_jump()
		else: 
			#print('alsdjflakdsjflaksdjflksdajflskfjlskfjalskdjflkjdflafkjd')
			jump_count = max_jump - 1
			jumpped = false
			sprite.flip_v = false
			change_state(States.JUMP)
	
	if is_on_floor() and (input.y == 0 and !$WallCheck.is_colliding()): 
		sprite.flip_v = false
		change_state(States.IDLE)
	
	$WallCheck.force_shapecast_update()
	if input.x != 0:
		if $WallCheck.is_colliding() and input.x != (-1 *$WallCheck.get_collision_normal(0).x):
			#print($WallCheck.get_collision_normal(0))
			#print('alkdsfjlk')
			if input.y == 0 :
				velocity.x = move_toward(velocity.x, MAX_SPEED * input.x, acceleration)
				sprite.flip_v = false
				change_state(States.FALL)
				

## WALL CLIMB
# wall climb is, only one frame thing no need to play animation
func wall_climb(delta):
	#sprite.flip_v = false
	if not $WallCheck.is_colliding():
		change_state(States.FALL)
	
	$WallCheckForClimb.force_shapecast_update()
	velocity.y = input.y * (WALL_SLIDE_SPEED)
	if $WallCheckForClimb.is_colliding():
		if $WallCheckForClimb.get_collision_normal(0).x == -1:
			velocity.x = 500
		else:
			velocity.x = -500
	
	if not $WallCheck.is_colliding():
		if input.x == 0:
			change_state(States.IDLE)
		if input.x != 0:
			change_state(States.RUN)
		if Input.is_action_just_pressed("jump") or (buffered_jump_enabled and is_on_floor()):
			jump_count = max_jump - 1
			jumpped = false
			change_state(States.JUMP)
		if $WallCheck.is_colliding() and input.y != 0:
			if input.y != 0: 
				change_state(States.WALL_SLIDE)
	


func wall_jump():
	#print('WALL JUMP')
	$WallCheck.force_shapecast_update()
	if $WallCheck.is_colliding():
		wall_direction = $WallCheck.get_collision_normal(0)
		#print(wall_direction)
		#print('~~~~~~~~~~~~~~~~~~~~~~~~~~~')
	else :
		wall_direction = Vector2.ZERO
	
	# Reset jump count
	jump_count = max_jump - 1
	jumpped = false
	
	# Wall jump based on wall direction
	if wall_direction.x == 1:  # Left wall
		velocity.x = WALL_JUMP_VELOCITY_X
	elif wall_direction.x == -1:  # Right wall
		velocity.x = -WALL_JUMP_VELOCITY_X
	
	
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
	jump_buffer_checked = true

func _on_coyote_jump_timer_timeout():
	coyote_jump_enabled = false

func _on_min_jump_timer_timeout():
	## check if player has released jump button early
	if !Input.is_action_pressed("jump"):
		if velocity.y < -10:
			velocity.y = -10

func any_wall_detect():
	# wall_detect_1.is_colliding() or wall_detect_2.is_colliding()
	if wall_detect_ray_1.is_colliding():
		return 1
	elif wall_detect_ray_2.is_colliding():
		return -1
	else:
		return 0
