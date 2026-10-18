extends Node

# Minijuego
const MINIJUEGO_CONFIG: Dictionary = {
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

const ESCUDOS_POR_COLOR: Dictionary = {
	"blue": 5,
	"purple": 10
}

const COLORES_RESULTADO: Dictionary = {
	"blue": Color("#83BFFF"),
	"purple": Color("#B69AEF"),
	"pink": Color("#FF91C8")
}

const CANTIDAD_ESCUDOS: int = 20
const CANTIDAD_PENSAMIENTOS: int = 10
const META_ESCUDOS: int = 15

var nivelMinijuegoActual: int = 1

# Niveles y dialogo
var datosJuego: Dictionary = {}
var etapaActual = 0;
var enemigoActual = 0;

# HUD
var autoestima = 20;
var tiempoRestante = 120;

# Minijuego
var escudosRecogidos = 0;

var motivoFinalMinijuego = "";
var colorResultadoMinijuego = "blue";
var pensamientosAtrapados = 0;

# Progreso narrativo
var etapaActualId: String = "escuela"
var personajeActualId: String = "enemigo_01"

# Resultado del minijuego
var respuestaSeleccionada: String = ""
var minijuegoCompletado: bool = false

# Datos cargados desde el JSON
var nivel_data: Dictionary = {}

func obtener_config_minijuego() -> Dictionary:
	if not MINIJUEGO_CONFIG.has(nivelMinijuegoActual):
		push_error("Nivel de minijuego no válido: %s" % nivelMinijuegoActual)
		return MINIJUEGO_CONFIG[1].duplicate()
	return MINIJUEGO_CONFIG[nivelMinijuegoActual].duplicate()


func color_para_escudos(cantidad: float) -> String:
	if cantidad <= ESCUDOS_POR_COLOR["blue"]:
		return "blue"
	if cantidad <= ESCUDOS_POR_COLOR["purple"]:
		return "purple"
	return "pink"
	
func respuesta_por_color(color: String) -> String:
	match color:
		"blue":
			return "accept"
		"pink":
			return "refuse"
		"purple":
			return "negotiate"
		_:
			return ""
			
# Dialogo interactivo
func obtener_personaje_actual() -> Dictionary:
	var etapas: Array = datosJuego.get("stages", [])
	
	for etapa in etapas:
		if etapa.get("id", "") != etapaActualId:
			continue

		var personajes: Array = etapa.get("characters", [])

		for personaje in personajes:
			if personaje.get("id", "") == personajeActualId:
				return personaje
				
	push_warning(
		"No se encontró el personaje: "
		+ personajeActualId
		+ " en la etapa "
		+ etapaActualId
	)

	return {}
	
func obtener_respuesta_actual() -> Dictionary:
	var personaje := obtener_personaje_actual()
	var minijuego: Dictionary = personaje.get("minigame", {})

	for respuesta in minijuego.get("responses", []):
		if respuesta.get("id", "") == respuestaSeleccionada:
			return respuesta

	return {}

func obtener_consecuencias_actuales() -> Dictionary:
	var personaje := obtener_personaje_actual()
	var consecuencias: Dictionary = personaje.get(
		"consequences", {}
	)

	return consecuencias.get(respuestaSeleccionada, {})
