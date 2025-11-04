extends Node3D

@export var use_gamepad: bool = false
@export var player_index: int = 0  # 0 for P1 (mouse), 1 for P2 (gamepad)
@export var gamepad_device: int = 0  # Which gamepad device (0, 1, 2, 3)
@export var invert_x: bool = false
@export var invert_y: bool = false
@export var mouse_sensitivity: float = 0.002
@export var stick_sensitivity: float = 2.5
@export var arm_yaw_offset_deg: float = 180.0  

@onready var spring_arm_3d: SpringArm3D = $SpringArm3D
@onready var camera_3d: Camera3D = $SpringArm3D/Camera3D

var yaw: float = 0.0
var pitch: float = 0.0
var is_active: bool = false
var mouse_captured: bool = false

func _ready() -> void:
	# Only the mouse player should capture mouse
	if not use_gamepad and player_index == 0:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		is_active = true
		mouse_captured = true
	elif use_gamepad:
		is_active = true
	
	yaw = transform.basis.get_euler().y
	pitch = spring_arm_3d.transform.basis.get_euler().x
	_apply_yaw_pitch()

func _process(delta: float) -> void:
	if not is_active:
		return
	
	if use_gamepad:
		# Gamepad camera control
		var look_x = _get_joy_axis(JOY_AXIS_RIGHT_X)
		var look_y = _get_joy_axis(JOY_AXIS_RIGHT_Y)
		
		# Apply inversion if enabled
		if invert_x:
			look_x *= -1.0
		if invert_y:
			look_y *= -1.0
		
		# Apply deadzone
		var deadzone = 0.2
		if abs(look_x) < deadzone:
			look_x = 0.0
		if abs(look_y) < deadzone:
			look_y = 0.0
		
		if abs(look_x) > 0.01 or abs(look_y) > 0.01:
			yaw   = wrapf(yaw   - look_x * stick_sensitivity * delta, -PI, PI)
			pitch = clampf(pitch - look_y * stick_sensitivity * delta, deg_to_rad(-60.0), deg_to_rad(30.0))
			_apply_yaw_pitch()
	else:
		# Mouse camera control - handle ESC key
		if Input.is_action_just_pressed("ui_cancel"):
			if mouse_captured:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				mouse_captured = false
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				mouse_captured = true
		
		# Only process mouse movement if mouse is captured
		if  Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			var mouse_velocity = Input.get_last_mouse_velocity()
			
			if mouse_velocity.length_squared() > 0.0:
				yaw   = wrapf(yaw   - mouse_velocity.x * mouse_sensitivity * delta, -PI, PI)
				pitch = clampf(pitch - mouse_velocity.y * mouse_sensitivity * delta, deg_to_rad(-60.0), deg_to_rad(30.0))
				_apply_yaw_pitch()

# Get joystick axis value for this player's specific device
func _get_joy_axis(axis: JoyAxis) -> float:
	return Input.get_joy_axis(gamepad_device, axis)

# Get button state for this player's specific device
func _is_joy_button_pressed(button: JoyButton) -> bool:
	return Input.is_joy_button_pressed(gamepad_device, button)

# Get action strength for this player's specific device (if you still use actions)
func _get_action_strength_for_device(action: String) -> float:
	var events = InputMap.action_get_events(action)
	for event in events:
		if event is InputEventJoypadMotion:
			if event.device == gamepad_device or event.device == -1:  # -1 means all devices
				return Input.get_joy_axis(gamepad_device, event.axis) * (1.0 if event.axis_value > 0 else -1.0)
		elif event is InputEventJoypadButton:
			if event.device == gamepad_device or event.device == -1:
				if Input.is_joy_button_pressed(gamepad_device, event.button_index):
					return 1.0
	return 0.0

func _apply_yaw_pitch() -> void:
	var t_pivot := transform
	t_pivot.basis = Basis(Quaternion(Vector3.UP, yaw))
	transform = t_pivot
	
	var t_arm := spring_arm_3d.transform
	var yaw_off := deg_to_rad(arm_yaw_offset_deg)
	var q := Quaternion(Vector3.UP, yaw_off) * Quaternion(Vector3.RIGHT, pitch)
	t_arm.basis = Basis(q)
	spring_arm_3d.transform = t_arm

func activate_camera():
	camera_3d.current = true
	is_active = true

func deactivate():
	is_active = false
