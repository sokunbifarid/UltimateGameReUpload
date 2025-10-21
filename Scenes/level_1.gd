extends Node3D

@onready var label: Label = $Label

@onready var player: CharacterBody3D = $Player


func _ready() -> void:
	print(player.global_position)

func _process(delta: float) -> void:
	label.text =  str(player.global_position)
