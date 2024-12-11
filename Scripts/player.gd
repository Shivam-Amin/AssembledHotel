class_name Player
extends CharacterBody2D

#Dependencies
#@onready var ground_ray: RayCast2D = $ground_ray

## MOVEMENT SECTION

#setup Variables
@export var MAX_SPEED: int = 150
@export var acceleration: float = 20

## JUMP SECTION:
@export var max_jump: int = 2
var jump_count : int = max_jump

# setup Veriables
@export var jump_height: float = 50
@export var jump_time_to_peak: float = 0.3
@export var jump_time_to_decent: float = 0.3

# jump Calculation
@onready var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak ) * -1
@onready var jump_gravity: float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1
@onready var fall_gravity: float = ((-2.0 * jump_height) / (jump_time_to_decent * jump_time_to_decent)) * -1 

# variable jump
@onready var jump_height_timer: Timer = $Timer/JumpHeightTimer

## Wall movement:
@onready var wall_detect_1 = $WallDetect/WallDetect1
@onready var wall_detect_2 = $WallDetect/WallDetect2

# Wall detection
@onready var on_wall: bool = false
@onready var walling_area: bool = false
# wall climb speed
const wall_climb_speed = 170

# wall jump
const wall_jump_pushback = 400
var jump_pressed = false

# wall sliding 
const wall_slide_gravity = 30
#var is_wall_sliding: bool = false

# jump buffer
@onready var jump_buffer_timer: Timer = $Timer/JumpbufferTimer
var jump_buffered: bool = false

# coyote timer
@onready var coyote_time: Timer = $Timer/CoyoteTimer
var can_coyote_jump: bool = false


var input: Vector2 = Vector2.ZERO

enum States  {IDLE, RUNNING, JUMPPING, WALLING}

var state = States.IDLE

func _physics_process(delta: float) -> void:
	if not on_wall:
		applay_gravity(delta)
	
	match state:
		States.IDLE:
			idle()
		States.RUNNING:
			running()
		States.JUMPPING:
			JUMPPING()
		States.WALLING:
			WALLING()
	
	
	wall_slide(delta)
	
	var was_on_floor = is_on_floor()
	var was_on_wall = detected_wall()
	
	move_and_slide()
	
	# NOTE: velocity.y is > 0 i.e. player has not started jumping but gravity applied.
	if was_on_floor and not is_on_floor() and velocity.y >= 0:
		can_coyote_jump = true
		coyote_time.start()
	
	#if not was_on_floor and is_on_floor():
		## NOTE: Perform BUFFER JUMP
		#if jump_buffered:
			#jump_buffered = false
			#change_state(States.JUMPPING)
	
	#print(not detected_wall(), was_on_wall)
		
	#if was_on_wall and not detected_wall():
		#print('UPPER JAAAA')
		#velocity.y -= -1000.0
		#velocity.x -= 1000.0

func change_state(new_state: States):
	state = new_state

func idle():
	velocity.x = move_toward(velocity.x, 0.0, acceleration)
	jump_count = max_jump
	
	if Input.is_action_just_pressed("jump"):
		change_state(States.JUMPPING)
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
		change_state(States.RUNNING)
	if detected_wall():
		change_state(States.WALLING)

func running():
	input.x = Input.get_axis("ui_left", "ui_right")
	input = input.normalized()
	
	velocity.x = move_toward(velocity.x, MAX_SPEED * input.x, acceleration)
	
	if input == Vector2.ZERO:
		change_state(States.IDLE)
	if Input.is_action_just_pressed("jump"):
		change_state(States.JUMPPING)
	if detected_wall():
		change_state(States.WALLING)

func JUMPPING():
	jump_height_timer.start()
	if can_jump() and not is_on_wall():
		jump_count -=1
		velocity.y = jump_velocity
		
		if can_coyote_jump:
			can_coyote_jump = false
			print("COYOTE JUMP")
	
	elif detected_wall():
		jump_count = max_jump
		if wall_detect_1.is_colliding():
			print('lsadfjalskdjfslkj')
			var new_velocity = Vector2(-wall_jump_pushback, jump_velocity)
			velocity = new_velocity
		elif wall_detect_2.is_colliding():
			var new_velocity = Vector2(wall_jump_pushback, jump_velocity)
			velocity = new_velocity
	
	#else:
		#if not jump_buffered:
			#jump_buffered = true
			#jump_buffer_timer.start()
			#print("JUMP BUFFER TRUE")
	
	
	if Input.is_action_pressed("jump") and not is_on_floor():
		if not jump_buffered:
			print('jsdfkljlkj')
			jump_pressed = true
			jump_buffer_timer.start()
			jump_buffered = true
	
	
	if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
		change_state(States.RUNNING)
	if is_on_floor() and jump_pressed:
		print('jabbaaa')
		if not jump_buffer_timer.is_stopped() and jump_count > 0:
			velocity.y = jump_velocity
		else:
			change_state(States.IDLE)
	if detected_wall():
		change_state(States.WALLING)

