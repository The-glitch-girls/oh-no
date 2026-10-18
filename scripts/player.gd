extends CharacterBody2D

@export var speed: float = 400.0

@export_group("movement_area")
@export var left_limit: float = 150.0
@export var right_limit: float = 1050.0

func _physics_process(_delta: float) -> void:
	var direction := Input.get_axis("ui_left","ui_right")
	
	velocity.x = direction * speed
	velocity.y = 0.0
	
	move_and_slide()
	
	position.x = clampf(position.x,left_limit,right_limit)
