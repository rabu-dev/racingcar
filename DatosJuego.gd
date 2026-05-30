extends Node

# Variables globales que no se borran al cambiar de escena
var dinero: int = 1000000000
var color_coche: Color = Color.RED
var nivel_motor: int = 0

# Progreso de carreras: { id_carrera: { completada: bool, mejor_tiempo: float, vueltas: int } }
var progreso_carreras: Dictionary = {}

# Posición del coche
var posicion_coche: Vector3 = Vector3.ZERO
var rotacion_coche: Vector3 = Vector3.ZERO

const COSTE_MEJORA = 1000
const MAX_NIVEL = 5
const COSTE_PINTURA = 500

const RUTA_GUARDADO = "user://savegame.json"

func _ready():
	cargar_partida()

# =====================================================
# MEJORAS Y COMPRAS
# =====================================================
func mejorar_motor() -> bool:
	if nivel_motor < MAX_NIVEL and dinero >= COSTE_MEJORA:
		dinero -= COSTE_MEJORA
		nivel_motor += 1
		guardar_partida()
		return true
	return false

func cambiar_color(nuevo_color: Color) -> bool:
	if dinero >= COSTE_PINTURA:
		dinero -= COSTE_PINTURA
		color_coche = nuevo_color
		guardar_partida()
		return true
	return false

# =====================================================
# SISTEMA DE GUARDADO
# =====================================================
func guardar_partida() -> void:
	var datos = {
		"dinero": dinero,
		"color_coche": {
			"r": color_coche.r,
			"g": color_coche.g,
			"b": color_coche.b,
			"a": color_coche.a
		},
		"nivel_motor": nivel_motor,
		"progreso_carreras": progreso_carreras,
		"posicion_coche": {
			"x": posicion_coche.x,
			"y": posicion_coche.y,
			"z": posicion_coche.z
		},
		"rotacion_coche": {
			"x": rotacion_coche.x,
			"y": rotacion_coche.y,
			"z": rotacion_coche.z
		}
	}

	var archivo = FileAccess.open(RUTA_GUARDADO, FileAccess.WRITE)
	if archivo:
		archivo.store_string(JSON.stringify(datos, "\t"))
		archivo.close()
		print("💾 Partida guardada")
	else:
		printerr("❌ Error al guardar la partida")

func cargar_partida() -> bool:
	if not FileAccess.file_exists(RUTA_GUARDADO):
		print("📁 No hay partida guardada")
		return false

	var archivo = FileAccess.open(RUTA_GUARDADO, FileAccess.READ)
	if not archivo:
		printerr("❌ Error al leer la partida guardada")
		return false

	var texto = archivo.get_as_text()
	archivo.close()

	var json = JSON.new()
	var error = json.parse(texto)
	if error != OK:
		printerr("❌ Error al parsear la partida guardada")
		return false

	var datos = json.data
	dinero = datos.get("dinero", 1000000000)
	nivel_motor = datos.get("nivel_motor", 0)

	var color_data = datos.get("color_coche", {})
	if color_data:
		color_coche = Color(
			color_data.get("r", 1.0),
			color_data.get("g", 0.0),
			color_data.get("b", 0.0),
			color_data.get("a", 1.0)
		)

	progreso_carreras = datos.get("progreso_carreras", {})

	var pos_data = datos.get("posicion_coche", {})
	if pos_data:
		posicion_coche = Vector3(
			pos_data.get("x", 0.0),
			pos_data.get("y", 0.5),
			pos_data.get("z", 0.0)
		)

	var rot_data = datos.get("rotacion_coche", {})
	if rot_data:
		rotacion_coche = Vector3(
			rot_data.get("x", 0.0),
			rot_data.get("y", 0.0),
			rot_data.get("z", 0.0)
		)

	print("💾 Partida cargada | Dinero: $", dinero, " | Motor: ", nivel_motor)
	return true

func eliminar_partida() -> void:
	if FileAccess.file_exists(RUTA_GUARDADO):
		DirAccess.remove_absolute(RUTA_GUARDADO)
		print("🗑️ Partida eliminada")

func tiene_partida_guardada() -> bool:
	return FileAccess.file_exists(RUTA_GUARDADO)

# =====================================================
# PROGRESO DE CARRERAS
# =====================================================
func completar_carrera(id_carrera: String, tiempo: float) -> void:
	if not progreso_carreras.has(id_carrera):
		progreso_carreras[id_carrera] = {
			"completada": true,
			"mejor_tiempo": tiempo,
			"vueltas": 0
		}
	else:
		progreso_carreras[id_carrera]["completada"] = true
		if tiempo < progreso_carreras[id_carrera]["mejor_tiempo"]:
			progreso_carreras[id_carrera]["mejor_tiempo"] = tiempo
	guardar_partida()

func esta_carrera_completada(id_carrera: String) -> bool:
	if progreso_carreras.has(id_carrera):
		return progreso_carreras[id_carrera].get("completada", false)
	return false

func obtener_mejor_tiempo(id_carrera: String) -> float:
	if progreso_carreras.has(id_carrera):
		return progreso_carreras[id_carrera].get("mejor_tiempo", 999999.0)
	return 999999.0
