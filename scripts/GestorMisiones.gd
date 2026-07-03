extends Node

# Tu tabla global con todas las misiones y carreras del juego
@export var tabla_misiones: Array[Dictionary] = [
	{
		"id": "correra_01",
		"titulo": "Poul Swift",
		"vuelta_total": 3,
		"usuarios": [
			{"id": "1", "user": "rabu", "progreso_vueltas": 0},
		]
	},
	{
		"id": "correra_02",
		"titulo": "Jon Carter",
		"vuelta_total": 1,
		"tiempos": [
			{
				"id": 1,
				"id_player": 0
			}
		],
		"player": [
			{"id": 1, "user": "rabu", "progreso_vueltas": 0},
		]
	}
]

func _ready():
	pass
	
	# Inicializamos el ID del player en tiempos dinámicamente como vimos antes
	var id_del_jugador = tabla_misiones[1]["player"][0]["id"]
	tabla_misiones[1]["tiempos"][0]["id_player"] = id_del_jugador


# Esta función la va a llamar CUALQUIER Area3D del mapa pasándole su ID
func disparar_mision(id_mision: String):
	
	
	# 1. Buscamos la carrera/misión correcta en la tabla
	for mision in tabla_misiones:
		if mision["id"] == id_mision:
			
			# 2. Hacemos lo que tenga que pasar al pisar el trigger.
			# Por ejemplo, si es la carrera 'correra_01', le sumamos una vuelta a 'rabu'
			if mision.has("usuarios"):
				for usuario in mision["usuarios"]:
					if usuario["user"] == "rabu":
						usuario["progreso_vueltas"] += 1
						
						
						# Si quieres actualizar un Label de interfaz desde aquí, podrías hacerlo así:
						# get_tree().current_scene.find_child("MiLabel").text = "Vuelta: " + str(usuario["progreso_vueltas"])
						
						# Si llega al total, carrera completada
						if usuario["progreso_vueltas"] >= mision["vuelta_total"]:
							
						
						return # Salimos de la función ya que procesamos el cambio
						
			# Si es la carrera de Jon Carter ('correra_02') puedes poner otra lógica aquí:
			if id_mision == "correra_02":
				# Aquí meterías tu lógica de cronómetro, guardar récord, etc.
				return

	push_warning("Trigger con ID '", id_mision, "' no existe en la tabla de misiones.")
