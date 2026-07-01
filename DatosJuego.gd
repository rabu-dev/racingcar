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

# Referencia al coche físico que esté activo en la escena
var coche_actual: VehicleBody3D = null

const COSTE_MEJORA = 1000
const MAX_NIVEL = 5
const COSTE_PINTURA = 500

const RUTA_GUARDADO = "user://savegame.json"

func _ready():
	cargar_partida()

# =====================================================
# 🛠️ SISTEMA DE CONEXIÓN Y SINCRONIZACIÓN DE FÍSICAS
# =====================================================
func registrar_coche(nodo_coche: VehicleBody3D) -> void:
	coche_actual = nodo_coche
	print("🚗 Coche registrado en el sistema de guardado.")

	# 1. Esperamos a que la escena se asiente en el árbol de nodos
	await get_tree().process_frame

	# 2. Esperamos a que el motor de físicas procese el SurfaceTool del mapa dinámico
	await get_tree().physics_frame

	# 3. Si NO hay partida guardada o la posición guardada parece un placeholder
	# (origen o casi tocando el suelo), mantenemos el spawn de la escena para
	# evitar que el coche aparezca en el vacío.
	if not tiene_partida_guardada() or _posicion_guardada_es_invalida():
		print("ℹ️ Posición guardada inválida o ausente. Manteniendo spawn original y reescribiendo partida.")
		posicion_coche = coche_actual.global_transform.origin
		rotacion_coche = coche_actual.global_transform.basis.get_euler()
		guardar_partida()
		return

	aplicar_posicion_al_coche()


# Consideramos inválida una posición guardada que esté exactamente en el origen,
# casi tocando el suelo (Y muy pequeña) o en el placeholder típico del spawn
# inicial (X=0, Y≈0.5, Z=0). Esto pasa cuando se guardó la partida antes de que
# el motor de físicas hubiera asentado al coche sobre el asfalto.
func _posicion_guardada_es_invalida() -> bool:
	if posicion_coche == Vector3.ZERO:
		return true
	if posicion_coche.y < 0.1:
		return true
	if posicion_coche.x == 0.0 and posicion_coche.z == 0.0 and abs(posicion_coche.y - 0.5) < 0.01:
		return true
	return false

func aplicar_posicion_al_coche() -> void:
	if not is_instance_valid(coche_actual): return
	
	# 1. Congelamos por completo cualquier inercia o velocidad previa residual
	coche_actual.linear_velocity = Vector3.ZERO
	coche_actual.angular_velocity = Vector3.ZERO
	coche_actual.engine_force = 0.0
	coche_actual.brake = 0.0
	
	# 2. Reconstruimos la matriz de transformación limpia
	var t = Transform3D()
	t = t.rotated(Vector3.UP, rotacion_coche.y)
	t = t.rotated(Vector3.RIGHT, rotacion_coche.x)
	t = t.rotated(Vector3.FORWARD, rotacion_coche.z)
	t.origin = posicion_coche
	
	# 3. Forzamos la posición directamente en el Servidor de Físicas
	# Esto evita que el coche atraviese las colisiones generadas por código en el primer frame
	var coche_rid = coche_actual.get_rid()
	PhysicsServer3D.body_set_state(coche_rid, PhysicsServer3D.BODY_STATE_TRANSFORM, t)
	PhysicsServer3D.body_set_state(coche_rid, PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY, Vector3.ZERO)
	PhysicsServer3D.body_set_state(coche_rid, PhysicsServer3D.BODY_STATE_ANGULAR_VELOCITY, Vector3.ZERO)
	
	# Aplicamos también al nodo visual
	coche_actual.global_transform = t
	print("✨ Coche posicionado con éxito sobre el asfalto en: ", posicion_coche)

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
# SISTEMA DE GUARDADO (JSON)
# =====================================================
func guardar_partida() -> void:
	# Si el coche está en la pista, guardamos sus coordenadas reales actuales
	if is_instance_valid(coche_actual):
		posicion_coche = coche_actual.global_transform.origin
		rotacion_coche = coche_actual.global_transform.basis.get_euler()

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

# 🔥 FUNCIÓN CORREGIDA: Borra el archivo físico Y limpia la memoria RAM al instante
func eliminar_partida() -> void:
	if FileAccess.file_exists(RUTA_GUARDADO):
		DirAccess.remove_absolute(RUTA_GUARDADO)
		print("🗑️ Archivo savegame.json eliminado del disco")
	
	# Reseteo forzado de variables para que no se queden flotando en los menús
	dinero = 1000000000  # O el dinero inicial que prefieras poner por defecto
	nivel_motor = 0
	color_coche = Color.RED
	progreso_carreras.clear()
	posicion_coche = Vector3.ZERO
	rotacion_coche = Vector3.ZERO
	
	print("✨ Memoria global del juego restablecida por completo")

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
