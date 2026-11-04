class_name AjustesPanel
extends PanelContainer
## Panel de ajustes (volúmenes). Se usa en el menú principal y en la pausa.

signal cerrado

@onready var _musica: HSlider = %Musica
@onready var _efectos: HSlider = %Efectos


func _ready() -> void:
	Preferencias.iniciar()
	_musica.value = Preferencias.volumen_musica
	_efectos.value = Preferencias.volumen_efectos
	_musica.value_changed.connect(Preferencias.fijar_musica)
	_efectos.value_changed.connect(Preferencias.fijar_efectos)
	_musica.drag_ended.connect(func(_cambio: bool) -> void: Preferencias.guardar())
	_efectos.drag_ended.connect(func(_cambio: bool) -> void: Preferencias.guardar())
	%Volver.pressed.connect(_al_volver)


func _al_volver() -> void:
	Preferencias.guardar()
	cerrado.emit()
