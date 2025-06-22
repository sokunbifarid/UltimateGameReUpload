extends CharacterBody3D

signal OnTakeDamage (hp : int)
signal OnUpdateScore (score: int)

@export var health : int = 5
@export var move_speed : float = 3.0
@export var jump_force : float = 8.0
@export var gravity : float = 20.0

@onready var camera : Camera3D = $Camera3D

func _physics_process(delta):
	#gravity
	velocity.y -= gravity * delta
	
	#jump
	if Input.is_action_pressed("jump") and is_on_floor():
			velocity.y = jump_force
	
	#movement for left and arrow keys etc
	var move_input : Vector2 = Input.get_vector("Move Left","Move Right","Move Forward","Move Back")
	var move_dir: Vector3 = Vector3(move_input.x, 0, move_input.y)
	
	velocity.x = move_dir.x * move_speed
	velocity.z = move_dir.z * move_speed
	
	
	move_and_slide()
	
func take_damage (amount : int):
	health -= amount
	OnTakeDamage.emit(health)
	if health <=0:
		_game_over()
		 
func _game_over():
	PlayerSts.score = 0 
	get_tree().reload_current_scene()

func increase_score (amount : int):
	PlayerSts.score += amount
	OnUpdateScore.emit(PlayerSts.score)
	print(PlayerSts.score)
	
