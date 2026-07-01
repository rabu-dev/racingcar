extends Control

# Variables exportadas para el tiempo y texto por defecto
@export var tiempo_visible_defecto: float = 2.0
@export var texto_prueba: String = "¡Notificación de prueba!"

# ======================================================
# NODOS EXPORTADOS (Se asignan desde el Inspector)
# ======================================================
@export var panel: Panel
@export var mensaje_label: Label
@export var anim_player: AnimationPlayer

# Cache de la animación resuelta (busca dinámicamente y tolera el typo previo)
var _anim_notif: String = ""

func _ready() -> void:
	# Verificación de seguridad por si olvidaste arrastrar algún nodo en el Inspector
	if panel == null or mensaje_label == null or anim_player == null:
		push_error("❌ ¡ERROR! Faltan nodos por asignar en el Inspector de este script.")
		return

	# Ocultamos el panel al arrancar el juego
	panel.hide()


# Resuelve el nombre real de la animación en el AnimationPlayer.
# Antes el código referenciaba "anim_notificacion/anim_notificaion" con un
# typo (faltaba la 'c'). Aquí buscamos la correcta y, si no existe,
# aceptamos la versión con typo para no romper proyectos antiguos.
func _resolver_anim_notif() -> String:
	if _anim_notif != "":
		return _anim_notif
	var nombres_posibles := [
		"anim_notificacion/anim_notificacion",
		"anim_notificacion/anim_notificaion",  # compatibilidad con typo previo
	]
	for nombre in nombres_posibles:
		if anim_player.has_animation(nombre):
			_anim_notif = nombre
			return _anim_notif
	# Fallback: primera animación cuyo nombre contenga "notif"
	for nombre in anim_player.get_animation_list():
		if "notif" in nombre.to_lower():
			_anim_notif = nombre
			return _anim_notif
	push_error("notificaciones.gd: no se encontró ninguna animación de notificación en el AnimationPlayer.")
	return ""


# Esta es la función que llamas desde tus otros scripts para mostrar texto
func mostrar_notificacion(texto: String, tiempo_visible: float = -1.0) -> void:
	# Guardas: si el script no terminó de inicializarse correctamente, evitamos crashear.
	if panel == null or mensaje_label == null or anim_player == null:
		push_warning("mostrar_notificacion(): nodos sin asignar, se omite la notificación '%s'." % texto)
		return

	var tiempo = tiempo_visible if tiempo_visible > 0 else tiempo_visible_defecto
	var anim_nombre := _resolver_anim_notif()
	if anim_nombre == "":
		return

	# 1. Cambiamos el texto de la alerta
	mensaje_label.text = texto

	# 2. Mostramos el panel y reproducimos la animación de entrada
	panel.show()
	anim_player.play(anim_nombre)

	# 3. Esperamos el tiempo configurado en pantalla
	await get_tree().create_timer(tiempo).timeout

	# 4. Reproducimos la misma animación al revés para ocultarla
	anim_player.play_backwards(anim_nombre)

	# 5. Esperamos a que termine de regresar para ocultar el nodo visualmente
	await anim_player.animation_finished
	panel.hide()
