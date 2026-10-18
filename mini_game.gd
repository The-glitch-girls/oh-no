extends Node2D

const SHIELD_SCENE: PackedScene = preload("res://scenes/components/Shield.tscn")
const THOUGHT_SCENE: PackedScene = preload("res://scenes/components/IntrusiveThought.tscn")

const SHIELD_COUNT: int = 20
const THOUGHT_COUNT: int = 10
const TOTAL_OBJECTS: int = SHIELD_COUNT + THOUGHT_COUNT
const TARGET_SCORE: int = 15

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

const RESULT_COLORS: Dictionary = {
	"blue": Color("#83BFFF"),
	"purple": Color("#B69AEF"),
	"pink": Color("#FF91C8")
}

@export_range(1, 3) var level: int = 1

@onready var player: CharacterBody2D = $Player
@onready var spawn_timer: Timer = $SpawnTimer
@onready var round_timer: Timer = $RoundTimer

@onready var time_label: Label = $HUD/TimeContainer/TimeLabel

@onready var end_overlay: Control = $HUD/EndOverlay
@onready var multiply_rect: ColorRect = $HUD/EndOverlay/MultiplyRect
@onready var tint_rect: ColorRect = $HUD/EndOverlay/TintRect
@onready var timeout_banner: TextureRect = $HUD/EndOverlay/TimeOutBanner
@onready var timeout_label: Label = $HUD/EndOverlay/TimeOutBanner/TimeOutLabel

@onready var result_bar: Control = $HUD/ResultBar
@onready var bar_background: TextureRect = $HUD/ResultBar/BarBackground
@onready var bar_indicator: TextureRect = $HUD/ResultBar/BarIndicator

var shields_spawned: int = 0
var thoughts_spawned: int = 0

var shields_caught: int = 0
var thoughts_caught: int = 0

var falling_objects: Array[Area2D] = []
var round_finished: bool = false
var finish_reason: String = ""


func _ready() -> void:
	if not LEVEL_SETTINGS.has(level):
		push_error("Nivel no válido: %s" % level)
		return

	var settings: Dictionary = LEVEL_SETTINGS[level]

	player.level = level
	player.set("speed", float(settings["player_speed"]))

	round_timer.wait_time = float(settings["duration"])
	spawn_timer.wait_time = float(settings["duration"]) / TOTAL_OBJECTS

	time_label.text = _format_time(round_timer.wait_time)

	end_overlay.hide()
	result_bar.hide()
	timeout_banner.hide()

	multiply_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	multiply_rect.modulate.a = 0.0
	tint_rect.modulate.a = 0.0

	if not spawn_timer.timeout.is_connected(_spawn_object):
		spawn_timer.timeout.connect(_spawn_object)

	if not round_timer.timeout.is_connected(_on_time_finished):
		round_timer.timeout.connect(_on_time_finished)

	round_timer.start()
	_spawn_object()


func _process(_delta: float) -> void:
	if not round_finished:
		time_label.text = _format_time(round_timer.time_left)


func _format_time(seconds_left: float) -> String:
	var total_seconds: int = ceili(seconds_left)
	var minutes: int = int(total_seconds / 60.0)
	var seconds: int = total_seconds % 60

	return "%02d:%02d" % [minutes, seconds]


func _spawn_object() -> void:
	if round_finished:
		spawn_timer.stop()
		return

	if shields_spawned >= SHIELD_COUNT \
	and thoughts_spawned >= THOUGHT_COUNT:
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
		falling_object.set("fall_speed", float(settings["shield_speed"]))
		falling_object.collected.connect(_on_shield_collected)
		shields_spawned += 1
	else:
		falling_object = THOUGHT_SCENE.instantiate() as Area2D
		falling_object.set("fall_speed", float(settings["thought_speed"]))
		falling_object.hit_player.connect(_on_thought_caught)
		thoughts_spawned += 1

	falling_object.position = Vector2(
		randf_range(player.left_limit, player.right_limit),
		-30.0
	)

	add_child(falling_object)
	falling_objects.append(falling_object)

	spawn_timer.start()


func _on_shield_collected() -> void:
	if round_finished:
		return

	shields_caught += 1

	if shields_caught >= TARGET_SCORE:
		_finish_round("score")


func _on_thought_caught() -> void:
	if round_finished:
		return

	thoughts_caught += 1
	shields_caught = maxi(0, shields_caught - 1)


func _on_time_finished() -> void:
	_finish_round("timeout")


