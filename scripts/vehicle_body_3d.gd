extends VehicleBody3D

# =====================================================
# CONFIGURACIÓN
# =====================================================
@export var fuerza_motor: float = 5500.0
@export var angulo_giro_max: float = 0.75
@export var fuerza_freno: float = 45.0

# =====================================================
# UI
# =====================================================
@export var display_velocidad: Label
@export var gear_text: Label

# =====================================================
# SONIDO DEL MOTOR (MEJORADO)
# =====================================================
@export var motor_audio: AudioStreamPlayer3D
@export var pitch_minimo: float = 0.5
@export var pitch_maximo: float = 2.5          # Aumentado para acelerones
@export var velocidad_subida_rpm: float = 8.0  # Qué tan rápido sube al acelerar
@export var velocidad_bajada_rpm: float = 3.0  # Qué tan rápido baja al soltar

# Variables internas para el sonido
var rpm_actual: float = 0.8
var boost_cambio_marcha: float = 0.0  # Spike temporal al cambiar marcha

# =====================================================
# MARCHAS (R → N → 1-6)
# =====================================================
var marcha_actual: int = 0
const MARCHA_MAXIMA: int = 6
const MARCHA_MINIMA: int = -1

const VELOCIDADES_MARCHAS = [35, 0, 45, 75, 115, 155, 195, 240]
const POTENCIA_MARCHAS = [0.6, 0.0, 1.0, 0.85, 0.70, 0.58, 0.48, 0.38]

var ruedas_direccion: Array[VehicleWheel3D] = []

func _ready():
	for hijo in get_children():
		if hijo is VehicleWheel3D:
			if hijo.use_as_steering:
				ruedas_direccion.append(hijo)
	
	if ruedas_direccion.is_empty():
		printerr("🛑 ERROR: No hay ruedas con 'Use As Steering'.")
	else:
		print("✅ Dirección OK: ", ruedas_direccion.size(), " ruedas.")
	
	if motor_audio and not motor_audio.playing:
		motor_audio.play()
		rpm_actual = 0.8  # Empezar en ralentí

func _input(event):
	if event.is_action_pressed("subir_marcha") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		cambiar_marcha(1)
		boost_cambio_marcha = 0.6  # SPIKE de revoluciones al cambiar
		print("⚙️ Marcha Manual+: ", obtener_texto_marcha())
	elif event.is_action_pressed("bajar_marcha") or (event is InputEventKey and event.pressed and event.keycode == KEY_Q):
		cambiar_marcha(-1)
		boost_cambio_marcha = 0.4  # Spike menor al bajar marcha
		print("⚙️ Marcha Manual-: ", obtener_texto_marcha())

func cambiar_marcha(direccion: int):
	marcha_actual = clamp(marcha_actual + direccion, MARCHA_MINIMA, MARCHA_MAXIMA)

func obtener_texto_marcha() -> String:
	if marcha_actual == -1:
		return "R"
	elif marcha_actual == 0:
		return "N"
	else:
		return str(marcha_actual)

func _physics_process(delta):
	# ==========================================
	# 1. DIRECCIÓN
	# ==========================================
	var giro_input = 0.0
	giro_input = Input.get_axis("ui_right", "ui_left") 
	
	if giro_input == 0.0:
		if Input.is_key_pressed(KEY_A):
			giro_input = 1.0
		elif Input.is_key_pressed(KEY_D):
			giro_input = -1.0
	
	if not ruedas_direccion.is_empty():
		var target_giro = giro_input * angulo_giro_max
		for rueda in ruedas_direccion:
			rueda.steering = lerp(rueda.steering, target_giro, delta * 10.0)
	
	# ==========================================
	# 2. MOTOR Y FRENOS
	# ==========================================
	var velocidad_kmh = linear_velocity.length() * 3.6
	
	var acel_input = 0.0
	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("acelerar"):
		acel_input = 1.0
		
	var freno_input = 0.0
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("frenar"):
		freno_input = 1.0
	
	var indice_array = marcha_actual + 1
	var limite_marcha = VELOCIDADES_MARCHAS[indice_array]
	var factor_potencia = 1.0
	
	if velocidad_kmh > limite_marcha:
		var exceso = velocidad_kmh - limite_marcha
		factor_potencia = clamp(1.0 - (exceso / 40.0), 0.1, 1.0)
	
	if marcha_actual == -1:
		engine_force = -acel_input * fuerza_motor * POTENCIA_MARCHAS[indice_array]
	elif marcha_actual == 0:
		engine_force = 0.0
	else:
		engine_force = acel_input * fuerza_motor * factor_potencia * POTENCIA_MARCHAS[indice_array]
	
	brake = freno_input * fuerza_freno
	
	# ==========================================
	# 3. SONIDO DEL MOTOR (MEJORADO)
	# ==========================================
	if motor_audio:
		# Calcular RPM objetivo basado en velocidad
		var rpm_objetivo = 0.8  # Ralentí base
		
		if marcha_actual > 0:
			var progreso_marcha = velocidad_kmh / max(VELOCIDADES_MARCHAS[indice_array], 1.0)
			rpm_objetivo = 0.8 + (progreso_marcha * 1.0)
		elif marcha_actual == -1:
			rpm_objetivo = 0.8 + (velocidad_kmh / 35.0) * 0.5
		
		# Si está ACELERANDO, subir RPM agresivamente
		if acel_input > 0.0:
			rpm_objetivo += 0.8  # Boost grande al acelerar
			# Interpolación RÁPIDA cuando aceleras
			rpm_actual = lerp(rpm_actual, rpm_objetivo, delta * velocidad_subida_rpm)
		else:
			# Interpolación LENTA cuando sueltas (más realista)
			rpm_actual = lerp(rpm_actual, rpm_objetivo, delta * velocidad_bajada_rpm)
		
		# Aplicar el boost del cambio de marcha (se va reduciendo)
		boost_cambio_marcha = lerp(boost_cambio_marcha, 0.0, delta * 4.0)
		
		# Pitch final = RPM actual + boost temporal
		var pitch_final = clamp(rpm_actual + boost_cambio_marcha, pitch_minimo, pitch_maximo)
		motor_audio.pitch_scale = pitch_final
	
	# ==========================================
	# 4. INTERFAZ (UI)
	# ==========================================
	if display_velocidad:
		display_velocidad.text = "%d km/h" % int(velocidad_kmh)
		
	if gear_text:
		gear_text.text = obtener_texto_marcha()
