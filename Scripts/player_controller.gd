extends CharacterBody3D
signal OnTakeDamage (hp : int)
signal OnUpdateScore (score : int)

@export var health : int = 3
@export var move_speed : float = 3.0
@export var jump_force : float = 8.0
@export var gravity : float = 20.0
@export var rotation_speed := 5.0
@onready var camera: Camera3D = $third_person_controller/SpringArm3D/Camera3D

func _ready():
	# Wait a frame to ensure multiplayer authority is properly set
	await get_tree().process_frame
	
	print("Player ready - Name: %s, Authority: %s, Multiplayer ID: %s" % [name, get_multiplayer_authority(), multiplayer.get_unique_id()])
	
	# Only enable camera for local player
	if is_multiplayer_authority():
		camera.current = true
		print("This is MY player - enabling camera and input")
	else:
		camera.current = false
		print("This is a REMOTE player - disabling camera")
	
	# Add dash action
	if not InputMap.has_action("dash"):
		var dash_event = InputEventKey.new()
		dash_event.keycode = KEY_SHIFT
		InputMap.add_action("dash")
		InputMap.action_add_event("dash", dash_event)

func _physics_process(delta):
	# CRITICAL: Only process input for the player we have authority over
	if not is_multiplayer_authority():
		return
	
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	var speed = move_speed
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

	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = jump_force

	move_and_slide()
	
	if global_position.y < -5:
		_game_over()

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
