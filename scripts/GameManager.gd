extends Node

func _ready() -> void:
	pass
	
func resetar_variables() -> void:
		GlobalManager.etapaActual = 0
		GlobalManager.enemigoActual = 0
		GlobalManager.autoestima = 20
		GlobalManager.tiempoRestante = 120
		GlobalManager.escudosRecogidos = 0
		GlobalManager.respuestaSeleccionada = null
		GlobalManager.motivoFinalMinijuego = ""
		GlobalManager.colorResultadoMinijuego = "blue"
		
func load_json_file(path: String):
	# 1. Check if the file exists
	if not FileAccess.file_exists(path):
		print("Error: File does not exist at ", path)
		return null
	
	# 2. Open the file in READ mode
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		print("Error: Could not open file at ", path)
		return null
		
	# 3. Read the entire content as a text string
	var json_text = file.get_as_text()
	file.close() # Always close the file when done
	
	# 4. Parse the text string into a Godot Variant (Dictionary or Array)
	var parsed_data = JSON.parse_string(json_text)
	
	if parsed_data == null:
		print("Error: Failed to parse JSON string.")
		return null
		
	return parsed_data
