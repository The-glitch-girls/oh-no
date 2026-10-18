extends Control

@onready var txtIntro: RichTextLabel = $txtIntro
@onready var logoContainer: Control = $Container
@onready var animation_player: AnimationPlayer = $txtIntroAnimation
@onready var sfxEscribir: AudioStreamPlayer = $SfxEscribir

func _ready() -> void:
	logoContainer.visible = true
	txtIntro.visible = false
	$txtIntroAnimation.stop()
	sfxEscribir.stop()
	
func _on_btn_jugar_pressed() -> void:
	logoContainer.visible = false
	$btnJugar.visible = false
	txtIntro.visible = true
	reproducir_y_esperar()

func reproducir_y_esperar() -> void:
	animation_player.play()
	await animation_player.animation_finished
	print("¡La animación ha terminado!")
	get_tree().change_scene_to_file("res://scenes/levels/nivel1_colegio.tscn")
