extends Node3D

# Buscamos la malla del coche. Ojo: reemplaza "MeshInstance3D" por el nombre 
# exacto del nodo tipo MeshInstance3D que sea el chasis dentro de VehicleBody3D.
@onready var chasis_mesh: MeshInstance3D = $VehicleBody3D/MeshInstance3D

@onready var DineroMenu: Label = $Control/Panel/VBoxContainer2/DineroMenu

func _ready() -> void:
	# Al entrar al garaje, forzamos que el coche visualice el color que esté guardado
	actualizar_color_visual()
	# Actualizamos el texto de la interfaz con el dinero actual
	actualizar_interfaz_dinero()
	

# --- FUNCIÓN AUXILIAR DE INTERFAZ ---

func actualizar_interfaz_dinero() -> void:
	if DineroMenu:
		DineroMenu.text = "Dinero: $" + str(DatosJuego.dinero)


# --- SEÑALES DE LOS BOTONES ---

# Conecta la señal 'pressed()' de tu botón azul de la UI aquí:
func _on_btn_azul_pressed() -> void:
	_intentar_cambiar_color(Color.BLUE, "azul")


# Conecta la señal 'pressed()' de tu botón rojo de la UI aquí:
func _on_btn_rojo_pressed() -> void:
	_intentar_cambiar_color(Color.RED, "rojo")


# Conecta la señal 'pressed()' de tu botón amarillo de la UI aquí:
func _on_btn_amarillo_pressed() -> void:
	_intentar_cambiar_color(Color.YELLOW, "amarillo")


# Centraliza la compra de pintura: protege contra chasis_mesh null, material null,
# y contra comprar un color que ya está aplicado.
func _intentar_cambiar_color(color: Color, nombre: String) -> void:
	if not chasis_mesh:
		push_warning("garaje.gd: chasis_mesh no encontrado (revisa la ruta @onready del nodo).")
		return
	var material = chasis_mesh.get_active_material(0)
	if not material is StandardMaterial3D:
		push_warning("garaje.gd: el material de la malla no es StandardMaterial3D.")
		return

	if material.albedo_color == color:
		Notificaciones.mostrar_notificacion("El coche ya está de color %s" % nombre, 3.0)
		return

	if DatosJuego.cambiar_color(color):
		actualizar_color_visual()
		actualizar_interfaz_dinero()
		#print("¡Color cambiado a %s!" % nombre)


# Conecta la señal 'pressed()' de tu botón de mejoras aquí:
func _on_btn_mejorar_motor_pressed() -> void:
	if DatosJuego.mejorar_motor():
		actualizar_interfaz_dinero() # Actualiza la UI tras gastar dinero en el motor
		#print("¡Motor mejorado con éxito! Nivel actual: ", DatosJuego.nivel_motor)
		#print("Dinero restante: ", DatosJuego.dinero)
	else:
		printerr("No tienes suficiente dinero o ya alcanzaste el nivel máximo.")


# Conecta la señal 'pressed()' de tu botón de cambiar de escena aquí:
func _on_btn_jugar_pressed() -> void:
	# Cambia esta ruta por la de tu escena de carrera (.tscn)
	get_tree().change_scene_to_file("res://escena/escenas de pruebas.tscn")


# --- FUNCIÓN AUXILIAR DE RENDER ---

func actualizar_color_visual() -> void:
	if chasis_mesh:
		# Obtenemos el material asignado al primer slot (0) de la malla
		var material = chasis_mesh.get_active_material(0)
		
		if material is StandardMaterial3D:
			# Modificamos el color albedo en tiempo real utilizando el Singleton
			material.albedo_color = DatosJuego.color_coche
		else:
			push_warning("El material de la malla no es un StandardMaterial3D.")
