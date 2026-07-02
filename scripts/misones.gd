extends Node

@export var tabla_misiones: Array[Dictionary] = [
	{
		"id": "correra_01",
		"titulo": "Poul Swift",
		"vuelta_total": 3,
		"checkpoint_actual": -1,
		"total_checkpoints": 8,
		"recompensa": 500,
		"usuarios": [
			{
				"id": "1",
				"user": "rabu",
				"progreso_vueltas": 0
			}
		]
	},
	{
		"id": "correra_02",
		"titulo": "JOb Carry",
		"vuelta_total": 3,
		"checkpoint_actual": -1,
		"total_checkpoints": 7,
		"recompensa": 1200,
		"tiempo": {
			"id": 0,
			"tiempo": 0.0,
			"player_id": ""
		},
		"usuarios": [
			{
				"id": "1",
				"user": "rabu",
				"progreso_vueltas": 0
			}
		]
	}
]

# ======================================================
# VARIABLES GLOBALES DE ESCENA
# ======================================================
# Nota: dinero_jugador se ha eliminado, ahora usamos DatosJuego.dinero
var carrera_tiempo_activa: bool = false
var tiempo_transcurrido: float = 0.0


func _ready():
	print("--- ESCENA MISIONES ARRANCADA ---")

	# Sincronizar la interfaz con el dinero que ya tenga guardado el jugador
	actualizar_interfaz_dinero()

	# ======================================
	# CONECTAR TRIGGERS POR GRUPO
	# ======================================

	for trigger in get_tree().get_nodes_in_group("mision_1"):
		trigger.mision_pisada.connect(
			_on_trigger_carrera_3d_mision_pisada
		)
		#print("Mision1 trigger conectado: ", trigger.name)

	for trigger in get_tree().get_nodes_in_group("mision_2"):
		trigger.mision_pisada.connect(
			_on_trigger_carrera_3d_mision_pisada
		)
		#print("Mision2 trigger conectado: ", trigger.name)

	# ======================================
	# PLAYER ID TIEMPO
	# ======================================

	var id_del_jugador = tabla_misiones[1]["usuarios"][0]["id"]
	tabla_misiones[1]["tiempo"]["player_id"] = id_del_jugador

	# ======================================
	# UI INICIAL
	# ======================================

	if has_node("VBoxContainer/Label_Mision"):
		$VBoxContainer/Label_Mision.text = (
			tabla_misiones[0]["titulo"]
			+ " - Vueltas: 0/"
			+ str(tabla_misiones[0]["vuelta_total"])
		)

	if has_node("VBoxContainer/Label_Mision2"):
		$VBoxContainer/Label_Mision2.text = (
			tabla_misiones[1]["titulo"]
			+ " - Esperando inicio..."
		)


func _process(delta: float):

	if carrera_tiempo_activa:

		tiempo_transcurrido += delta

		tabla_misiones[1]["tiempo"]["tiempo"] = tiempo_transcurrido

		var minutos = int(tiempo_transcurrido / 60)
		var segundos = int(tiempo_transcurrido) % 60
		var milesimas = int(
			(tiempo_transcurrido - floor(tiempo_transcurrido))
			* 100
		)

		if has_node("VBoxContainer/Label_Mision2"):
			$VBoxContainer/Label_Mision2.text = (
				tabla_misiones[1]["titulo"]
				+ " - Tiempo: %02d:%02d.%02d"
				% [minutos, segundos, milesimas]
			)


# ======================================================
# DINERO Y COMPRAS (CONECTADO AL AUTOLOAD)
# ======================================================

func ganar_dinero(cantidad: int):
	DatosJuego.dinero += cantidad
	DatosJuego.guardar_partida()
	#print(
		#"💰 Has ganado +$",
		#cantidad,
		#" | Total: $",
		#DatosJuego.dinero
	#)

	actualizar_interfaz_dinero()


func actualizar_interfaz_dinero():
	# Obtenemos el valor real de los datos guardados
	var dinero_actual = DatosJuego.dinero

	if has_node("dinero"):
		$dinero.text = "Dinero: $" + str(dinero_actual)

	elif has_node("Dinero"):
		$Dinero.text = "Dinero: $" + str(dinero_actual)


