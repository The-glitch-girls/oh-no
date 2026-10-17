
extends Node2D

const SHIELD_SCENE: PackedScene = preload("res://scenes/components/Shield.tscn")
const THOUGHT_SCENE: PackedScene = preload("res://scenes/components/IntrusiveThought.tscn")

const SHIELD_COUNT: int = 15
const THOUGHT_COUNT: int = 10
const TOTAL_OBJECTS: int = SHIELD_COUNT + THOUGHT_COUNT

const LEVEL_SETTINGS: Dictionary = {
	1: {
		"duration": 20.0,
		"shield_speed": 180.0,
		"thought_speed": 200.0,
		"player_speed": 400.0
	},
	2: {
		"duration": 15.0,
		"shield_speed": 300.0,
		"thought_speed": 330.0,
		"player_speed": 300.0
	},
	3: {
		"duration": 10.0,
		"shield_speed": 430.0,
		"thought_speed": 470.0,
		"player_speed": 220.0
	}
}

@export_range(1, 3) var level: int = 1

@onready var player: CharacterBody2D = $Player
@onready var spawn_timer: Timer = $SpawnTimer
@onready var round_timer: Timer = $RoundTimer
@onready var time_label: Label = $HUD/TimeLabel

var shields_spawned: int = 0
var thoughts_spawned: int = 0

var shields_caught: int = 0
var thoughts_caught: int = 0

var round_finished: bool = false


func _ready() -> void:
	var settings: Dictionary = LEVEL_SETTINGS[level]

	player.level = level

	round_timer.wait_time = settings["duration"]
	spawn_timer.wait_time = settings["duration"] / TOTAL_OBJECTS

	time_label.text = "Tiempo: %d" % int(round_timer.wait_time)

	spawn_timer.timeout.connect(_spawn_object)
	round_timer.timeout.connect(_finish_round)

	round_timer.start()
	_spawn_object()


func _process(_delta: float) -> void:
	if not round_finished:
		time_label.text = "Tiempo: %d" % ceili(round_timer.time_left)


func _spawn_object() -> void:
	if round_finished:
		spawn_timer.stop()
		return

	if shields_spawned >= SHIELD_COUNT and thoughts_spawned >= THOUGHT_COUNT:
		spawn_timer.stop()
		return

	var spawn_shield: bool

	if shields_spawned >= SHIELD_COUNT:
		spawn_shield = false
	elif thoughts_spawned >= THOUGHT_COUNT:
		spawn_shield = true
	else:
		spawn_shield = randf() < 0.6

	var settings: Dictionary = LEVEL_SETTINGS[level]
	var falling_object: Area2D

	if spawn_shield:
		falling_object = SHIELD_SCENE.instantiate() as Area2D
		falling_object.fall_speed = settings["shield_speed"]
		falling_object.collected.connect(_on_shield_collected)
		shields_spawned += 1
	else:
		falling_object = THOUGHT_SCENE.instantiate() as Area2D
		falling_object.fall_speed = settings["thought_speed"]
		falling_object.hit_player.connect(_on_thought_caught)
		thoughts_spawned += 1

	var screen_size: Vector2 = get_viewport_rect().size

	falling_object.position = Vector2(
		randf_range(player.left_limit, player.right_limit),
		-30.0
	)

	add_child(falling_object)

	spawn_timer.start()


func _on_shield_collected() -> void:
	if round_finished:
		return

	shields_caught += 1


func _on_thought_caught() -> void:
	if round_finished:
		return

	thoughts_caught += 1
	shields_caught = maxi(0, shields_caught - 1)


func _finish_round() -> void:
	if round_finished:
		return

	round_finished = true
	spawn_timer.stop()

	time_label.text = "Tiempo: 0"

	for falling_object in get_children():
		if falling_object is Area2D:
			if falling_object.scene_file_path == SHIELD_SCENE.resource_path:
				falling_object.queue_free()
			elif falling_object.scene_file_path == THOUGHT_SCENE.resource_path:
				falling_object.queue_free()

	print("Nivel: ", level)
	print("Escudos atrapados: ", shields_caught)
	print("Pensamientos atrapados: ", thoughts_caught)
	print("Resultado: ", get_result_color())


func get_result_color() -> String:
	if shields_caught <= 5:
		return "red"
	elif shields_caught <= 9:
		return "yellow"
	else:
		return "green"