func _finish_round(reason: String) -> void:
	if round_finished:
		return

	round_finished = true
	finish_reason = reason
	GlobalManager.escudosRecogidos = shields_caught
	GlobalManager.motivoFinalMinijuego = finish_reason
	GlobalManager.colorResultadoMinijuego = get_result_color()

	spawn_timer.stop()
	round_timer.stop()

	if reason == "timeout":
		time_label.text = "00:00"

	for falling_object in falling_objects:
		if is_instance_valid(falling_object):
			falling_object.queue_free()

	falling_objects.clear()

	print("Nivel: ", level)
	print("Motivo del final: ", finish_reason)
	print("Escudos netos: ", shields_caught)
	print("Pensamientos atrapados: ", thoughts_caught)
	print("Resultado: ", get_result_color())

	_play_end_sequence()


func get_result_color() -> String:
	if shields_caught <= 5:
		return "blue"
	elif shields_caught <= 10:
		return "purple"
	else:
		return "pink"


func _play_end_sequence() -> void:
	end_overlay.show()
	result_bar.hide()
	timeout_banner.hide()


	var effect_color_name: String

	if finish_reason == "timeout":
		effect_color_name = "blue"
	else:
		effect_color_name = get_result_color()

	multiply_rect.color = RESULT_COLORS[effect_color_name]
	tint_rect.color = RESULT_COLORS[effect_color_name]
	multiply_rect.modulate.a = 0.0
	tint_rect.modulate.a = 0.0
	var use_tint_rect: bool = finish_reason != "timeout"


	var color_tween: Tween = create_tween()
	color_tween.tween_property(
		multiply_rect,
		"modulate:a",
		1.0,
		0.65
	)
	if use_tint_rect:
		color_tween.parallel().tween_property(
			tint_rect,
			"modulate:a",
			0.5,
			0.65
		)
	color_tween.tween_interval(1.0)
	color_tween.tween_property(
		multiply_rect,
		"modulate:a",
		0.0,
		0.8
	)
	if use_tint_rect:
		color_tween.parallel().tween_property(
			tint_rect,
			"modulate:a",
			0.0,
			0.8
		)

	await color_tween.finished

	if not is_inside_tree():
		return

	if finish_reason == "timeout":
		timeout_label.text = "¡Se acabó el tiempo!"
		timeout_banner.modulate.a = 0.0
		timeout_banner.show()
		var banner_in_tween: Tween = create_tween()
		banner_in_tween.tween_property(
			timeout_banner,
			"modulate:a",
			1.0,
			0.25
		)
		await banner_in_tween.finished

		await get_tree().create_timer(0.65).timeout

		if not is_inside_tree():
			return

		var banner_out_tween: Tween = create_tween()
		banner_out_tween.tween_property(
			timeout_banner,
			"modulate:a",
			0.0,
			0.35
		)
		await banner_out_tween.finished
		timeout_banner.hide()


	_animate_result_indicator()


func _animate_result_indicator() -> void:
	result_bar.show()

	var bar_top: float = bar_background.position.y
	var bar_bottom: float = bar_top + bar_background.size.y

	var indicator_x: float = (
		bar_background.position.x
		+ (bar_background.size.x - bar_indicator.size.x) / 2.0
	)

	var indicator_bottom_y: float = (
		bar_bottom - bar_indicator.size.y / 2.0
	)

	var indicator_target_y: float = (
		bar_bottom
		- (float(shields_caught) / float(TARGET_SCORE))
		* bar_background.size.y
		- bar_indicator.size.y / 2.0
	)

	indicator_target_y = clampf(
		indicator_target_y,
		bar_top,
		bar_bottom - bar_indicator.size.y
	)

	bar_indicator.position = Vector2(
		indicator_x,
		indicator_bottom_y
	)

	var indicator_tween: Tween = create_tween()
	indicator_tween.set_trans(Tween.TRANS_CUBIC)
	indicator_tween.set_ease(Tween.EASE_OUT)

	indicator_tween.tween_property(
		bar_indicator,
		"position:y",
		indicator_target_y,
		0.65
	)
	await indicator_tween.finished

	# El color final corresponde a la zona donde termina el indicador.
	var final_color: Color = RESULT_COLORS[get_result_color()]
	multiply_rect.color = final_color
	tint_rect.color = final_color
	multiply_rect.modulate.a = 0.0
	tint_rect.modulate.a = 0.0
	var final_color_tween: Tween = create_tween()
	final_color_tween.tween_property(
		multiply_rect,
		"modulate:a",
		1.0,
		0.4
	)
	final_color_tween.parallel().tween_property(
		tint_rect,
		"modulate:a",
		0.5,
		0.4
	)
