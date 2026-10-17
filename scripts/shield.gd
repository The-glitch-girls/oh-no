extends Area2D

signal collected

@export var fall_speed: float = 180.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	position.y += fall_speed * delta
	
	var screen_height := get_viewport_rect().size.y
	
	if position.y >= screen_height:
		queue_free()


func _on_body_entered(body: Node2D) -> void :
	if body.name == "Player":
		collected.emit()
		queue_free()
	
