extends Node2D

@onready var btnCreditos = $btnCreditos

func _ready():
	await get_tree().create_timer(1.0).timeout
	btnCreditos.visible = true

func _on_btn_creditos_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Creditos.tscn")
