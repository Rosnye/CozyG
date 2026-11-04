extends Control
## Menú principal: continuar, nueva partida, ajustes y salir.

const ESCENA_JUEGO: String = "res://scenes/juego.tscn"
const RUTA_GUARDADO: String = "user://guardado.json"

@onready var _caja: Control = %Caja
@onready var _continuar: Button = %Continuar
@onready var _salir: Button = %Salir
@onready var _ajustes: AjustesPanel = %Ajustes
@onready var _confirmacion: ConfirmationDialog = %Confirmacion


func _ready() -> void:
	Pantalla.vigilar(get_window())
	Preferencias.iniciar()
	_continuar.visible = FileAccess.file_exists(RUTA_GUARDADO)
	# En el navegador no hay nada que cerrar.
	_salir.visible = not OS.has_feature("web")
	_ajustes.visible = false
	_continuar.pressed.connect(_al_continuar)
	%NuevaPartida.pressed.connect(_al_pedir_nueva)
	%BotonAjustes.pressed.connect(_abrir_ajustes)
	_salir.pressed.connect(func() -> void: get_tree().quit())
	_ajustes.cerrado.connect(_cerrar_ajustes)
	_confirmacion.confirmed.connect(_empezar_de_cero)


func _al_continuar() -> void:
	get_tree().change_scene_to_file(ESCENA_JUEGO)


func _al_pedir_nueva() -> void:
	# Solo se pide confirmación si hay una partida que se perdería.
	if FileAccess.file_exists(RUTA_GUARDADO):
		_confirmacion.popup_centered()
	else:
		_empezar_de_cero()


func _empezar_de_cero() -> void:
	DirAccess.remove_absolute(RUTA_GUARDADO)
	get_tree().change_scene_to_file(ESCENA_JUEGO)


func _abrir_ajustes() -> void:
	_caja.visible = false
	_ajustes.visible = true


func _cerrar_ajustes() -> void:
	_ajustes.visible = false
	_caja.visible = true
