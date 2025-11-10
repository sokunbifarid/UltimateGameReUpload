extends Node3D

@onready var _1: Area3D = $"1"
@onready var _2: Area3D = $"2"
@onready var _3: Area3D = $"3"
@onready var _4: Area3D = $"4"

# Target object that will move (adjust this to your actual target node)
@onready var target_object = self  # Change this to the node you want to move

var y_pos: float = 0.0
var is_animating: bool = false

func _ready() -> void:
	# Connect all buttons
	_1.input_event.connect(_on_number_input_event.bind("1"))
	_2.input_event.connect(_on_number_input_event.bind("2"))
	_3.input_event.connect(_on_number_input_event.bind("3"))
	_4.input_event.connect(_on_number_input_event.bind("4"))
	
	# Connect hover effects
	_1.mouse_entered.connect(_on_button_hover.bind(_1))
	_2.mouse_entered.connect(_on_button_hover.bind(_2))
	_3.mouse_entered.connect(_on_button_hover.bind(_3))
	_4.mouse_entered.connect(_on_button_hover.bind(_4))
	
	_1.mouse_exited.connect(_on_button_unhover.bind(_1))
	_2.mouse_exited.connect(_on_button_unhover.bind(_2))
	_3.mouse_exited.connect(_on_button_unhover.bind(_3))
	_4.mouse_exited.connect(_on_button_unhover.bind(_4))
func _on_number_input_event(_camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int, num: String) -> void:
	if event is InputEventMouseButton and event.pressed and not is_animating:
		var new_y_pos: float = 0.0
		
		match num:
			"1":
				new_y_pos = 0
				Multiplayer.lobby_members_max = 1
			"2":
				new_y_pos = 1.5
				Multiplayer.lobby_members_max = 2
			"3":
				new_y_pos = 3
				Multiplayer.lobby_members_max = 3
			"4":
				new_y_pos = 4.5
				Multiplayer.lobby_members_max = 4
		
		# Animate to the new position
		animate_to_position(new_y_pos)

func animate_to_position(new_y: float) -> void:
	is_animating = true
	
	# Store current position
	var current_pos = target_object.position
	var target_pos = Vector3(current_pos.x, new_y, current_pos.z)
	
	# Create smooth tween with bounce effect
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)  # Adds a slight overshoot for smoothness
	
	# Main movement animation
	tween.tween_property(target_object, "position", target_pos, 0.6)
	
	# Optional: Add a subtle scale bounce effect
	tween.parallel().tween_property(target_object, "scale", Vector3(1.05, 1.05, 1.05), 0.3)
	tween.tween_property(target_object, "scale", Vector3(1.0, 1.0, 1.0), 0.3)
	
	# Update y_pos and unlock animation when complete
	tween.finished.connect(func():
		y_pos = new_y
		is_animating = false
	)

func _on_button_hover(button: Area3D) -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(button, "scale", Vector3(1.5, 1.5, 1.5), 0.3)

func _on_button_unhover(button: Area3D) -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(button, "scale", Vector3(1.0, 1.0, 1.0), 0.3)
