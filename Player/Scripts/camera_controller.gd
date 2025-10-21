extends Node3D
@onready var label: Label = $"../Label"
@export var camera: Camera3D
@export var navi_agent: NavigationAgent3D
@export var raycast : RayCast3D
@export var ray_end_point : Marker3D
@export var sens = 0.5
@export var zoom_speed = 0.5
@export var min_distance = 1.7
@export var max_distance = 20.0
var last_colliding_object = null
var rotation_lock : bool = true
var vertical_rotation := 0.0
var horizontal_rotation := 0.0
var original_rotation: Vector3

func _ready() -> void:
	original_rotation = rotation

func _process(delta: float) -> void:
	if !camera.current: return
	handle_zoom()
	handle_raycast()

func point_click_movement(event):
	if !rotation_lock: 
		return
	if Input.is_action_just_pressed("leftMouseButton"):
		var mousePos = get_viewport().get_mouse_position()
		var rayLength = 1000
		var from = camera.project_ray_origin(mousePos)
		var to = from + camera.project_ray_normal(mousePos) * rayLength
		var space = get_world_3d().direct_space_state
		var rayQuery = PhysicsRayQueryParameters3D.new()
		rayQuery.from = from
		rayQuery.to = to
		rayQuery.collide_with_areas = true
		var result = space.intersect_ray(rayQuery)
		if result.size() > 0:
			navi_agent.target_position = result.position

func _input(event):
	if !camera.current : return
	if event is InputEventMouseMotion and !rotation_lock:
		# Horizontal rotation around the Y-axis (left/right)
		horizontal_rotation -= event.relative.x * sens
		rotation.y = deg_to_rad(horizontal_rotation)
		# Vertical rotation around local X-axis (up/down)
		vertical_rotation = clamp(vertical_rotation - event.relative.y * sens, -30, 35)
		rotation.x = deg_to_rad(vertical_rotation)
	
	if Input.is_action_just_pressed("camera_reset"):
		rotation = original_rotation
		rotation_lock = !rotation_lock
		label.text = "Rotation Lock : " + str(rotation_lock)
	
	point_click_movement(event)

func handle_zoom():
	if Input.is_action_pressed("zoom_in"):
		camera.size = clamp(camera.size - zoom_speed, min_distance, max_distance)
	elif Input.is_action_pressed("zoom_out"):
		camera.size = clamp(camera.size + zoom_speed, min_distance, max_distance)

func handle_raycast():
	var current_collider: Node = null

	if raycast.is_colliding():
		var hit = raycast.get_collider()
		# Direct MeshInstance3D
		if hit is MeshInstance3D:
			current_collider = hit

		# Direct CSG shape
		elif hit is CSGShape3D: # Covers CSGBox3D, CSGSphere3D, etc.
			current_collider = hit

		# Parent has a MeshInstance3D child
		elif hit.has_node("MeshInstance3D"):
			current_collider = hit.get_node("MeshInstance3D")

		# If we found a valid collider and it's different from last
		if current_collider and current_collider != last_colliding_object:
			_restore_last_object()

			# Fade current object
			var current_material = current_collider.get_active_material(0) if current_collider is MeshInstance3D else current_collider.material
			if current_material:
				current_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				current_material.albedo_color.a = 0.1

			last_colliding_object = current_collider

	else:
		# No hit, restore last object if any
		if last_colliding_object:
			_restore_last_object()
			last_colliding_object = null


func _restore_last_object():
	if last_colliding_object:
		var last_material
		if last_colliding_object  is MeshInstance3D:
			last_material = last_colliding_object.get_active_material(0)
		else:
			last_material = last_colliding_object.material
		if last_material:
			last_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			last_material.albedo_color.a = 1.0
