extends CanvasLayer

@onready var retry_button = get_node_or_null("HBoxContainer/Retry")
@onready var menu_button = $HBoxContainer/MainM



func _on_retry_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()
	if retry_button:
		retry_button.visible = true
	else:
		print("Retry button not found!")
func _on_main_m_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/3dmain_menu.tscn")
