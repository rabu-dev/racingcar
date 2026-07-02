
extends VehicleBody3D

# =====================================================
# CONFIGURACIÓN
# =====================================================
@export_group("Configuracion")
@export var fuerza_motor: float = 8000.0
@export var angulo_giro_max: float = 0.70
@export var fuerza_freno: float = 100.0
@export var suavidad_freno: float = 6.0
@export var suavidad_direccion: float = 7.0
@export var factor_velocidad_direccion: float = 0.03
@export var resistencia_aire: float = 0.0001

# =====================================================
# UI
# =====================================================
@export_group("UI")
@export var display_velocidad: Label
@export var gear_text: Label

# =====================================================
# SONIDO DEL MOTOR
# =====================================================
@export_group("SONIDO DEL MOTOR")
@export var motor_audio: AudioStreamPlayer3D
@export var pitch_minimo: float = 0.5
@export var pitch_maximo: float = 2.5
@export var velocidad_subida_rpm: float = 8.0
@export var velocidad_bajada_rpm: float = 3.0

var rpm_actual: float = 0.8
var boost_cambio_marcha: float = 0.0

# =====================================================
# MARCHAS (R → N → 1-6)
# =====================================================
var marcha_actual: int = 0
const MARCHA_MAXIMA: int = 6
const MARCHA_MINIMA: int = -1

const VELOCIDADES_MARCHAS = [35, 0, 40, 70, 110, 150, 190, 230]
const POTENCIA_MARCHAS = [0.5, 0.0, 1.0, 0.92, 0.85, 0.78, 0.70, 0.65]

var ruedas_direccion: Array[VehicleWheel3D] = []

# Entradas normalizadas (0.0 - 1.0)
var input_aceleracion: float = 0.0
var input_freno: float = 0.0
var input_direccion: float = 0.0
var input_freno_mano: float = 0.0

var ruedas_traseras: Array[VehicleWheel3D] = []
var friccion_original_trasera: float = 1.8
var temporizador_guardado: float = 0.0
const INTERVALO_GUARDADO: float = 30.0

@export_group("Luces")
@export var faros_delanteros: Array[SpotLight3D] = []

@export_group("Humo de Derrape")
@export var humo_trasero_izq: GPUParticles3D
@export var humo_trasero_der: GPUParticles3D
@export var humo_delantero_izq: GPUParticles3D
@export var humo_delantero_der: GPUParticles3D
@export var velocidad_min_derrape: float = 15.0
@export var intensidad_derrape: float = 0.0

@export_group("Freno Mano")
@export var friccion_freno_mano: float = 0.4
@export var suavidad_freno_mano: float = 10.0
@export var fuerza_freno_mano: float = 40.0

@export_group("Física de Lluvia")
@export var friccion_seco: float = 1.8
@export var friccion_lluvia: float = 0.9

@export_group("Control IA")
@export var controlado_por_ai: bool = false
@export var mantener_camara_en_ai: bool = false

var es_de_noche: bool = false
var esta_lloviendo: bool = false
var ai_input_aceleracion: float = 0.0
var ai_input_freno: float = 0.0
var ai_input_direccion: float = 0.0
var ai_input_freno_mano: float = 0.0

# =====================================================
# READY
# =====================================================
func _ready():
	
	DatosJuego.registrar_coche(self)
	if controlado_por_ai and marcha_actual <= 0:
		marcha_actual = 1
	_configurar_camara_ai()
	# Aplicar color guardado al coche
	_aplicar_color_coche()
	
	# Aplicar posición guardada
	_aplicar_posicion_guardada()
	
	# 1. Buscar ruedas de dirección y tracción
	for hijo in get_children():
		if hijo is VehicleWheel3D:
			if hijo.use_as_steering:
				ruedas_direccion.append(hijo)
			elif hijo.use_as_traction:
				ruedas_traseras.append(hijo)
				friccion_original_trasera = hijo.wheel_friction_slip

	if ruedas_direccion.is_empty():
		printerr("🛑 ERROR: No hay ruedas con 'Use As Steering'.")
	else:
		print("✅ Dirección OK: ", ruedas_direccion.size(), " ruedas.")
	
	if not ruedas_traseras.is_empty():
		print("✅ Tracción OK: ", ruedas_traseras.size(), " ruedas traseras.")

	# 2. Inicializar Audio
	if motor_audio and not motor_audio.playing:
		motor_audio.play()
		rpm_actual = 0.8

	# 3. Conectar con el entorno y verificar estado de noche inicial
	var entorno = get_node_or_null("../WorldEnvironment")
	if entorno:
		print("✅ WorldEnvironment encontrado")
		entorno.clima_cambiado.connect(_on_clima_cambiado)
		entorno.hora_actualizada.connect(_on_hora_actualizada)
		
		# Comprueba la hora actual al arrancar el juego para encender luces si ya es de noche
		if "hora" in entorno:
			_comprobar_y_actualizar_hora(entorno.hora)
		elif "hora_actual" in entorno: 
			_comprobar_y_actualizar_hora(entorno.hora_actual)
	else:
		print("❌ WorldEnvironment NO encontrado — revisa la ruta")

	# 4. Inicializar partículas de humo
	for p in [humo_trasero_izq, humo_trasero_der, humo_delantero_izq, humo_delantero_der]:
		if p:
			p.emitting = true
			p.amount_ratio = 0.0
			# Configurar dirección de emisión: hacia arriba y hacia atrás
			if p.process_material:
				p.process_material.direction = Vector3(0, 1, 1)
				p.process_material.spread = 15.0

	# 5. Configuración inicial de físicas y luces
	_actualizar_friccion_ruedas(friccion_seco)
	_actualizar_faros()

