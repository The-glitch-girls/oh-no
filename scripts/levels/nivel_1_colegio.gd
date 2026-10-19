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
@onready var btnSgteEnemigo = $btnSgteEnemigo
@onready var autoestima_fondo: TextureRect = $HUD/AutoestimaBarra/AutoestimaFondo
@onready var relleno_clip: Control = $HUD/AutoestimaBarra/RellenoClip
@onready var autoestima_relleno: TextureRect = $HUD/AutoestimaBarra/RellenoClip/AutoestimaRelleno
@onready var msx_player: AudioStreamPlayer2D = $AudioNovela
@onready var transition_overlay: ColorRect = $HUD/TransitionOverlay
@onready var transition_material: ShaderMaterial = (
	transition_overlay.material as ShaderMaterial
)

@onready var transition_overlay_blue: ColorRect = $HUD/TransitionOverlayBlue
@onready var transition_material_blue: ShaderMaterial = (
	transition_overlay_blue.material as ShaderMaterial
)

const FILE_PATH = "res://assets/data/niveles.json"
const VELOCIDAD_ESCRITURA = 0.035

var nivel_data
var nivel_enemigos
var enemigo_actual
var solicitud_arr_actual: Array = []
var indice_solicitud: int = 0
var escribiendo: bool = false
var tween_autoestima: Tween

# Resultado del minijuego
var respuesta_textos: Array = []
var reacciones_enemigo: Array = []

# Control del diálogo posterior al minijuego
var tipo_dialogo: String = "solicitud"
var indice_dialogo: int = 0

func _ready() -> void:
	print("ready fue llamado")
	msx_player.play()
	flecha_siguiente.hide()
	flecha_siguiente.pressed.connect(_al_presionar_flecha)
	flecha_siguiente.button_down.connect(GameManager.play_button_pressed_sound)
	btnMinijuego.button_down.connect(GameManager.play_button_pressed_sound)
	btnSgteEnemigo.button_down.connect(GameManager.play_button_pressed_sound)
	jugador_sprite.hide()
	jugador_nombre.hide()
	burbuja_pensamiento.hide()
	_actualizar_barra_autoestima()
	
	# Cargar el JSON antes de procesar el resultado.
	var data = GameManager.load_json_file(FILE_PATH)
	if data and data.has("stages"):
		print("Successfully loaded JSON data")

		# Guardar el JSON completo para consultarlo desde GlobalManager.
		GlobalManager.datosJuego = data

		# Obtener la etapa escuela.
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

		# Si regresamos del minijuego, procesar el resultado.
		if GlobalManager.minijuegoCompletado:
			transition_overlay.show()
			transition_material.set_shader_parameter("iris_radius", 0.0)
			var iris_open_tween: Tween = create_tween()
			iris_open_tween.tween_property(
				transition_material,
				"shader_parameter/iris_radius",
				1.2,
				0.7
			)
			iris_open_tween.finished.connect(transition_overlay.hide)

			GlobalManager.etapaActualId = "escuela"

			enemigo_actual = nivel_enemigos[
				GlobalManager.enemigoActual
			]

			procesar_resultado_minijuego()
			return

		# Si es una partida nueva, mostrar al primer enemigo.
		GlobalManager.etapaActual = 1
		GlobalManager.enemigoActual = 0
		GlobalManager.etapaActualId = "escuela"
		GlobalManager.personajeActualId = "enemigo_01"

		enemigo_actual = nivel_enemigos[
			GlobalManager.enemigoActual
		]

		_actualizar_enemigo()
	else:
		push_error("No se pudo cargar niveles.json")

	
		
func _siguiente_enemigo() -> void:
	print("CARGANDO SIGGUIENTE ENEMIGO ... ")
	btnSgteEnemigo.hide()
	var siguiente_indice: int = GlobalManager.enemigoActual + 1
	
	if siguiente_indice >= nivel_enemigos.size():
		await _mostrar_transicion()
		_siguiente_nivel()
		return
	
	await _mostrar_transicion()

	GlobalManager.enemigoActual = siguiente_indice
	enemigo_actual = nivel_enemigos[siguiente_indice]
	
	# Actualizar el ID que consulta GlobalManager.
	GlobalManager.personajeActualId = str(
		enemigo_actual.get("id", "")
	)
	
	# Limpiar el resultado anterior del minijuego
	GlobalManager.respuestaSeleccionada = ""
	GlobalManager.minijuegoCompletado = false
	
	tipo_dialogo = "solicitud"
	indice_dialogo = 0
	indice_solicitud = 0
	escribiendo = false
	flecha_siguiente.hide()
	_actualizar_enemigo()

