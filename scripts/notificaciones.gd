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

func _ready() -> void:
	# Verificación de seguridad por si olvidaste arrastrar algún nodo en el Inspector
	if panel == null or mensaje_label == null or anim_player == null:
		push_error("❌ ¡ERROR! Faltan nodos por asignar en el Inspector de este script.")
		return
		
	# Ocultamos el panel al arrancar el juego
	panel.hide()


# Esta es la función que llamas desde tus otros scripts para mostrar texto
func mostrar_notificacion(texto: String, tiempo_visible: float = -1.0) -> void:
	var tiempo = tiempo_visible if tiempo_visible > 0 else tiempo_visible_defecto
	
	# 1. Cambiamos el texto de la alerta
	mensaje_label.text = texto
	
	# 2. Mostramos el panel y reproducimos TU animación real de entrada
	panel.show()
	anim_player.play("anim_notificacion/anim_notificaion")
	
	# 3. Esperamos el tiempo configurado en pantalla
	await get_tree().create_timer(tiempo).timeout
	
	# 4. Reproducimos la misma animación al revés (en reversa) para ocultarla,
	# ¡así no necesitas crear una segunda animación desde cero!
	anim_player.play_backwards("anim_notificacion/anim_notificaion")
	
	# 5. Esperamos a que termine de regresar para ocultar el nodo visualmente
	await anim_player.animation_finished
	panel.hide()