func intentar_comprar_mejora(precio_mejora: int) -> bool:
	# Verificamos y restamos usando los datos guardados en el Autoload
	if DatosJuego.dinero >= precio_mejora:

		DatosJuego.dinero -= precio_mejora

		actualizar_interfaz_dinero()

		#print(
			#"✅ Compra realizada | Saldo: $",
			#DatosJuego.dinero
		#)

		return true

	#print("❌ No tienes dinero suficiente")

	return false


# ======================================================
# CHECKPOINTS Y CARRERAS
# ======================================================

func _on_trigger_carrera_3d_mision_pisada(
	id_mision: String,
	num_checkpoint: int
):
	# Buscar índice de la misión
	var idx = -1
	for i in tabla_misiones.size():
		if tabla_misiones[i]["id"] == id_mision:
			idx = i
			break

	if idx == -1:
		#print("❌ ID de misión inválido: ", id_mision)
		return

	var checkpoint_actual = tabla_misiones[idx]["checkpoint_actual"]
	var total_cp = tabla_misiones[idx]["total_checkpoints"]

	#print(
		#"MISSION:", id_mision,
		#" | ACTUAL:", checkpoint_actual,
		#" | ENTRÓ:", num_checkpoint
	#)

	# ======================================
	# INICIO DE CARRERA
	# ======================================

	if checkpoint_actual == -1:

		if num_checkpoint == 0:

			tabla_misiones[idx]["checkpoint_actual"] = 0

			#print("🏁 Carrera iniciada")

			if id_mision == "correra_02":
				carrera_tiempo_activa = true
				tiempo_transcurrido = 0.0

		return

	# ======================================
	# CHECKPOINT SIGUIENTE
	# ======================================

	if num_checkpoint == checkpoint_actual + 1:

		tabla_misiones[idx]["checkpoint_actual"] = num_checkpoint

		#print("✅ Checkpoint válido:", num_checkpoint)

		return

	# ======================================
	# COMPLETAR VUELTA
	# ======================================

	if num_checkpoint == 0 and checkpoint_actual == total_cp - 1:

		tabla_misiones[idx]["checkpoint_actual"] = 0
		tabla_misiones[idx]["usuarios"][0]["progreso_vueltas"] += 1

		var vueltas = tabla_misiones[idx]["usuarios"][0]["progreso_vueltas"]

		#print(
			#"🏁 VUELTA COMPLETADA ",
			#vueltas,
			#"/",
			#tabla_misiones[idx]["vuelta_total"]
		#)

		# ==================================
		# ACTUALIZAR UI
		# ==================================

		if id_mision == "correra_01":
			if has_node("VBoxContainer/Label_Mision"):
				$VBoxContainer/Label_Mision.text = (
					tabla_misiones[idx]["titulo"]
					+ " - Vueltas: "
					+ str(vueltas)
					+ "/"
					+ str(tabla_misiones[idx]["vuelta_total"])
				)

		# ==================================
		# TERMINAR CARRERA
		# ==================================

		if vueltas >= tabla_misiones[idx]["vuelta_total"]:

			ganar_dinero(tabla_misiones[idx]["recompensa"])
			DatosJuego.completar_carrera(id_mision, tiempo_transcurrido if id_mision == "correra_02" else 0.0)

			if id_mision == "correra_02":

				carrera_tiempo_activa = false

				if has_node("VBoxContainer/Label_Mision2"):
					$VBoxContainer/Label_Mision2.text = (
						"🏆 "
						+ tabla_misiones[idx]["titulo"]
						+ " COMPLETADA +$"
						+ str(tabla_misiones[idx]["recompensa"])
					)

			else:

				if has_node("VBoxContainer/Label_Mision"):
					$VBoxContainer/Label_Mision.text = (
						"🏆 "
						+ tabla_misiones[idx]["titulo"]
						+ " COMPLETADA +$"
						+ str(tabla_misiones[idx]["recompensa"])
					)

		return

	# ======================================
	# REPETIR MISMO CHECKPOINT
	# ======================================

	if num_checkpoint == checkpoint_actual:
		return

	# ======================================
	# ERROR ORDEN
	# ======================================

	#print(
		#"❌ Orden incorrecto. Tocaba: ",
		#checkpoint_actual + 1,
		#" pero pisaste: ",
		#num_checkpoint
	#)