func _transicion_siguiente() -> void:
	
	pass
	
	
func _actualizar_enemigo() -> void:
	print("AZTUALIZANDO ENEMIGO ... ")
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
	
	print("deberia mostrar solicitud")
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
		
	match tipo_dialogo:
		"solicitud":
			if indice_solicitud < solicitud_arr_actual.size() - 1:
				indice_solicitud += 1
				_mostrar_solicitud()
		"respuesta":
			if indice_dialogo < respuesta_textos.size() - 1:
				indice_dialogo += 1

				await _escribir_texto_rich(
					txtMensaje,
					str(respuesta_textos[indice_dialogo])
				)

				if indice_dialogo < respuesta_textos.size() - 1:
					flecha_siguiente.show()
				else:
					await get_tree().create_timer(1.0).timeout
					await _mostrar_reaccion_enemigo()

		"reaccion":
			if indice_dialogo < reacciones_enemigo.size() - 1:
				indice_dialogo += 1
				await _escribir_texto_rich(
					txtMensaje,
					str(reacciones_enemigo[indice_dialogo])
				)
				if indice_dialogo < reacciones_enemigo.size() - 1:
					flecha_siguiente.show()
				else:
					flecha_siguiente.hide()
				
				# WIP 
				await get_tree().create_timer(1.5).timeout
				btnSgteEnemigo.show()

func _mostrar_jugador(pensamiento: String = "", respuesta_inicial: String = "") -> void:
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

	# Si no se reciben textos nuevos, se utilizan los del JSON inicial.
	if pensamiento.is_empty():
		pensamiento = str(
			enemigo_actual.get("automatic_thought", "")
		)
	
	if respuesta_inicial.is_empty():
		respuesta_inicial = str(
			enemigo_actual.get("automatic_response", "")
		)
		
	await _escribir_texto(txtPensamiento, pensamiento)
	
	# Esperar un segundo.
	await get_tree().create_timer(1.0).timeout

	# Mostrar la burbuja inferior y escribir la respuesta.
	txtMensaje.show()
	txtMensaje.text = ""
	txtMensaje.visible_characters = -1
	
	await _escribir_texto_rich(
		txtMensaje,
		respuesta_inicial
	)
	
	# Esperar un segundo.
	await get_tree().create_timer(1.0).timeout
	
	btnMinijuego.visible = true
	btnSgteEnemigo.visible = false


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

func procesar_resultado_minijuego() -> void:
	if not GlobalManager.minijuegoCompletado:
		return

	# Consumir el estado para no procesarlo dos veces.
	GlobalManager.minijuegoCompletado = false
	
	var respuesta: Dictionary = (
		GlobalManager.obtener_respuesta_actual()
	)

	var consecuencias: Dictionary = (
		GlobalManager.obtener_consecuencias_actuales()
	)
	
	if respuesta.is_empty():
		push_error("No se encontró la respuesta narrativa")
		return

	if consecuencias.is_empty():
		push_error("No se encontraron las consecuencias")
		return
	
	# Pensamiento interno de la protagonista.
	var pensamiento: String = respuesta.get("thought", "")

	# Respuestas narrativas de la protagonista.
	var textos: Array = respuesta.get("text", [])
		
	# Reacción del enemigo.
	var reacciones: Array = consecuencias.get(
		"enemy_reaction", []
	)

	# Aplicar consecuencias.
	var cambio_autoestima: int = respuesta.get(
		"self_esteem_change", 0
	)

	var costo_tiempo: int = consecuencias.get(
		"time_cost", 0
	)
	print("Autoestima antes: ", GlobalManager.autoestima)
	
	GlobalManager.autoestima += cambio_autoestima
	print("Cambio aplicado: ", cambio_autoestima)
	print("Autoestima después: ", GlobalManager.autoestima)
	GlobalManager.tiempoRestante -= costo_tiempo
	_actualizar_barra_autoestima()
	
	respuesta_textos = textos
	reacciones_enemigo = reacciones

	await _mostrar_respuesta_minijuego()
	
