extends Area3D

signal mision_pisada(id_mision, numero_checkpoint)

@export var id_mision_asociada: String = "correra_01"

# META = 0
# CP1 = 1
# CP2 = 2
# CP3 = 3...
@export var numero_checkpoint: int = 0


func _ready():
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D):

	# Solo el jugador
	if !body.is_in_group("player"):
		return

	print("Misión:", id_mision_asociada)
	print("Checkpoint:", numero_checkpoint)

	mision_pisada.emit(
		id_mision_asociada,
		numero_checkpoint
	)
