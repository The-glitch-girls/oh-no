extends Node2D

const SHIELD_SCENE: PackedScene = preload("res://scenes/components/shield.tscn")

const LEVEL_SETTINGS: Dictionary = {
	1: {"duration": 20.0, "shield_speed": 180.0, "player_speed": 400.0 },
	2: {"duration": 15.0, "shield_speed": 300.0, "player_speed": 300.0 },
	3: {"duration": 10.0, "shield_speed": 430.0, "player_speed": 200.0 }
}

@export_range(1,3) var level: int = 1 

const MAX_SHIELDS: int = 15

@onready var player: CharacterBody2D = $Player
@onready var spawn_timer: Timer = $SpawnTimer
@onready var round_timer: Timer = $RoundTimer
@onready var time_label: Label = $HUD/TimeLabel

var shields_spawned: int = 0
var shields_caught: int = 0
var round_finished: bool = false

func _ready() -> void:
	var settings: Dictionary = LEVEL_SETTINGS [level]
	
	player.level = level 
	
	round_timer.wait_time = settings["duration"]
	
	spawn_timer.wait_time = 1.0
	
	time_label.text = "%d" % int(round_timer.wait_time)
	spawn_timer.timeout.connect(_spawn_shield)
	round_timer.timeout.connect(_finish_round)
	
	round_timer.start()
	_spawn_shield()
	
func _process(delta: float) -> void:
	if not round_finished:
		time_label.text = "%d" % ceili(round_timer.time_left)
		
	
func _spawn_shield() -> void: 
	if round_finished or shields_spawned >= MAX_SHIELDS:
		spawn_timer.stop()
		return
		
	var shield:= SHIELD_SCENE.instantiate() as Area2D
	var settings: Dictionary = LEVEL_SETTINGS[level]
	
	shield.fall_speed = settings["shield_speed"]
	
	var screen_size: Vector2 = get_viewport_rect().size 
	
	var left_edge: float = player.left_limit
	var right_edge: float = player.right_limit
	
	shield.position = Vector2(
		randf_range(left_edge, right_edge),
		-30.0)
		
	shield.collected.connect(_on_shield_collected)
	add_child(shield)
	
	shields_spawned += 1
	spawn_timer	.start()
	

func _on_shield_collected()-> void:
	if round_finished: return
	
	shields_caught += 1
	
func _finish_round() -> void : 
	if round_finished: return
	
	round_finished = true
	
	spawn_timer.stop()
	
	time_label.text = "0"
	
	for shield in get_children():
		if shield is Area2D and shield.scene_file_path == SHIELD_SCENE.resource_path:
			shield.queue_free()
	
	print("Nivel: ", level)
	print("Escudos atrapados: ", shields_caught, "/", MAX_SHIELDS)
	print ("Resultado: ", get_result_color())
	
func get_result_color() -> String : 
	if shields_caught <= 5:
		return "red"
	elif shields_caught <= 9:
		return "yellow"
	else: 
		return "green"
	
