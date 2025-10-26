# MainMenu3D.gd
extends Node3D

@onready var Anim = get_node("/root/mainMenuroot/AnimationPlayer")
@onready var camera = get_node("/root/mainMenuroot/MainCamera")
@onready var local_button : Area3D = get_node("/root/mainMenuroot/MainMenu/LocalButton")
@onready var online_button = get_node("/root/mainMenuroot/MainMenu/OnlineButton")
@onready var quit_button = get_node("/root/mainMenuroot/MainMenu/QuitButton")
@onready var host_lobby: Area3D = $OnlineMenu/Host_Lobby
@onready var refresh_lobbies: Area3D = $OnlineMenu/refresh_Lobbies
@onready var online_menu: Node3D = $OnlineMenu
@onready var main_menu: Node3D = $MainMenu
@onready var back_to_main_menu: Area3D = $OnlineMenu/Main_Menu
@onready var character_selection: Area3D = $OnlineMenu/Character_Selection
@onready var character_selection_menu: Node3D = $Character_Selection

# Store camera positions for each menu
var camera_main_menu_pos: Vector3
var camera_online_menu_pos: Vector3
var camera_character_selection_pos: Vector3
var slide_distance: float = 20.0  # Distance between menus

func _ready() -> void:
	# Store the initial camera position (main menu view)
	camera_main_menu_pos = camera.position
	
	# Calculate camera positions for other menus
	# Online menu is to the right of main menu
	camera_online_menu_pos = camera_main_menu_pos + Vector3(slide_distance, 0, 0)
	
	# Character selection is to the right of online menu
	camera_character_selection_pos = camera_online_menu_pos + Vector3(slide_distance, 0, 0)
	
	# Show all menus (camera will control what's visible)
	main_menu.show()
	online_menu.show()
	character_selection_menu.show()
	
	connect_signals()
	
func connect_signals():
	local_button.mouse_entered.connect(_on_mouse_entered.bind(local_button))
	online_button.mouse_entered.connect(_on_mouse_entered.bind(online_button))
	quit_button.mouse_entered.connect(_on_mouse_entered.bind(quit_button))
	host_lobby.mouse_entered.connect(_on_mouse_entered.bind(host_lobby))
	refresh_lobbies.mouse_entered.connect(_on_mouse_entered.bind(refresh_lobbies))
	back_to_main_menu.mouse_entered.connect(_on_mouse_entered.bind(back_to_main_menu))
	character_selection.mouse_entered.connect(_on_mouse_entered.bind(character_selection))

	local_button.mouse_exited.connect(_on_mouse_exited.bind(local_button))
	online_button.mouse_exited.connect(_on_mouse_exited.bind(online_button))
	quit_button.mouse_exited.connect(_on_mouse_exited.bind(quit_button))
	host_lobby.mouse_exited.connect(_on_mouse_exited.bind(host_lobby))
	refresh_lobbies.mouse_exited.connect(_on_mouse_exited.bind(refresh_lobbies))
	back_to_main_menu.mouse_exited.connect(_on_mouse_exited.bind(back_to_main_menu))
	character_selection.mouse_exited.connect(_on_mouse_exited.bind(character_selection))

	online_button.input_event.connect(_on_online_button_input_event)
	back_to_main_menu.input_event.connect(_on_main_menu_input_event)
	character_selection.input_event.connect(_on_character_selection_input_event)
	quit_button.input_event.connect(_on_quit_button_input_event)

func _on_local_button_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		pass
		
@warning_ignore("unused_parameter")
func _on_online_button_input_event(_camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		move_camera_to_online_menu()

@warning_ignore("unused_parameter")
func _on_character_selection_input_event(_camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		move_camera_to_character_selection()

func move_camera_to_online_menu():
	animate_camera_to_position(camera_online_menu_pos)


func move_camera_to_character_selection():
	animate_camera_to_position(camera_character_selection_pos)

func move_camera_to_main_menu():
	animate_camera_to_position(camera_main_menu_pos)

func animate_camera_to_position(target_pos: Vector3):
	# Create smooth camera movement animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Move camera to target position
	tween.tween_property(camera, "position", target_pos, 0.5)

func _on_quit_button_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		print("Quit game")
		get_tree().quit()

func _on_mouse_entered(area3d):
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(area3d, "scale", Vector3(1.5, 1.5, 1.5), 0.3)

func _on_mouse_exited(area3d):
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(area3d, "scale", Vector3(1.0, 1.0, 1.0), 0.3)

@warning_ignore("unused_parameter", "shadowed_variable")
func _on_main_menu_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		move_camera_to_main_menu()
