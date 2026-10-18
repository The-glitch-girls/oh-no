extends Node2D

@onready var enemigo_sprite = $enemigo
@onready var enemigo_pastilla = $enemigo_nombre
@onready var enemigo_label = $enemigo_nombre/en_label
@onready var jugador_sprite = $jugador
@onready var jugador_nombre = $jugador_nombre
@onready var txtMensaje = $txtMensaje
@onready var flecha_siguiente = $flecha_siguiente
@onready var burbuja_pensamiento = $burbuja_pensamiento
@onready var txtPensamiento = $burbuja_pensamiento/txtPensamiento
@onready var btnMinijuego = $btnMinijuego

const FILE_PATH = "res://assets/data/niveles.json"
const VELOCIDAD_ESCRITURA = 0.035

var nivel_data
var nivel_enemigos
var enemigo_actual
var solicitud_arr_actual: Array = []
var indice_solicitud: int = 0
var escribiendo: bool = false

func _ready() -> void:
	# Setear variables
	GlobalManager.etapaActual = 1
	GlobalManager.enemigoActual = 0
	flecha_siguiente.hide()
	flecha_siguiente.pressed.connect(_al_presionar_flecha)
	jugador_sprite.hide()
	jugador_nombre.hide()
	burbuja_pensamiento.hide()
	
	# Cargar datos de json
	var data = GameManager.load_json_file(FILE_PATH)
	
	if data and data.has("stages"):
		print("Successfully loaded JSON data")
		nivel_data = data["stages"].filter(
			func(level):
				return level["id"] == "escuela"
		)

		if nivel_data.is_empty():
			push_error("No se encontró la etapa escuela")
			return

		nivel_enemigos = nivel_data[0]["characters"]

		if nivel_enemigos.is_empty():
			push_error("La etapa no tiene personajes")
			return

		enemigo_actual = nivel_enemigos[
			GlobalManager.enemigoActual
		]
		
		_actualizar_enemigo()
		
		
func _siguiente_enemigo() -> void:
	if GlobalManager.enemigoActual < nivel_enemigos.size():
		GlobalManager.enemigoActual =+ 1
		enemigo_actual = nivel_enemigos[GlobalManager.enemigoActual]
		_actualizar_enemigo()

func _actualizar_enemigo() -> void:
	# Reiniciar el diálogo del enemigo actual.
	indice_solicitud = 0
	solicitud_arr_actual = enemigo_actual.get("request", [])
	enemigo_sprite.show()
	enemigo_label.show()
	txtMensaje.show()
	jugador_sprite.hide()
	jugador_nombre.hide()
	burbuja_pensamiento.hide()
	flecha_siguiente.hide()
	
	enemigo_label.text = str(enemigo_actual.get("name", ""))
	if solicitud_arr_actual.is_empty():
		_mostrar_jugador()
		return
		
	_mostrar_solicitud()
	
	
	txtMensaje.text = enemigo_actual.request[0]
		
	if solicitud_arr_actual.size() > 1:
		print("mostrar flecha")
	

func _mostrar_solicitud() -> void:
	if indice_solicitud >= solicitud_arr_actual.size():
		_mostrar_jugador()
		return

	flecha_siguiente.hide()

	await _escribir_texto_rich(
		txtMensaje,
		str(solicitud_arr_actual[indice_solicitud])
	)

	# Si hay más mensajes, esperamos que pulsen la flecha.
	if indice_solicitud < solicitud_arr_actual.size() - 1:
		flecha_siguiente.show()
	else:
		# Terminó la solicitud: mostrar el pensamiento del jugador.
		await get_tree().create_timer(1.5).timeout
		await _mostrar_jugador()

func _al_presionar_flecha() -> void:
	if escribiendo:
		return

	if indice_solicitud < solicitud_arr_actual.size() - 1:
		indice_solicitud += 1
		_mostrar_solicitud()


func _mostrar_jugador() -> void:
	flecha_siguiente.hide()
	txtMensaje.text = ""
	txtPensamiento.text = ""

	# Ocultar al enemigo y sus elementos de diálogo.
	enemigo_sprite.hide()
	enemigo_label.hide()

	# Mostrar al jugador y su pensamiento.
	jugador_sprite.show()
	jugador_nombre.show()
	burbuja_pensamiento.show()

	await _escribir_texto(
		txtPensamiento,
		str(enemigo_actual.get("automatic_thought", ""))
	)
	
	# Esperar un segundo.
	await get_tree().create_timer(1.0).timeout

	# Mostrar la burbuja inferior y escribir la respuesta.
	txtMensaje.show()
	txtMensaje.text = ""
	txtMensaje.visible_characters = -1

	await _escribir_texto_rich(
		txtMensaje,
		str(enemigo_actual.get("automatic_response", ""))
	)
	
	# Esperar un segundo.
	await get_tree().create_timer(1.0).timeout
	
	btnMinijuego.visible = true


func _escribir_texto(label: Label, mensaje: String) -> void:
	escribiendo = true
	label.text = ""

	for i in range(mensaje.length()):
		label.text = mensaje.substr(0, i + 1)
		await get_tree().create_timer(
			VELOCIDAD_ESCRITURA
		).timeout

	escribiendo = false


func _escribir_texto_rich(label: RichTextLabel, mensaje: String) -> void:
	escribiendo = true
	label.text = ""
	label.visible_characters = 0
	label.text = mensaje

	for i in range(mensaje.length()):
		label.visible_characters = i + 1
		await get_tree().create_timer(
			VELOCIDAD_ESCRITURA
		).timeout

	label.visible_characters = -1
	escribiendo = false


func _on_btn_minijuego_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MiniGame.tscn")
