extends Control

# --- Referencias a los Nodos ---
# Usamos @onready para obtener los nodos cuando la escena carga.
# Asegúrate de que tus nodos en la escena se llamen exactamente "Play" y "Ajustes".
@onready var play_btn = $Play
@onready var tutorial_btn = $Tutorial
@onready var ajustes_btn = $Ajustes
@onready var exit_btn = $Exit
# --- Variables Exportadas ---
# Aquí arrastrarás tu escena de nivel (.tscn) desde el inspector
@export_file("*.tscn") var escena_del_juego: String
@export_file("*.tscn") var mainmenu: String
@export_file("*.tscn") var escena_del_tutorial: String
# --- Función de Inicio ---
func _ready() -> void:
	# Verificamos si los botones existen para evitar errores
	if play_btn and ajustes_btn and exit_btn:
		# 1. Conectamos las señales de clic
		play_btn.pressed.connect(_on_play_pressed)
		tutorial_btn.pressed.connect(_on_tutorial_pressed)
		ajustes_btn.pressed.connect(_on_ajustes_pressed)
		exit_btn.pressed.connect(_on_exit_pressed)
		# 2. Configuración del Cursor (Manita)
		play_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tutorial_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		ajustes_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		exit_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		# 3. Configuración para MANDO / TECLADO
		# Le decimos al botón Play que agarre el foco (que esté seleccionado por defecto)
		play_btn.grab_focus()
		
		# Configuramos los "vecinos" para que el mando sepa a dónde ir
		# Si presionas ABAJO en Play, vas a Ajustes
		play_btn.focus_neighbor_bottom = tutorial_btn.get_path()
		tutorial_btn.focus_neighbor_bottom = ajustes_btn.get_path()
		# Si presionas ARRIBA en Ajustes, vas a Play
		ajustes_btn.focus_neighbor_top = tutorial_btn.get_path()
		exit_btn.focus_neighbor_top = ajustes_btn.get_path()
		
	else:
		printerr("Error: No se encontraron los nodos 'Play' o 'Ajustes'. Revisa los nombres en la escena.")


# --- Lógica de Botones ---

func _on_play_pressed() -> void:
	print("¡Jugar!")
	
	# Verificamos si hay una escena asignada
	if escena_del_juego != "":
		# Cambiamos a la escena del juego
		get_tree().change_scene_to_file(escena_del_juego)
	else:
		printerr("Error: No has asignado la 'Escena del Juego' en el Inspector del nodo MainMenu.")

func _on_tutorial_pressed() -> void:
	print("📘 Botón Tutorial presionado")
	_cambiar_a_escena(escena_del_tutorial, "Escena del Tutorial")


func _on_ajustes_pressed() -> void:
	print("⚙️ Botón Ajustes presionado")
	# Antes era copy-paste de play: validaba escena_del_juego pero cargaba mainmenu.
	# Ahora valida la escena a la que realmente va (mainmenu).
	_cambiar_a_escena(mainmenu, "mainmenu")


# Helper compartido: evita el copy-paste que tenía antes y centraliza el mensaje de error.
func _cambiar_a_escena(ruta: String, nombre_campo: String) -> void:
	if ruta != "":
		get_tree().change_scene_to_file(ruta)
		return
	printerr("Error: No has asignado '", nombre_campo, "' en el Inspector del nodo MainMenu.")
	
func _on_exit_pressed() -> void:
	get_tree().quit()
	


func _on_borrarpartidas_pressed() -> void:
	DatosJuego.eliminar_partida()
	pass # Replace with function body.