# =====================================================
# INPUT (TECLADO + MANDO)
# =====================================================
func _input(event):

	# Subir marcha
	if event.is_action_pressed("subir_marcha"):
		cambiar_marcha(1)
		boost_cambio_marcha = 0.6
		print("⬆ Marcha:", obtener_texto_marcha())

	# Bajar marcha
	elif event.is_action_pressed("bajar_marcha"):
		cambiar_marcha(-1)
		boost_cambio_marcha = 0.4
		print("⬇ Marcha:", obtener_texto_marcha())
func cambiar_marcha(direccion: int):
	marcha_actual = clamp(
		marcha_actual + direccion,
		MARCHA_MINIMA,
		MARCHA_MAXIMA
	)

func obtener_texto_marcha() -> String:
	if marcha_actual == -1:
		return "R"
	elif marcha_actual == 0:
		return "N"
	else:
		return str(marcha_actual)
# =====================================================
# PHYSICS PROCESS
# =====================================================
func _physics_process(delta):
	# ------------------------------------------
	# 1. DIRECCIÓN (0.0 - 1.0, suavizada)
	# ------------------------------------------
	var giro_crudo = _obtener_input_direccion()

	# Factor de velocidad: a mayor velocidad, menos giro possible
	var velocidad_kmh = linear_velocity.length() * 3.6
	var factor_velocidad = clamp(1.0 - (velocidad_kmh * factor_velocidad_direccion), 0.3, 1.0)

	# Suavizado del input de dirección
	input_direccion = lerp(input_direccion, abs(giro_crudo), delta * suavidad_direccion)

	if not ruedas_direccion.is_empty():
		var target_giro = giro_crudo * angulo_giro_max * factor_velocidad
		for rueda in ruedas_direccion:
			rueda.steering = lerp(rueda.steering, target_giro, delta * suavidad_direccion)

	# ------------------------------------------
	# 2. MOTOR Y FRENOS (0.0 - 1.0, suavizados)
	# ------------------------------------------
	var acel_crudo = _obtener_input_aceleracion()
	var freno_crudo = _obtener_input_freno()
	var freno_mano_crudo = _obtener_input_freno_mano()

	# Suavizado de inputs
	input_aceleracion = lerp(input_aceleracion, acel_crudo, delta * suavidad_freno)
	input_freno = lerp(input_freno, freno_crudo, delta * suavidad_freno)
	input_freno_mano = lerp(input_freno_mano, freno_mano_crudo, delta * suavidad_freno_mano)

	var indice_array = marcha_actual + 1
	var limite_marcha = VELOCIDADES_MARCHAS[indice_array]
	var factor_potencia = 1.0

	if velocidad_kmh > limite_marcha:
		var exceso = velocidad_kmh - limite_marcha
		factor_potencia = clamp(1.0 - (exceso / 100.0), 0.3, 1.0)

	if marcha_actual == -1:
		engine_force = -input_aceleracion * fuerza_motor * POTENCIA_MARCHAS[indice_array]
	elif marcha_actual == 0:
		engine_force = 0.0
	else:
		engine_force = input_aceleracion * fuerza_motor * factor_potencia * POTENCIA_MARCHAS[indice_array]

	brake = input_freno * fuerza_freno

	# Resistencia del aire (más realista)
	var resistencia = linear_velocity.length() * resistencia_aire * linear_velocity.length()
	apply_central_force(-linear_velocity.normalized() * resistencia)

	# ------------------------------------------
	# 3. FRENO MANO
	# ------------------------------------------
	if not ruedas_traseras.is_empty():
		var friccion_objetivo = friccion_original_trasera if input_freno_mano < 0.1 else friccion_freno_mano
		for rueda in ruedas_traseras:
			rueda.wheel_friction_slip = lerp(rueda.wheel_friction_slip, friccion_objetivo, delta * suavidad_freno_mano)
		
		# Añadir freno extra cuando se usa freno mano
		if input_freno_mano > 0.5:
			brake += input_freno_mano * fuerza_freno_mano

	# ------------------------------------------
	# 4. DERRAPE (HUMO)
	# ------------------------------------------
	var velocidad_lateral = abs(linear_velocity.cross(global_transform.basis.z).length())
	var girando_fuerte = abs(input_direccion) > 0.2
	var derrapando = velocidad_lateral > 3.0 and velocidad_kmh > 10.0 and (girando_fuerte or input_freno_mano > 0.3)

	# Freno mano intensifica el derrape
	var factor_freno_mano = clamp(input_freno_mano * 1.5, 0.0, 1.0)
	
	if derrapando:
		intensidad_derrape = clamp(velocidad_lateral / 20.0, 0.2, 1.0)
		intensidad_derrape = clamp(intensidad_derrape + factor_freno_mano, 0.0, 1.0)
	else:
		intensidad_derrape = lerp(intensidad_derrape, factor_freno_mano * 0.5, delta * 4.0)
	#print("lat:", snapped(velocidad_lateral, 0.1), " kmh:", int(velocidad_kmh), " dir:", snapped(input_direccion, 0.01), " freno:", snapped(input_freno, 0.01), " mano:", snapped(input_freno_mano, 0.01), " humo:", int(intensidad_derrape * 100))

	_controlar_humo(humo_trasero_izq, intensidad_derrape)
	_controlar_humo(humo_trasero_der, intensidad_derrape)

	var derrape_delantero = derrapando and velocidad_kmh < 40.0 and (input_freno > 0.0 or input_freno_mano > 0.5)
	var intensidad_delantera = clamp(intensidad_derrape * 0.5, 0.0, 0.6) if derrape_delantero else lerp(_get_emission(humo_delantero_izq), 0.0, delta * 4.0)
	_controlar_humo(humo_delantero_izq, intensidad_delantera)
	_controlar_humo(humo_delantero_der, intensidad_delantera)

	# ------------------------------------------
	# 4. SONIDO DEL MOTOR
	# ------------------------------------------
	if motor_audio:
		var rpm_objetivo = 0.8

		if marcha_actual > 0:
			var progreso_marcha = velocidad_kmh / max(VELOCIDADES_MARCHAS[indice_array], 1.0)
			rpm_objetivo = 0.8 + (progreso_marcha * 1.0)
		elif marcha_actual == -1:
			rpm_objetivo = 0.8 + (velocidad_kmh / 35.0) * 0.5

		if input_aceleracion > 0.0:
			rpm_objetivo += 0.8
			rpm_actual = lerp(rpm_actual, rpm_objetivo, delta * velocidad_subida_rpm)
		else:
			rpm_actual = lerp(rpm_actual, rpm_objetivo, delta * velocidad_bajada_rpm)

		boost_cambio_marcha = lerp(boost_cambio_marcha, 0.0, delta * 4.0)

		var pitch_final = clamp(rpm_actual + boost_cambio_marcha, pitch_minimo, pitch_maximo)
		motor_audio.pitch_scale = pitch_final

	# ------------------------------------------
	# 5. GUARDADO PERIÓDICO
	# ------------------------------------------
	temporizador_guardado += delta
	if temporizador_guardado >= INTERVALO_GUARDADO:
		temporizador_guardado = 0.0
		# Mantenemos radianes (Vector3 Euler) para ser consistentes con
		# DatosJuego.guardar_partida() que ya usa basis.get_euler().
		# Antes se guardaba rotation_degrees, mezclando grados/radianes y
		# rompiendo la rotación al cargar la partida.
		DatosJuego.posicion_coche = global_position
		DatosJuego.rotacion_coche = global_transform.basis.get_euler()
		DatosJuego.guardar_partida()

	# ------------------------------------------
	# 6. UI
	# ------------------------------------------
	if display_velocidad:
		display_velocidad.text = "%d km/h" % int(velocidad_kmh)

	if gear_text:
		gear_text.text = obtener_texto_marcha()

