extends Camera3D

@export var altura: float = 300.0
@export var tamano_vista: float = 500.0
@export var suavidad: float = 5.0

var jugador: Node3D

func _ready():
	projection = Camera3D.PROJECTION_ORTHOGONAL
	size = tamano_vista
	position.y = altura
	rotation.x = -PI / 2
	near = 0.1
	far = 1000.0

func _process(delta):
	if not jugador:
		var nodos = get_tree().get_nodes_in_group("player")
		if nodos.size() > 0:
			jugador = nodos[0]
		return

	var objetivo = Vector3(jugador.global_position.x, altura, jugador.global_position.z)
	global_position = global_position.lerp(objetivo, delta * suavidad)
