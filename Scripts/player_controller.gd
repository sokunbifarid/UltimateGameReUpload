extends CharacterBody3D
signal OnTakeDamage (hp : int)
signal OnUpdateScore (score : int)


@export var health : int = 3
@export var move_speed : float = 3.0
@export var jump_force : float = 8.0
@export var gravity : float = 20.0
@export var rotation_speed := 5.0
@onready var camera: Camera3D = $third_person_controller/SpringArm3D/Camera3D


func _physics_process(delta):

	if !is_multiplayer_authority():
		return
	
  	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Sprint control
	var speed = move_speed

	# Movement
	var move_dir = Vector3.ZERO
	
	if Input.is_action_pressed("move_forward"):
		move_dir.z -= 1
	elif Input.is_action_pressed("move_back"):
		move_dir.z += 1

	if Input.is_action_pressed("move_left"):
		move_dir.x -= 1
	elif Input.is_action_pressed("move_right"):
		move_dir.x += 1
	
	move_dir = move_dir.normalized()
	velocity.x = move_dir.x * speed
	velocity.z = move_dir.z * speed

	# Jumping
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = jump_force

	velocity = velocity
	move_and_slide()
	if global_position.y < -5:
			_game_over()

# Add new action "dash" and bind it to Shift
func _ready():
	if is_multiplayer_authority():
		camera.current = true
		print("yes is_multiplayer_authority")
	var dash_event = InputEventKey.new()
	dash_event.keycode = KEY_SHIFT
	InputMap.add_action("dash")
	InputMap.action_add_event("dash", dash_event)


func take_damage (amount : int):
	health -= amount
	OnTakeDamage.emit(health)
	print("take damage")
	
	if health <= 0:
		call_deferred("_game_over")

func _game_over ():
	PlayerStats.score = 0
	$GOScn.visible = true
	$GOScn.get_node("AnimationPlayer").play("Fade_in")
	
func increase_score (amount : int):
	PlayerStats.score += amount
	OnUpdateScore.emit(PlayerStats.score)
