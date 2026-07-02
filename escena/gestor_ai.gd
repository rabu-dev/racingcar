extends Node3D

@export var grupo_bots: StringName = &"ai_racer"
@export var grupo_checkpoints: StringName = &"mision_1"
@export var distancia_cambio_checkpoint: float = 16.0
@export var velocidad_recta_kmh: float = 115.0
@export var velocidad_curva_kmh: float = 60.0
@export var angulo_curva_grados: float = 30.0
@export var distancia_frenado_extra: float = 28.0

var ruta: Array[Node3D] = []
var progreso_por_bot: Dictionary = {}

func _ready() -> void:
	_recargar_ruta()


func _physics_process(_delta: float) -> void:
	if ruta.is_empty():
		_recargar_ruta()
		return

	for bot in get_tree().get_nodes_in_group(grupo_bots):
		if not is_instance_valid(bot):
			continue
		if not bot.has_method("set_ai_input"):
			continue
		if not bool(bot.get("controlado_por_ai")):
			continue
		_actualizar_bot(bot)


func _recargar_ruta() -> void:
	var checkpoints: Array[Node3D] = []
	for nodo in get_tree().get_nodes_in_group(grupo_checkpoints):
		if nodo is Node3D:
			checkpoints.append(nodo)
	checkpoints.sort_custom(func(a: Node3D, b: Node3D): return _orden_checkpoint(a) < _orden_checkpoint(b))
	ruta = checkpoints
	progreso_por_bot.clear()


func _actualizar_bot(bot: VehicleBody3D) -> void:
	var bot_id = bot.get_instance_id()
	if not progreso_por_bot.has(bot_id):
		progreso_por_bot[bot_id] = _buscar_checkpoint_inicial(bot.global_position)

	var indice: int = progreso_por_bot[bot_id]
	var objetivo := ruta[indice]
	var objetivo_pos := objetivo.global_position
	var plano_objetivo := Vector3(objetivo_pos.x, bot.global_position.y, objetivo_pos.z) - bot.global_position
	var distancia := plano_objetivo.length()

	if distancia <= distancia_cambio_checkpoint:
		indice = (indice + 1) % ruta.size()
		progreso_por_bot[bot_id] = indice
		objetivo = ruta[indice]
		objetivo_pos = objetivo.global_position
		plano_objetivo = Vector3(objetivo_pos.x, bot.global_position.y, objetivo_pos.z) - bot.global_position
		distancia = plano_objetivo.length()

	if plano_objetivo.length_squared() <= 0.001:
		bot.set_ai_input(0.0, 0.2, 0.0)
		return

	var forward: Vector3 = -bot.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var dir_objetivo: Vector3 = plano_objetivo.normalized()
	var angulo: float = forward.signed_angle_to(dir_objetivo, Vector3.UP)
	var steer: float = clampf(angulo / deg_to_rad(40.0), -1.0, 1.0)
	var velocidad_kmh: float = bot.linear_velocity.length() * 3.6
	var angulo_abs: float = abs(rad_to_deg(angulo))
	var objetivo_velocidad: float = velocidad_recta_kmh if angulo_abs < angulo_curva_grados else velocidad_curva_kmh

	if distancia < distancia_frenado_extra and angulo_abs > angulo_curva_grados:
		objetivo_velocidad = min(objetivo_velocidad, velocidad_curva_kmh * 0.85)

	var aceleracion: float = 0.0
	var freno: float = 0.0
	var freno_mano: float = 0.0

	if velocidad_kmh < objetivo_velocidad - 6.0:
		aceleracion = 1.0
	elif velocidad_kmh > objetivo_velocidad + 10.0:
		freno = 0.7
	else:
		aceleracion = 0.35

	if angulo_abs > 55.0 and velocidad_kmh > velocidad_curva_kmh:
		freno = max(freno, 1.0)
		freno_mano = 0.15

	bot.set_ai_input(aceleracion, freno, steer, freno_mano)


func _buscar_checkpoint_inicial(origen: Vector3) -> int:
	var mejor_indice := 0
	var mejor_distancia := INF
	for i in ruta.size():
		var distancia := origen.distance_squared_to(ruta[i].global_position)
		if distancia < mejor_distancia:
			mejor_distancia = distancia
			mejor_indice = i
	return mejor_indice


func _orden_checkpoint(nodo: Node3D) -> int:
	return int(nodo.get("numero_checkpoint"))
