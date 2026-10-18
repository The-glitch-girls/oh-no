extends CharacterBody2D

@export var level: int = 1 
@export var speed: float = -1.0

@export_group("movement_area")
@export var left_limit: float = 150.0
@export var right_limit: float = 1050.0

const PLAYER_SPEEDS: Dictionary = {
	1: 400.0,
	2: 300.0,
	3: 200.0
}

func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("ui_left","ui_right")
	var current_speed: float = speed if speed >= 0.0 else PLAYER_SPEEDS.get(level,400.0)
	
	velocity.x = direction * current_speed
	velocity.y = 0.0
	
	move_and_slide()
	
	var screen_width := get_viewport_rect().size.x
	position.x = clampf(position.x,left_limit,right_limit)
