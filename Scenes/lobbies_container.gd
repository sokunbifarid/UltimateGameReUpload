extends Node3D
@export var scroll_speed: float = 0.5  # Adjust this value to control scroll sensitivity

func _input(event):
	if event is InputEventMouseButton:
		# Scroll up (wheel up)
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			global_position.y += scroll_speed
		
		# Scroll down (wheel down)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			global_position.y -= scroll_speed

func _add_functionality():
	for box in get_children():
		var area3D: Area3D = box.get_node("Area3D")
		area3D.mouse_entered.connect(_on_mouse_entered.bind(area3D))
		area3D.mouse_exited.connect(_on_mouse_exited.bind(area3D))
		


func _on_mouse_entered(area3d):
	var box = area3d.get_parent()
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(box, "scale", Vector3(1.5, 1.5, 1.5), 0.3)

func _on_mouse_exited(area3d):
	var box = area3d.get_parent()
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(box, "scale", Vector3(1.0, 1.0, 1.0), 0.3)
