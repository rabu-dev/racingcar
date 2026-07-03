extends Area3D

# Esta variable controlará si el jugador está pisando la zona o no
var jugador_dentro: bool = false

func _ready() -> void:
	# Conectamos las señales por código (o puedes hacerlo desde el editor)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

# Se ejecuta automáticamente cada vez que el jugador pulsa cualquier tecla
func _unhandled_input(event: InputEvent) -> void:
	# Si el jugador está dentro del área Y pulsa la tecla que configuramos ("interactuar")
	if jugador_dentro and event.is_action_pressed("interactuar"):
		entrar_al_garaje()

# Detecta cuando el coche entra en el área
func _on_body_entered(body: Node3D) -> void:
	# Aquí puedes comprobar si el cuerpo que entra es el coche del jugador
	# Por ejemplo: if body.name == "VehicleBod":
	if body is VehicleBody3D: # O el tipo de nodo que sea tu coche
		jugador_dentro = true
		Notificaciones.mostrar_notificacion("Presiona 'E' para entrar al garaje", 3.5) # Durará 3.5 segundos en pantalla
		#print("Presiona 'E' para entrar al garaje") # esto una notificacion

# Detecta cuando el coche sale del área
func _on_body_exited(body: Node3D) -> void:
	if body is VehicleBody3D:
		jugador_dentro = false
		

# La función que realiza el cambio de escena
func entrar_al_garaje() -> void:
	# Cambia esto por la ruta real de tu escena del garaje
	get_tree().change_scene_to_file("res://escena/garaje/Garaje.tscn")
