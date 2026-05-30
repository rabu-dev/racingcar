extends Node

const SAVE_PATH = "user://settings.cfg"
var config = ConfigFile.new()

# Diccionario global con los valores actuales de configuración
var settings = {
	"video": {
		"fullscreen": false,
		"resolution": Vector2i(1280, 720)
	},
	"audio": {
		"master_volume": 100
	}
}

func _ready():
	load_settings()

func save_settings():
	# Guardamos los valores del diccionario en el archivo .cfg
	for section in settings.keys():
		for key in settings[section].keys():
			config.set_value(section, key, settings[section][key])
	config.save(SAVE_PATH)
	print("ConfigManager: Ajustes guardados correctamente en ", SAVE_PATH)
	apply_settings()

func load_settings():
	if config.load(SAVE_PATH) != OK:
		# Si el archivo no existe (primera vez que se abre el juego), guardamos los de por defecto
		print("ConfigManager: No se encontró archivo de guardado. Creando uno por defecto...")
		save_settings()
		return
	
	# Cargamos los valores leyendo el archivo .cfg
	for section in settings.keys():
		for key in settings[section].keys():
			settings[section][key] = config.get_value(section, key, settings[section][key])
	print("ConfigManager: Ajustes cargados con éxito.")
	apply_settings()

func apply_settings():
	# 1. Aplicar Configuración de Vídeo
	if settings["video"]["fullscreen"]:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(settings["video"]["resolution"])
		# Opcional: Centrar la ventana en la pantalla al cambiar el tamaño
		var screen_size = DisplayServer.screen_get_size()
		var window_size = settings["video"]["resolution"]
		DisplayServer.window_set_position(screen_size / 2 - window_size / 2)
	
	# 2. Aplicar Configuración de Audio
	var bus_index = AudioServer.get_bus_index("Master")
	if bus_index != -1:
		# Convertimos el valor lineal (0-100) a Decibelios logarítmicos para el oído humano
		var volume_db = linear_to_db(settings["audio"]["master_volume"] / 100.0)
		AudioServer.set_bus_volume_db(bus_index, volume_db)
