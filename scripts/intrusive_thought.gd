
extends Area2D

signal hit_player

@export var fall_speed: float = 180.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	position.y += fall_speed * delta

	if global_position.y >= get_viewport_rect().size.y:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		hit_player.emit()
		queue_free()
