extends WorldEnvironment

enum Clima { DESPEJADO, LLUVIOSO, NIEBLA }
signal clima_cambiado(nuevo_clima: Clima)
signal hora_actualizada(hora: float)

@export_group("Configuracion de Tiempo")
@export var velocidad_tiempo: float = 1.0 # Multiplicador: 1.0 = 1 minuto de juego por segundo real
@export_range(0.0, 24.0) var hora_actual: float = 8.0 # Empezamos a las 8:00 AM

@export_group("Asignaciones")
@export var sol: DirectionalLight3D
@export var particulas_lluvia: GPUParticles3D # Debe estar asignado para el clima lluvioso

# Variables internas para la transición suave del clima
@export var clima_actual: Clima = Clima.DESPEJADO
var interpolacion_clima: float = 0.0
var velocidad_transicion_clima: float = 2.5

# Configuración de colores para el ciclo día/noche
var color_dia: Color = Color("fff6e3")
var color_tarde: Color = Color("e27b3e")
var color_noche: Color = Color("1a1c2e")



func _ready() -> void:
	if not sol:
		push_warning("Falta asignar el nodo DirectionalLight3D en el inspector.")
	
	if environment:
		environment = environment.duplicate()
		environment.glow_enabled = false
		
	# Dejamos las partículas encendidas pero con ratio 0 para controlarlo por código suavemente
	if particulas_lluvia:
		particulas_lluvia.emitting = true
		particulas_lluvia.amount_ratio = 0.0

var _ultima_hora_visual: float = -1.0

func _process(delta: float) -> void:
	_avanzar_tiempo(delta)
	_actualizar_iluminacion_y_cielo()
	_procesar_transicion_clima(delta)

# ----------------------------------------------------------------
# LÓGICA DEL TIEMPO (Ciclo Día/Noche)
# ----------------------------------------------------------------
func _avanzar_tiempo(delta: float) -> void:
	hora_actual += (delta * velocidad_tiempo) / 60.0
	if hora_actual >= 24.0:
		hora_actual = 0.0
	hora_actualizada.emit(hora_actual)

func _actualizar_iluminacion_y_cielo() -> void:
	if not sol or not environment:
		return

	var hora_bucket = floor(hora_actual * 10.0) / 10.0
	if hora_bucket == _ultima_hora_visual and clima_actual == Clima.DESPEJADO:
		return
	_ultima_hora_visual = hora_bucket

	var angulo_x: float = deg_to_rad((hora_actual * 15.0) - 90.0)
	sol.rotation.x = angulo_x

	var intensidad_objetivo: float
	var color_objetivo: Color

	if hora_actual >= 6.0 and hora_actual < 12.0:
		var t = (hora_actual - 6.0) / 6.0
		color_objetivo = color_tarde.lerp(color_dia, t)
		intensidad_objetivo = lerp(0.2, 1.0, t)
	elif hora_actual >= 12.0 and hora_actual < 18.0:
		var t = (hora_actual - 12.0) / 6.0
		color_objetivo = color_dia.lerp(color_tarde, t)
		intensidad_objetivo = lerp(1.0, 0.8, t)
	elif hora_actual >= 18.0 and hora_actual < 20.0:
		var t = (hora_actual - 18.0) / 2.0
		color_objetivo = color_tarde.lerp(color_dia, t)
		intensidad_objetivo = lerp(0.8, 0.0, t)
	else:
		color_objetivo = color_tarde
		intensidad_objetivo = 0.0

	if clima_actual == Clima.DESPEJADO:
		sol.light_color = color_objetivo
		sol.light_energy = intensidad_objetivo
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.ambient_light_color = color_noche
		environment.ambient_light_energy = clamp(intensidad_objetivo * 0.4, 0.15, 0.4)
		if intensidad_objetivo <= 0.01:
			environment.background_mode = Environment.BG_COLOR
			environment.background_color = Color("0a0d1a")
		else:
			environment.background_mode = Environment.BG_SKY
			environment.background_energy_multiplier = lerp(0.1, 1.5, intensidad_objetivo)

# ----------------------------------------------------------------
# LÓGICA DEL CLIMA
# ----------------------------------------------------------------
func cambiar_clima(nuevo_clima: Clima) -> void:
	if clima_actual == nuevo_clima:
		return
	clima_actual = nuevo_clima
	interpolacion_clima = 0.0 # Reiniciar la interpolación para una transición suave
	clima_cambiado.emit(clima_actual)

func _procesar_transicion_clima(delta: float) -> void:
	if interpolacion_clima < 1.0:
		interpolacion_clima = clamp(interpolacion_clima + delta * velocidad_transicion_clima, 0.0, 1.0)
		
	match clima_actual:
		Clima.DESPEJADO:
			if environment:
				if environment.fog_enabled:
					environment.fog_enabled = false
				# Apagamos los reflejos de suelo mojado suavemente
				if environment.ssr_enabled:
					environment.ssr_enabled = false
			if particulas_lluvia:
				particulas_lluvia.amount_ratio = lerp(particulas_lluvia.amount_ratio, 0.0, interpolacion_clima)
				
		Clima.LLUVIOSO:
			if sol:
				sol.light_energy = lerp(sol.light_energy, 0.15, interpolacion_clima)
				sol.light_color = sol.light_color.lerp(Color("3a4146"), interpolacion_clima)
			if particulas_lluvia:
				particulas_lluvia.amount_ratio = lerp(particulas_lluvia.amount_ratio, 0.3, interpolacion_clima)
				
		Clima.NIEBLA:
			if environment:
				if not environment.fog_enabled:
					environment.fog_enabled = true
				if environment.ssr_enabled:
					environment.ssr_enabled = false
			if particulas_lluvia:
				particulas_lluvia.amount_ratio = lerp(particulas_lluvia.amount_ratio, 0.0, interpolacion_clima)
