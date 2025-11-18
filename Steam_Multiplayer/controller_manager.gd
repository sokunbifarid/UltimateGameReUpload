extends Node

var connected_controllers: Dictionary = {}  # device_id -> type

func _ready():
	# Check existing controllers at startup
	_scan_existing_controllers()

	# Signal for new connections or disconnections
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	
	print("IS PS : ",is_controller_PS())
func is_controller_PS():
	return connected_controllers[0] == "playstation"

func _scan_existing_controllers():
	var pads = Input.get_connected_joypads()
	for device_id in pads:
		_identify_controller(device_id, true)


func _on_joy_connection_changed(device_id: int, connected: bool):
	if connected:
		_identify_controller(device_id, true)
	else:
		print("Controller disconnected:", device_id)
		connected_controllers.erase(device_id)


func _identify_controller(device_id: int, announce: bool):
	var name := Input.get_joy_name(device_id)
	var controller_type := "unknown"

	if _is_playstation(name):
		controller_type = "playstation"
	elif _is_xbox(name):
		controller_type = "xbox"

	connected_controllers[device_id] = controller_type

	if announce:
		print("--------------------------------")
		print("Device id:", device_id)
		print("Name:", name)
		print("Type:", controller_type)
		print("--------------------------------")


func _is_playstation(name: String) -> bool:
	name = name.to_lower()
	return name.find("ps") != -1 \
		or name.find("playstation") != -1 \
		or name.find("dualshock") != -1 \
		or name.find("dualsense") != -1 \
		or name.find("wireless controller") != -1


func _is_xbox(name: String) -> bool:
	name = name.to_lower()
	return name.find("xbox") != -1 \
		or name.find("x-box") != -1 \
		or name.find("microsoft") != -1