func _mostrar_respuesta_minijuego() -> void:
	flecha_siguiente.hide()
	btnMinijuego.hide()

	tipo_dialogo = "respuesta"
	indice_dialogo = 0
	
	var nombre_animacion = GlobalManager.respuestaSeleccionada
	jugador_sprite.texture = load("res://assets/sprites/jugador/"+nombre_animacion+".png")
	jugador_sprite.show()
	jugador_nombre.show()
	burbuja_pensamiento.show()

	enemigo_sprite.hide()
	enemigo_label.hide()

	txtPensamiento.text = ""

	var respuesta: Dictionary = (
		GlobalManager.obtener_respuesta_actual()
	)

	await _escribir_texto(
		txtPensamiento,
		str(respuesta.get("thought", ""))
	)

	await get_tree().create_timer(1.0).timeout

	respuesta_textos = respuesta.get("text", [])

	if respuesta_textos.is_empty():
		_mostrar_reaccion_enemigo()
		return

	await _escribir_texto_rich(
		txtMensaje,
		str(respuesta_textos[0])
	)

	if respuesta_textos.size() > 1:
		flecha_siguiente.show()
	else:
		await get_tree().create_timer(1.0).timeout
		_mostrar_reaccion_enemigo()

func _mostrar_reaccion_enemigo() -> void:
	flecha_siguiente.hide()

	tipo_dialogo = "reaccion"
	indice_dialogo = 0

	jugador_sprite.hide()
	jugador_nombre.hide()
	burbuja_pensamiento.hide()

	enemigo_sprite.show()
	enemigo_label.show()
	enemigo_label.text = str(
		enemigo_actual.get("name", "")
	)

	var consecuencias: Dictionary = (
		GlobalManager.obtener_consecuencias_actuales()
	)

	reacciones_enemigo = consecuencias.get(
		"enemy_reaction", []
	)

	if reacciones_enemigo.is_empty():
		return

	await _escribir_texto_rich(
		txtMensaje,
		str(reacciones_enemigo[0])
	)

	if reacciones_enemigo.size() > 1:
		flecha_siguiente.show()
	else:
		flecha_siguiente.hide()	
	

func _actualizar_barra_autoestima() -> void:
	var max_autoestima: float = 80.0
	
	var porcentaje := clampf(
		float(GlobalManager.autoestima) / max_autoestima,
		0.0,
		1.0
	)
	
	var material := (
		$HUD/AutoestimaBarra/RellenoClip/AutoestimaRelleno
		.material as ShaderMaterial
	)
	
	if material == null:
		push_error("AutoestimaRelleno necesita un ShaderMaterial.")
		return

	if tween_autoestima and tween_autoestima.is_running():
		tween_autoestima.kill()

	var progreso_actual: float = material.get_shader_parameter("progress")
	print("Autoestima: ", GlobalManager.autoestima)
	print("Porcentaje objetivo: ", porcentaje)
	print("ShaderMaterial: ", material.resource_path)
	print("Progress antes: ", material.get_shader_parameter("progress"))
	print("Textura del relleno: ", autoestima_relleno.texture.get_size())

	tween_autoestima = create_tween()
	tween_autoestima.set_trans(Tween.TRANS_CUBIC)
	tween_autoestima.set_ease(Tween.EASE_OUT)
	
	tween_autoestima.tween_method(
		func(valor: float) -> void:
			material.set_shader_parameter("progress", valor),
		progreso_actual,
		porcentaje,
		0.6
	)
	
#TODO ir al sgte nivel
func _siguiente_nivel() -> void:
	GlobalManager.etapaActual += 1

	match GlobalManager.etapaActual:
		2:
			get_tree().change_scene_to_file(
				"res://scenes/Final.tscn"
			)
		_:
			print("No hay más niveles implementados.")
			
func _mostrar_transicion() -> void:
	transition_overlay_blue.show()
	transition_material_blue.set_shader_parameter("iris_radius", 0.0)
	var iris_open_tween: Tween = create_tween()
	iris_open_tween.tween_property(
		transition_material_blue,
		"shader_parameter/iris_radius",
		1.2,
		0.7
	)
	iris_open_tween.finished.connect(transition_overlay.hide)
			
func _on_btn_minijuego_pressed() -> void:
	btnMinijuego.disabled = true
	msx_player.stop()
	transition_overlay.show()
	transition_material.set_shader_parameter("iris_radius", 1.2)
	var transition_tween: Tween = create_tween()
	transition_tween.tween_property(
		transition_material,
		"shader_parameter/iris_radius",
		0.0,
		0.7
	)
	await transition_tween.finished
	get_tree().change_scene_to_file("res://scenes/MiniGame.tscn")


func _on_btn_sgte_enemigo_pressed() -> void:
	_siguiente_enemigo()
