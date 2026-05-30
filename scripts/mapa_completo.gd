extends CanvasLayer

@export var altura_mapa: float = 800.0
@export var tamano_vista_mapa: float = 2500.0
@export var tecla_mapa: String = "mapa"

var mapa_activo: bool = false
var camera_mapa: Camera3D
var viewport_mapa: SubViewport
var panel_mapa: PanelContainer
var jugador: Node3D

func _ready():
	layer = 10
	visible = false
	_crear_ui()
	_crear_viewport()
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	if event.is_action_pressed(tecla_mapa):
		toggle_mapa()

func toggle_mapa():
	mapa_activo = !mapa_activo
	visible = mapa_activo
	get_tree().paused = mapa_activo

func _process(delta):
	if not mapa_activo:
		return

	if not jugador:
		var nodos = get_tree().get_nodes_in_group("player")
		if nodos.size() > 0:
			jugador = nodos[0]
		return

	if camera_mapa:
		camera_mapa.global_position.x = jugador.global_position.x
		camera_mapa.global_position.z = jugador.global_position.z

func _crear_ui():
	panel_mapa = PanelContainer.new()
	panel_mapa.name = "PanelMapa"
	panel_mapa.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_mapa.mouse_filter = Control.MOUSE_FILTER_STOP

	var estilo = StyleBoxFlat.new()
	estilo.bg_color = Color(0.0, 0.0, 0.0, 0.85)
	panel_mapa.add_theme_stylebox_override("panel", estilo)

	add_child(panel_mapa)

	var label_titulo = Label.new()
	label_titulo.text = "MAPA - Pulsa M para cerrar"
	label_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_titulo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	label_titulo.offset_bottom = 40
	label_titulo.add_theme_font_size_override("font_size", 20)
	panel_mapa.add_child(label_titulo)

	var viewport_texture = SubViewportContainer.new()
	viewport_texture.name = "ViewportContainer"
	viewport_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewport_texture.offset_top = 50
	viewport_texture.offset_bottom = -10
	viewport_texture.offset_left = 10
	viewport_texture.offset_right = -10
	viewport_texture.stretch = true
	panel_mapa.add_child(viewport_texture)

	viewport_mapa = SubViewport.new()
	viewport_mapa.name = "SubViewportMapa"
	viewport_mapa.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_mapa.transparent_bg = false
	viewport_mapa.size = Vector2i(1920, 1080)
	viewport_texture.add_child(viewport_mapa)

	camera_mapa = Camera3D.new()
	camera_mapa.name = "CameraMapa"
	camera_mapa.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera_mapa.size = tamano_vista_mapa
	camera_mapa.position.y = altura_mapa
	camera_mapa.rotation.x = -PI / 2
	camera_mapa.near = 0.1
	camera_mapa.far = 2000.0
	viewport_mapa.add_child(camera_mapa)

	var btn_cerrar = Button.new()
	btn_cerrar.text = "X"
	btn_cerrar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn_cerrar.offset_left = -50
	btn_cerrar.offset_right = -10
	btn_cerrar.offset_top = 5
	btn_cerrar.offset_bottom = 35
	btn_cerrar.pressed.connect(toggle_mapa)
	panel_mapa.add_child(btn_cerrar)

func _crear_viewport():
	pass