# =====================================================
# SEÑALES DEL ENTORNO Y LÓGICA DE TIEMPO
# =====================================================
func _on_hora_actualizada(hora: float) -> void:
	_comprobar_y_actualizar_hora(hora)

func set_ai_input(aceleracion: float, freno_value: float, direccion: float, freno_mano_value: float = 0.0) -> void:
	ai_input_aceleracion = clamp(aceleracion, 0.0, 1.0)
	ai_input_freno = clamp(freno_value, 0.0, 1.0)
	ai_input_direccion = clamp(direccion, -1.0, 1.0)
	ai_input_freno_mano = clamp(freno_mano_value, 0.0, 1.0)
	if controlado_por_ai and marcha_actual <= 0:
		marcha_actual = 1

func limpiar_ai_input() -> void:
	set_ai_input(0.0, 0.0, 0.0, 0.0)

func _comprobar_y_actualizar_hora(hora: float) -> void:
	var nuevo_estado_noche = (hora >= 20.0 or hora < 6.0)
	
	# Muestra el estado del tiempo en la consola para debuguear
	#print("⏰ Reloj: ", hora, " | ¿Es de noche?: ", nuevo_estado_noche)
	
	if nuevo_estado_noche != es_de_noche:
		es_de_noche = nuevo_estado_noche
		_actualizar_faros()
		#print("💡 Luces del coche actualizadas. Estado encendido: ", es_de_noche or esta_lloviendo)

