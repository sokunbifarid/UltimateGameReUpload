extends Node3D

@onready var yes: Area3D = $"no"
@onready var no: Area3D = $"yes"

# Target object that will move (adjust this to your actual target node)
@onready var target_object = self  # Change this to the node you want to move
var is_controller_connected: bool = false
var y_pos: float = 0.0
var is_animating: bool = false

func _ready() -> void:
	# Connect all buttons
	yes.input_event.connect(_on_number_input_event.bind("1"))
	no.input_event.connect(_on_number_input_event.bind("0"))
	# Connect hover effects
	yes.mouse_entered.connect(_on_button_hover.bind(yes))
	no.mouse_entered.connect(_on_button_hover.bind(no))
	
	yes.mouse_exited.connect(_on_button_unhover.bind(yes))
	no.mouse_exited.connect(_on_button_unhover.bind(no))
	check_controller_connection()
	if !is_controller_connected:
		get_parent().hide()
func check_controller_connection() -> void:
	"""Check if any controller is connected"""
	var connected_joypads = Input.get_connected_joypads()
	is_controller_connected = connected_joypads.size() > 0
	
	if is_controller_connected:
		print("Controller connected: %s" % Input.get_joy_name(connected_joypads[0]))
	else:
		print("No controller connected")

func _on_joy_connection_changed(device: int, connected: bool) -> void:
	"""Handle controller connection/disconnection"""
	if connected:
		print("Controller connected: %s (Device %d)" % [Input.get_joy_name(device), device])
		is_controller_connected = true
	else:
		print("Controller disconnected (Device %d)" % device)
		# Check if any controllers are still connected
		is_controller_connected = Input.get_connected_joypads().size() > 0

func get_controller_connected() -> bool:
	"""Returns whether a controller is currently connected"""
	return is_controller_connected

func _on_number_input_event(_camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int, num: String) -> void:
	if event is InputEventMouseButton and event.pressed and not is_animating:
		var new_y_pos: float = 0.0
		
		match num:
			"1":
				new_y_pos = 3.9
				Multiplayer.use_gamepad = true
			"0":
				new_y_pos = 3.17
				Multiplayer.use_gamepad = false
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
	tween.parallel().tween_property(target_object, "scale", Vector3(0.57, 0.57, 0.57), 0.3)
	tween.tween_property(target_object, "scale", Vector3(0.55, 0.55, 0.55), 0.3)
	
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