func WALLING():
	if detected_wall():
		on_wall = true
		
		# wall slide gravity
		velocity.y += wall_slide_gravity
		velocity.y = min(velocity.y, wall_slide_gravity)
		
		if Input.is_action_pressed("ui_up"):
			velocity.y = -wall_climb_speed
		elif Input.is_action_pressed("ui_down"):
			velocity.y = wall_climb_speed
		elif Input.is_action_just_pressed("jump"):
			change_state(States.JUMPPING)
	else:
		on_wall = false
	
	if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
		change_state(States.RUNNING)
	if is_on_floor():
		change_state(States.IDLE)

func _on_coyote_timer_timeout():
	can_coyote_jump = false

func _on_jumpbuffer_timer_timeout():
	jump_pressed = false
	jump_buffered = false

func _on_jump_height_timer_timeout():
	if not Input.is_action_pressed("jump"):
		if velocity.y < -10:
			velocity.y = -10

func jump():
	pass
#func can_wall_slide() -> bool:
	#if detected_wall() and !is_on_floor():
		#if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
			#return true
		#else: 
			#return false
	#return false

func detected_wall():
	if wall_detect_1.is_colliding() or wall_detect_2.is_colliding():
		return true
	return false

func wall_slide(delta):
	pass

func get_gravity() -> float:
	# return jump_gravity if player is jumping
	if velocity.y < 0.0:
		return jump_gravity
	else:
		# NOTE: if player is not on floor and coyote timer is also gone,
		# then return fall gravity, else return 0.
		if !is_on_floor() and can_coyote_jump == false:
			return fall_gravity
		return 0.0
	
	#return jump_gravity if velocity.y < 0.0 else fall_gravity

func applay_gravity(delta):
	velocity.y += get_gravity() * delta

func grounded():
	if is_on_floor() or can_coyote_jump:
		jump_count = max_jump
		return true

func can_jump():
	if grounded() or jump_count>0:
		return true
	else: 
		return false



func _on_wall_area_body_entered(body):
	if body is TileMap:
		walling_area = true

func _on_wall_area_body_exited(body):
	if body is TileMap:
		walling_area = false















##==============================
#class_name PlayerJumpState
#extends State
#
#signal to_idle
#signal to_climb
#signal to_smash
#signal to_jump
#
## Dependencies
##@export var player :Player
#@export var player : Player
##@export var skin : Node2D
#@export var vap: AnimationPlayer
#
#@onready var smash_timer: Timer = $smash_timer
#@onready var jump_timer: Timer = $jump_timer
#
#var has_pressed = false
##var con = [to_idle]
#func _ready() -> void:
	#set_physics_process(false)
#
#func enter_state() -> void:
	##var tween = create_tween().set_trans(Tween.TRANS_EXPO)
	##tween.tween_property(skin, "scale",Vector2(0.2,1), 0.3)
	#vap.play("Yellowstamp")
	#player.can_smash = true
	#smash_timer.start()
	##print("timer_started")
	#set_physics_process(true)
	#player.jumps -= 1
	#jump()
#
#func _physics_process(delta: float) -> void:
	#if !player.is_on_floor() && !has_pressed:
		#if Input.is_action_just_pressed("jump"):
			##print("jump_timer_started")
			#has_pressed = true
			#jump_timer.start()
	#player.apply_gravity(delta)
	#
	##if Input.is_action_just_released("jump") && player.velocity.y <0:
		##player.velocity.y = player.jump_velocity/4
	#
	#if player.is_on_floor() or player.any_ray_collide():
		#if has_pressed && !jump_timer.is_stopped():
			##par.explode()
			#jump_timer.stop()
			##print("jumped again")
			#has_pressed = false
			#to_jump.emit()
		#else:
			#jump_timer.stop()
			##print("jump timer ended before")
			#has_pressed = false
			#to_idle.emit()
	#
	#if player.any_ray_collide():
		#to_climb.emit()
	#
	## GROUND BREAK FUNCTIONALITY LMAO
	#if Input.is_action_pressed("down") && player.can_smash && player.smashin == true:
		#to_smash.emit()
	#
	#if Input.is_action_just_pressed("jump") && player.jumps > 0:
		##par.explode()
		#to_jump.emit()
		##smash_timer.start()
		##jump()
		##player.jumps -= 1
	#var input = Input.get_axis("left", "right")
	#player.velocity.x = move_toward(player.velocity.x, player.max_speed * input, player.acceleration)
	##var was_on_floor = player.is_on_floor()
	#player.move_and_slide()
	##if !was_on_floor && player.is_on_floor():
		##par.explode()
#
#func jump():
	#player.velocity.y = player.jump_velocity
#
#
#func exit_state() -> void:
	##var tween = create_tween().set_trans(Tween.TRANS_EXPO)
	##tween.tween_property(skin, "scale",Vector2(1,1), 0.3)
	#set_physics_process(false)
#
#
#func _on_jump_timer_timeout() -> void:
	#has_pressed = false
