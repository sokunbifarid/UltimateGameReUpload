# MainMenu3D.gd (Attached to root Node3D)
# MainMenu3D.gd
extends Node3D

@onready var Anim = get_node("/root/mainMenuroot/AnimationPlayer")
@onready var camera = get_node("/root/mainMenuroot/MainCamera")
@onready var local_button = get_node("/root/mainMenuroot/MainMenu/LocalButton")
@onready var online_button = get_node("/root/mainMenuroot/MainMenu/OnlineButton")
@onready var quit_button = get_node("/root/mainMenuroot/MainMenu/QuitButton")

@onready var online_menu: Node3D = $OnlineMenu
@onready var main_menu: Node3D = $MainMenu


func _on_local_button_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		print("Local game started")
		Anim.play("main_to_local")

func _on_online_button_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		main_menu.hide()
		online_menu.show()

func _on_quit_button_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		print("Quit game")
		get_tree().quit()

#The Hover FeedBack
func _on_local_button_mouse_entered() -> void:
	local_button.scale = Vector3(1.2, 1.2, 1.2)
	 # Replace with function body.


func _on_local_button_mouse_exited() -> void:
	local_button.scale = Vector3.ONE # Replace with function body.


func _on_quit_button_mouse_entered() -> void:
	quit_button.scale = Vector3(1.2, 1.2, 1.2)
	

func _on_quit_button_mouse_exited() -> void:
	quit_button.scale = Vector3.ONE# Replace with function body.
