extends Node2D

@onready var enemigo_sprite = $enemigo
@onready var enemigo_nombre = $enemigo_nombre
@onready var txtMensaje = $txtMensaje

const FILE_PATH = "res://assets/data/niveles.json"
var nivel_data
var nivel_enemigos
var enemigo_actual

func _ready() -> void:
	# Setear variables
	GlobalManager.etapaActual = 1
	GlobalManager.enemigoActual = 0

	# Cargar datos de json
	var data = GameManager.load_json_file(FILE_PATH)
	if data and data["stages"]:
		print("Successfully loaded JSON data")
		nivel_data = data["stages"].filter(func(level): return level["id"] == "escuela")
		nivel_enemigos = nivel_data[0]["characters"]
		enemigo_actual = nivel_enemigos[GlobalManager.enemigoActual]
		_actualizar_enemigo()
		
func _siguiente_enemigo() -> void:
	if GlobalManager.enemigoActual < nivel_enemigos.size():
		GlobalManager.enemigoActual =+ 1
		enemigo_actual = nivel_enemigos[GlobalManager.enemigoActual]

func _actualizar_enemigo() -> void:
	#enemigo_sprite
	#enemigo_nombre
	#txtMensaje = $txtMensaje
	print("nombre: ", enemigo_actual.name)
	print("request: ", enemigo_actual.request)
	print("automatic_thought: ", enemigo_actual.automatic_thought)
	print("automatic_response ", enemigo_actual.automatic_response)
