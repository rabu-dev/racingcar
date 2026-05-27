extends Node

# Tu tabla global con todas las misiones y carreras del juego
@export var tabla_misiones: Array[Dictionary] = [
	{
		"id": "correra_01",
		"titulo": "Poul Swift",
		"vuelta_total": 5,
		"usuarios": [
			{"id": "1", "user": "rabu", "progreso_vueltas": 0},
			{"id": "2", "user": "bot1", "progreso_vueltas": 0}
		]
	},
	{
		"id": "correra_02",
		"titulo": "Jon Carter",
		"tiempos": [
			{
				"id": 1,
				"id_player": 0
			}
		],
		"player": [
			{"id": 1, "user": "rabu", "progreso_vueltas": 0},
			{"id": 2, "user": "bot1", "progreso_vueltas": 0}
		]
	}
]

func _ready():
	print("--- GestorMisiones Iniciado correctamente ---")
	
	# Inicializamos el ID del player en tiempos dinámicamente como vimos antes
	var id_del_jugador = tabla_misiones[1]["player"][0]["id"]
	tabla_misiones[1]["tiempos"][0]["id_player"] = id_del_jugador


# Esta función la va a llamar CUALQUIER Area3D del mapa pasándole su ID
func disparar_mision(id_mision: String):
	print("=> [GestorMisiones] Recibida señal del trigger para la misión: ", id_mision)
	
	# 1. Buscamos la carrera/misión correcta en la tabla
	for mision in tabla_misiones:
		if mision["id"] == id_mision:
			
			# 2. Hacemos lo que tenga que pasar al pisar el trigger.
			# Por ejemplo, si es la carrera 'correra_01', le sumamos una vuelta a 'rabu'
			if mision.has("usuarios"):
				for usuario in mision["usuarios"]:
					if usuario["user"] == "rabu":
						usuario["progreso_vueltas"] += 1
						print("¡Progreso de rabu actualizado! Vueltas: ", usuario["progreso_vueltas"], "/", mision["vuelta_total"])
						
						# Si quieres actualizar un Label de interfaz desde aquí, podrías hacerlo así:
						# get_tree().current_scene.find_child("MiLabel").text = "Vuelta: " + str(usuario["progreso_vueltas"])
						
						# Si llega al total, carrera completada
						if usuario["progreso_vueltas"] >= mision["vuelta_total"]:
							print("¡CARRERA TERMINADA PARA RABU!")
						
						return # Salimos de la función ya que procesamos el cambio
						
			# Si es la carrera de Jon Carter ('correra_02') puedes poner otra lógica aquí:
			if id_mision == "correra_02":
				print("¡Procesando tiempos para la carrera de Jon Carter!")
				# Aquí meterías tu lógica de cronómetro, guardar récord, etc.
				return

	print("Alerta: Se activó un trigger con ID '", id_mision, "' pero no existe en la tabla.")
