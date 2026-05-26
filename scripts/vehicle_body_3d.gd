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
# MARCHAS (R → N → 1-6)
# =====================================================
var marcha_actual: int = 1
const MARCHA_MAXIMA: int = 6
const MARCHA_MINIMA: int = -1  # -1=R, 0=N, 1-6=Marchas

# Índice en array: [R, N, 1, 2, 3, 4, 5, 6]
# Para acceder: usar (marcha_actual + 1)
const VELOCIDADES_MARCHAS = [35, 0, 45, 75, 115, 155, 195, 240]
const POTENCIA_MARCHAS = [0.6, 0.0, 1.0, 0.85, 0.70, 0.58, 0.48, 0.38]

var ruedas_direccion: Array[VehicleWheel3D] = []

func _ready():
	# Buscar ruedas direccionales automáticamente
	for hijo in get_children():
		if hijo is VehicleWheel3D:
			if hijo.use_as_steering:
				ruedas_direccion.append(hijo)
	
	if ruedas_direccion.is_empty():
		printerr("🛑 ERROR: No hay ruedas con 'Use As Steering'.")
	else:
		print("✅ Dirección OK: ", ruedas_direccion.size(), " ruedas.")

func _input(event):
	# Soporte para teclado (Q/E) y Mando (acciones mapeadas)
	if event.is_action_pressed("subir_marcha") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		cambiar_marcha(1)
		print("⚙️ Marcha Manual+: ", obtener_texto_marcha())
	elif event.is_action_pressed("bajar_marcha") or (event is InputEventKey and event.pressed and event.keycode == KEY_Q):
		cambiar_marcha(-1)
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
	# 1. DIRECCIÓN (Soportando Teclado y Stick del Mando)
	# ==========================================
	
	var giro_input = 0.0
	
	giro_input = Input.get_axis("ui_right", "ui_left") 
	
	if giro_input == 0.0:
		if Input.is_key_pressed(KEY_A):
			giro_input = 1.0
		elif Input.is_key_pressed(KEY_D):
			giro_input = -1.0
	
	# Aplicar el giro a las ruedas
	if not ruedas_direccion.is_empty():
		var target_giro = giro_input * angulo_giro_max
		for rueda in ruedas_direccion:
			rueda.steering = lerp(rueda.steering, target_giro, delta * 10.0)
	
	# ==========================================
	# 2. MOTOR Y FRENOS (R/N/1-6)
	# ==========================================
	var velocidad_kmh = linear_velocity.length() * 3.6
	
	var acel_input = 0.0
	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("acelerar"):
		acel_input = 1.0
		
	var freno_input = 0.0
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("frenar"):
		freno_input = 1.0
	
	# Índice del array (marcha_actual va de -1 a 6, array de 0 a 7)
	var indice_array = marcha_actual + 1
	
	# Control de velocidad por marchas
	var limite_marcha = VELOCIDADES_MARCHAS[indice_array]
	var factor_potencia = 1.0
	
	if velocidad_kmh > limite_marcha:
		var exceso = velocidad_kmh - limite_marcha
		factor_potencia = clamp(1.0 - (exceso / 40.0), 0.1, 1.0)
	
	# Aplicar fuerza del motor
	if marcha_actual == -1:  # Marcha atrás
		engine_force = -acel_input * fuerza_motor * POTENCIA_MARCHAS[indice_array]
	elif marcha_actual == 0:  # Neutra (sin fuerza)
		engine_force = 0.0
	else:  # Marchas normales 1-6
		engine_force = acel_input * fuerza_motor * factor_potencia * POTENCIA_MARCHAS[indice_array]
	
	brake = freno_input * fuerza_freno
	
	# ==========================================
	# 3. INTERFAZ (UI)
	# ==========================================
	if display_velocidad:
		display_velocidad.text = "%d km/h" % int(velocidad_kmh)
		
	if gear_text:
		gear_text.text = obtener_texto_marcha()