func _on_clima_cambiado(nuevo_clima: int) -> void:
	if nuevo_clima == 1:
		esta_lloviendo = true
		_actualizar_friccion_ruedas(friccion_lluvia)
	else:
		esta_lloviendo = false
		_actualizar_friccion_ruedas(friccion_seco)
	_actualizar_faros()

# =====================================================
# MÉTODOS INTERNOS
# =====================================================
func _actualizar_faros() -> void:
	if faros_delanteros.is_empty():
		return

	var encender: bool = (es_de_noche or esta_lloviendo)

	for luz in faros_delanteros:
		if is_instance_valid(luz):
			# Le damos mucha más potencia para asegurarnos de que se note en el mapa
			luz.light_energy = 50.0 if encender else 0.0
			
			# Forzamos a que el nodo esté visible y activo externamente
			luz.visible = encender
func _actualizar_friccion_ruedas(valor_friccion: float) -> void:
	for hijo in get_children():
		if hijo is VehicleWheel3D:
			hijo.wheel_friction_slip = valor_friccion

func _configurar_camara_ai() -> void:
	var camara := get_node_or_null("Camera3D") as Camera3D
	if not camara:
		return
	if controlado_por_ai and not mantener_camara_en_ai:
		camara.current = false
		camara.queue_free()
		return
	camara.current = true

func _obtener_input_direccion() -> float:
	if controlado_por_ai:
		return ai_input_direccion
	var giro_crudo = Input.get_axis("ui_right", "ui_left")
	if giro_crudo == 0.0:
		if Input.is_key_pressed(KEY_A):
			return 1.0
		if Input.is_key_pressed(KEY_D):
			return -1.0
	return giro_crudo

func _obtener_input_aceleracion() -> float:
	if controlado_por_ai:
		return ai_input_aceleracion
	return 1.0 if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("acelerar") else 0.0

func _obtener_input_freno() -> float:
	if controlado_por_ai:
		return ai_input_freno
	return 1.0 if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("frenar") else 0.0

func _obtener_input_freno_mano() -> float:
	if controlado_por_ai:
		return ai_input_freno_mano
	return 1.0 if Input.is_key_pressed(KEY_SPACE) or Input.is_action_pressed("freno_mano") else 0.0

func _controlar_humo(particulas: GPUParticles3D, intensidad: float) -> void:
	if not particulas:
		return
	particulas.amount_ratio = intensidad

func _get_emission(particulas: GPUParticles3D) -> float:
	return particulas.amount_ratio if particulas else 0.0

func _aplicar_color_coche() -> void:
	for hijo in get_children():
		if hijo is MeshInstance3D:
			var material = hijo.get_active_material(0)
			if material is StandardMaterial3D:
				material.albedo_color = DatosJuego.color_coche

func _aplicar_posicion_guardada() -> void:
	if DatosJuego.posicion_coche != Vector3.ZERO:
		global_position = DatosJuego.posicion_coche
		# rotation (no rotation_degrees): DatosJuego guarda Euler en radianes.
		rotation = DatosJuego.rotacion_coche

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		DatosJuego.posicion_coche = global_position
		DatosJuego.rotacion_coche = global_transform.basis.get_euler()
		DatosJuego.guardar_partida()
		get_tree().quit()
