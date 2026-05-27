extends Area3D

signal mision_pisada(id_mision, numero_checkpoint)

@export var id_mision_asociada: String = "correra_01"
@export var numero_checkpoint: int = 1  # <-- META = 0, SIGUIENTE = 1, SIGUIENTE = 2...

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D):
	if body.name == "VehicleBody3D": 
		# Enviamos el ID de la carrera Y el número de checkpoint que se ha pisado
		mision_pisada.emit(id_mision_asociada, numero_checkpoint)
