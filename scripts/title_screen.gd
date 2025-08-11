extends Control

func _ready() -> void:
	pass
	
func _process(delta):
	pass
	
		
	

func _on_start_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://phases/phase_1/phase_1.tscn")


func _on_credits_btn_pressed() -> void:
	pass # Replace with function body.


func _on_quit_btn_pressed() -> void:
	get_tree().quit()
