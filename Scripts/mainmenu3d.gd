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

# Store initial positions
var main_menu_start_pos: Vector3
var online_menu_start_pos: Vector3
var slide_distance: float = 18.0  # Adjust this value based on your scene scale

func _ready() -> void:
	# Store the initial positions
	main_menu_start_pos = main_menu.position
	online_menu_start_pos = online_menu.position
	
	# Position online menu off-screen to the right initially
	online_menu.position = main_menu_start_pos + Vector3(slide_distance, 0, 0)
	online_menu.hide()
	
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

	back_to_main_menu.input_event.connect(_on_main_menu_input_event)


func _on_local_button_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		pass
		
func _on_online_button_input_event(_camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		slide_to_online_menu()

func slide_to_online_menu():
	# Show online menu before animating
	online_menu.show()
	
	# Create tween for smooth animation
	var tween = create_tween()
	tween.set_parallel(true)  # Animate both menus simultaneously
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Slide main menu to the left (off-screen)
	tween.tween_property(main_menu, "position", main_menu_start_pos - Vector3(slide_distance, 0, 0), 0.5)
	
	# Slide online menu to the center
	tween.tween_property(online_menu, "position", main_menu_start_pos, 0.5)
	
	# Hide main menu after animation completes
	tween.chain().tween_callback(func(): main_menu.hide())

func slide_to_main_menu():
	# Show main menu before animating
	main_menu.show()
	
	# Create tween for smooth animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Slide online menu to the right (off-screen)
	tween.tween_property(online_menu, "position", main_menu_start_pos + Vector3(slide_distance, 0, 0), 0.5)
	
	# Slide main menu to the center
	tween.tween_property(main_menu, "position", main_menu_start_pos, 0.5)
	
	# Hide online menu after animation completes
	tween.chain().tween_callback(func(): online_menu.hide())

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


func _on_main_menu_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		slide_to_main_menu()
