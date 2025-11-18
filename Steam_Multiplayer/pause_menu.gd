extends Control

@onready var back_to_game: Button = $ColorRect/HBoxContainer/backToGame
@onready var main_menu: Button = $"ColorRect/HBoxContainer/Main Menu"

const R2 = preload("uid://ra2ia7ghbs2d")
const RT = preload("uid://c17ckp65kqo0s")

const CIRCLE = preload("uid://cp0ax7u42sum1")
const B = preload("uid://crvqtlm3r5fbc")
var paused: bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Multiplayer.use_gamepad:
		if Multiplayer._is_contoller_PS():
			back_to_game.icon = CIRCLE
			main_menu.icon = R2
		else:
			back_to_game.icon = B
			main_menu.icon = RT


	back_to_game.pressed.connect(func():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		self.hide()
		)
	main_menu.pressed.connect(func():
		get_tree().change_scene_to_file("res://Scenes/3dmain_menu.tscn"))

func _input(event: InputEvent) -> void:
	if Multiplayer.use_gamepad:
		if event.is_action_pressed("back_to_game"):
			self.visible = !self.visible
			
		if event.is_action_pressed("enter_game") and self.visible: 
			get_tree().change_scene_to_file("res://Scenes/3dmain_menu.tscn")
		
	else:
		if event.is_action_pressed("pause"):
			self.visible = !self.visible
			
		if self.visible:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
