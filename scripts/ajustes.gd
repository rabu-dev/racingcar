extends Control

var menu_abierto: bool = false

func _ready() -> void:
	hide() # Empieza oculto
	process_mode = Node.PROCESS_MODE_ALWAYS # No se frena con la pausa


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("abrir_ajustes"):
		toggle_menu_ajustes()


func toggle_menu_ajustes() -> void:
	menu_abierto = !menu_abierto
	
	if menu_abierto:
		show()
		# get_tree().paused = true # Descomenta si quieres pausar el juego
		#print("⚙️ Menú de ajustes abierto")
	else:
		hide()
		# get_tree().paused = false # Descomenta si usaste la pausa arriba
		#print("🚗 Volviendo al juego")


# Esta es la función que estás conectando desde la interfaz de tu imagen:
func _on_btn_cerrar_ajustes_pressed() -> void:
	toggle_menu_ajustes()
