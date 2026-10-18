extends Node2D

const SHIELD_SCENE: PackedScene = preload("res://scenes/components/Shield.tscn")
const THOUGHT_SCENE: PackedScene = preload("res://scenes/components/IntrusiveThought.tscn")

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

@onready var msx_player: AudioStreamPlayer2D = $AudioMinijuego

var shields_spawned: int = 0
var thoughts_spawned: int = 0

var shields_caught: int = 0
var thoughts_caught: int = 0

var falling_objects: Array[Area2D] = []
var round_finished: bool = false
var finish_reason: String = ""
var level_settings: Dictionary = {}
var screen_color_name: String = ""
var screen_color_tween: Tween


func _ready() -> void:
	level_settings = GlobalManager.obtener_config_minijuego()
	player.speed = float(level_settings["player_speed"])

	round_timer.wait_time = float(level_settings["duration"])
	spawn_timer.wait_time = float(level_settings["duration"]) / _total_objects()

	time_label.text = _format_time(round_timer.wait_time)

	end_overlay.hide()
	result_bar.hide()
	timeout_banner.hide()

	multiply_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	multiply_rect.modulate.a = 0.0
	tint_rect.modulate.a = 0.0
	screen_color_name = ""

	if not spawn_timer.timeout.is_connected(_spawn_object):
		spawn_timer.timeout.connect(_spawn_object)

	if not round_timer.timeout.is_connected(_on_time_finished):
		round_timer.timeout.connect(_on_time_finished)

	round_timer.start()
	msx_player.play()
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

	if shields_spawned >= GlobalManager.CANTIDAD_ESCUDOS \
	and thoughts_spawned >= GlobalManager.CANTIDAD_PENSAMIENTOS:
		spawn_timer.stop()
		return

	var spawn_shield: bool

	if shields_spawned >= GlobalManager.CANTIDAD_ESCUDOS:
		spawn_shield = false
	elif thoughts_spawned >= GlobalManager.CANTIDAD_PENSAMIENTOS:
		spawn_shield = true
	else:
		spawn_shield = randf() < 0.6

	var falling_object: Area2D

	if spawn_shield:
		falling_object = SHIELD_SCENE.instantiate() as Area2D
		falling_object.set("fall_speed", float(level_settings["shield_speed"]))
		falling_object.collected.connect(_on_shield_collected)
		shields_spawned += 1
	else:
		falling_object = THOUGHT_SCENE.instantiate() as Area2D
		falling_object.set("fall_speed", float(level_settings["thought_speed"]))
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

	if shields_caught >= GlobalManager.META_ESCUDOS:
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
	GlobalManager.pensamientosAtrapados = thoughts_caught
	# Resultado según los escudos obtenidos
	GlobalManager.colorResultadoMinijuego = get_result_color()
	
	# Convertir el color en una respuesta narrativa
	GlobalManager.respuestaSeleccionada = (
		GlobalManager.respuesta_por_color(
			GlobalManager.colorResultadoMinijuego
		)
	)
	
	# Indicar que el minijuego terminó
	GlobalManager.minijuegoCompletado = true

	spawn_timer.stop()
	round_timer.stop()

	if reason == "timeout":
		time_label.text = "00:00"

	for falling_object in falling_objects:
		if is_instance_valid(falling_object):
			falling_object.queue_free()

	falling_objects.clear()

	print("Nivel: ", GlobalManager.nivelMinijuegoActual)
	print("Motivo del final: ", finish_reason)
	print("Escudos netos: ", shields_caught)
	print("Pensamientos atrapados: ", thoughts_caught)
	print("Resultado: ", get_result_color())
	
	msx_player.stop()
	_play_end_sequence()


func get_result_color() -> String:
	return GlobalManager.color_para_escudos(shields_caught)


func _total_objects() -> int:
	return GlobalManager.CANTIDAD_ESCUDOS + GlobalManager.CANTIDAD_PENSAMIENTOS


func _play_end_sequence() -> void:
	end_overlay.show()
	result_bar.hide()
	timeout_banner.hide()

	var effect_color_name: String

	if finish_reason == "timeout":
		effect_color_name = "blue"
	else:
		effect_color_name = get_result_color()

	multiply_rect.color = GlobalManager.COLORES_RESULTADO[effect_color_name]
	tint_rect.color = GlobalManager.COLORES_RESULTADO[effect_color_name]
	multiply_rect.modulate.a = 0.0
	tint_rect.modulate.a = 0.0

	if finish_reason == "timeout":
		timeout_label.text = "¡Se acabó el tiempo!"
		timeout_banner.modulate.a = 0.0
		timeout_banner.show()
		var timeout_intro_tween: Tween = create_tween()
		timeout_intro_tween.tween_property(
			multiply_rect,
			"modulate:a",
			1.0,
			0.65
		)
		timeout_intro_tween.parallel().tween_property(
			timeout_banner,
			"modulate:a",
			1.0,
			0.25
		)
		await timeout_intro_tween.finished
		await get_tree().create_timer(4.0).timeout

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
		await get_tree().create_timer(2.0).timeout
	else:
		var result_intro_tween: Tween = create_tween()
		result_intro_tween.tween_property(
			multiply_rect,
			"modulate:a",
			1.0,
			0.65
		)
		result_intro_tween.parallel().tween_property(
			tint_rect,
			"modulate:a",
			0.5,
			0.65
		)
		result_intro_tween.tween_interval(1.0)
		result_intro_tween.tween_property(
			multiply_rect,
			"modulate:a",
			0.0,
			0.8
		)
		result_intro_tween.parallel().tween_property(
			tint_rect,
			"modulate:a",
			0.0,
			0.8
		)
		await result_intro_tween.finished

	if not is_inside_tree():
		return

	await _animate_result_indicator()
	
	# Volver a la escena del nivel
	if not is_inside_tree():
		return

	await get_tree().create_timer(1.0).timeout

	if not is_inside_tree():
		return

	get_tree().change_scene_to_file(
		"res://scenes/levels/nivel1_colegio.tscn"
	)


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
		- (float(shields_caught) / float(GlobalManager.META_ESCUDOS))
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
		2.4
	)
	indicator_tween.parallel().tween_method(
		_update_color_while_indicator_moves,
		0.0,
		float(shields_caught),
		2.4
	)
	await indicator_tween.finished

	_update_color_while_indicator_moves(float(shields_caught))
	if screen_color_tween != null and screen_color_tween.is_running():
		await screen_color_tween.finished


func _update_color_while_indicator_moves(progress_score: float) -> void:
	var color_name: String = GlobalManager.color_para_escudos(progress_score)
	if color_name == screen_color_name:
		return

	if screen_color_tween != null and screen_color_tween.is_running():
		screen_color_tween.kill()

	screen_color_name = color_name
	var screen_color: Color = GlobalManager.COLORES_RESULTADO[color_name]
	multiply_rect.modulate.a = 1.0
	tint_rect.modulate.a = 0.5
	screen_color_tween = create_tween()
	screen_color_tween.tween_property(
		multiply_rect,
		"color",
		screen_color,
		0.2
	)
	screen_color_tween.parallel().tween_property(
		tint_rect,
		"color",
		screen_color,
		0.2
	)
