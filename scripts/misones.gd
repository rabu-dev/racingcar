extends Node

@export var tabla_misiones: Array[Dictionary] = [
	{
		"id": "correra_01",
		"titulo": "Poul Swift",
		"vuelta_total": 3,
		"checkpoint_actual": 0,  # <-- Empieza en el checkpoint 0 (la salida)
		"total_checkpoints": 8,  # <-- Supongamos que el circuito tiene meta, checkpoint 1 y checkpoint 2
		"usuarios": [
			{"id": "1", "user": "rabu", "progreso_vueltas": 0},
		]
	},
	{
		"id": "correra_02",
		"titulo": "Jon Carter",
		"tiempos": [
			{
				"id": 1,
				"tiepo": 50000,
				"id_player" : 1,
			}
		],
		"player": [
			{"id": 1, "user": "rabu", "progreso_vueltas": 0},
			{"id": 2, "user": "bot1", "progreso_vueltas": 0}
		],
		"coord": Vector3(0, 0, 0)
	}
]

func _ready():
	print("--- ESCENA MISIONES ARRANCADA ---")
	
	# 1. Conexión manual por código (El cable invisible)
	# Buscamos el nodo Trigger en la escena y le conectamos su señal a nuestra función
	if has_node("TriggerCarrera3D") or has_node("TriggerCarrera3D2") :
		$TriggerCarrera3D.mision_pisada.connect(_on_trigger_carrera_3d_mision_pisada)
		$TriggerCarrera3D2.mision_pisada.connect(_on_trigger_carrera_3d_mision_pisada)
		print("¡Cable de señal conectado con éxito por código!")
	else:
		print("Alerta: No se encontró el nodo 'TriggerCarrera3D' como hijo de Misiones.")
	
	# Lo que ya tenías de los IDs y Labels...
	var id_del_jugador = tabla_misiones[1]["player"][0]["id"]
	tabla_misiones[1]["tiempos"][0]["id_player"] = id_del_jugador
	
	$Label_Mision.text = tabla_misiones[0]["titulo"] + " - Vueltas: 0"
	$Label_Mision2.text = tabla_misiones[1]["titulo"] + " - Esperando..."


# =================================================================
# ESTA FUNCIÓN RECIBE EL TRIGGER DEL AREA3D (Se conecta por Señales)
# =================================================================
func _on_trigger_carrera_3d_mision_pisada(id_mision: String, num_checkpoint: int):
	for mision in tabla_misiones:
		if mision["id"] == id_mision:
			
			var paso_correcto = mision["checkpoint_actual"]
			var total_cp = mision["total_checkpoints"]
			
			# CASO 1: Está en la Meta (0) y pisa el Checkpoint 1 (Es correcto)
			# O está en el 1 y pisa el 2...
			if num_checkpoint == paso_correcto + 1:
				mision["checkpoint_actual"] = num_checkpoint
				print("¡Checkpoint ", num_checkpoint, " registrado correctamente!")
				return
				
			# CASO 2: Ha completado el último checkpoint y vuelve a pisar la META (0)
			elif num_checkpoint == 0 and paso_correcto == total_cp - 1:
				# Reseteamos el recorrido al principio
				mision["checkpoint_actual"] = 0 
				
				# ¡Y ahora SÍ sumamos la vuelta de forma legal!
				mision["usuarios"][0]["progreso_vueltas"] += 1
				var vueltas = mision["usuarios"][0]["progreso_vueltas"]
				
				$Label1_Mision.text = mision["titulo"] + " - Vueltas: " + str(vueltas) + "/" + str(mision["vuelta_total"])
				print("¡Vuelta limpia completada! Total: ", vueltas)
				return
				
			# CASO 3: Ha pisado un checkpoint que no tocaba (Trampa o se ha saltado el camino)
			else:
				# Si vuelve a pisar el mismo en el que ya estaba, no pasa nada
				if num_checkpoint != paso_correcto:
					print("¡Mal! Has pisado el checkpoint ", num_checkpoint, " pero te tocaba el ", paso_correcto + 1)
	print("=> [Misiones] ¡Se ha detectado el trigger de la misión: ", id_mision, "!")
	
	# Recorremos la tabla para buscar qué misión coincide con el ID que pisó el jugador
	for mision in tabla_misiones:
		if mision["id"] == id_mision:
			
			# SI ES LA PRIMERA CARRERA (Poul Swift)
			if id_mision == "correra_01":
				# Accedemos al progreso de 'rabu' (índice 0 de usuarios) y le sumamos una vuelta
				mision["usuarios"][0]["progreso_vueltas"] += 1
				var vueltas_actuales = mision["usuarios"][0]["progreso_vueltas"]
				var vueltas_totales = mision["vuelta_total"]
				
				# Actualizamos el primer Label en tiempo real
				$Label_Mision.text = mision["titulo"] + " - Vueltas: " + str(vueltas_actuales) + "/" + str(vueltas_totales)
				print("Rabu lleva: ", vueltas_actuales, " vueltas.")
				
				if vueltas_actuales >= vueltas_totales:
					$Label_Mision.text = "¡" + mision["titulo"] + " COMPLETADA!"
				return
				
			# SI ES LA SEGUNDA CARRERA (Jon Carter)
			elif id_mision == "correra_02":
				# Accedemos al progreso de 'rabu' dentro de la lista 'player'
				mision["player"][0]["progreso_vueltas"] += 1
				var vueltas_p2 = mision["player"][0]["progreso_vueltas"]
				
				# Actualizamos el segundo Label en tiempo real
				$Label_Mision2.text = mision["titulo"] + " - Progreso: " + str(vueltas_p2)
				print("Progreso en Jon Carter: ", vueltas_p2)
				return

	print("Se recibió un ID de misión (" + id_mision + ") pero no existe en la tabla.")
