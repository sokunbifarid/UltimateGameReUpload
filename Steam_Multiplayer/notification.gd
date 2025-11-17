extends Node3D

@onready var label_3d: Label3D = $Label3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Multiplayer.connect("notification",got_notification)
	
func got_notification(mesg:String):
	label_3d.text = mesg
