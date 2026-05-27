extends Control

# Usamos Nombres Únicos de Escena (%) para evitar errores de rutas
@onready var fullscreen_check = $PanelContainer/VBoxContainer/TabContainer/VBoxContainer/HBoxContainer2/CheckBox
@onready var resolution_options = $PanelContainer/VBoxContainer/TabContainer/VBoxContainer/HBoxContainer/OptionButton
@onready var volume_slider = $PanelContainer/VBoxContainer/TabContainer/VBoxContainer/VBoxContainer/HBoxContainer/HSlider
@onready var save_button = $PanelContainer/VBoxContainer/TabContainer/VBoxContainer/Button 

@export_file("*.tscn") var mainmenu: String  

# Lista estática de resoluciones soportadas
const RESOLUTIONS = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]

func _ready():
	# 1. Inicializar los valores visuales desde el ConfigManager
	fullscreen_check.button_pressed = ConfigManager.settings["video"]["fullscreen"]
	volume_slider.value = ConfigManager.settings["audio"]["master_volume"]
	
	# 2. Rellenar el OptionButton de resoluciones
	resolution_options.clear()
	for res in RESOLUTIONS:
		resolution_options.add_item(str(res.x) + " x " + str(res.y))
	
	# 3. Seleccionar el índice de la resolución actual
	var current_res = ConfigManager.settings["video"]["resolution"]
	var index = RESOLUTIONS.find(current_res)
	if index != -1:
		resolution_options.selected = index
	else:
		resolution_options.selected = 0
		
	# 4. Conectar las señales por código para asegurar que no fallen
	fullscreen_check.toggled.connect(_on_fullscreen_check_toggled)
	resolution_options.item_selected.connect(_on_resolution_options_item_selected)
	volume_slider.value_changed.connect(_on_volume_slider_value_changed)
	save_button.pressed.connect(_on_save_button_pressed)

# --- MANEJO DE EVENTOS ---

func _on_fullscreen_check_toggled(toggled_on: bool):
	ConfigManager.settings["video"]["fullscreen"] = toggled_on
	# Si activamos pantalla completa, el OptionButton de resolución se debería desactivar temporalmente
	resolution_options.disabled = toggled_on
	ConfigManager.apply_settings()

func _on_resolution_options_item_selected(index: int):
	var selected_res = RESOLUTIONS[index]
	ConfigManager.settings["video"]["resolution"] = selected_res
	ConfigManager.apply_settings()

func _on_volume_slider_value_changed(value: float):
	ConfigManager.settings["audio"]["master_volume"] = int(value)
	ConfigManager.apply_settings()

func _on_save_button_pressed():
	ConfigManager.save_settings()
	get_tree().change_scene_to_file(mainmenu)
	# Aquí puedes añadir código para cerrar el menú, por ejemplo:
	# queue_free() o cambiar de escena
