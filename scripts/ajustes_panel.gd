class_name AjustesPanel
extends PanelContainer
## Panel de ajustes (volúmenes). Se usa en el menú principal y en la pausa.

signal cerrado

@onready var _musica: HSlider = %Musica
@onready var _efectos: HSlider = %Efectos
@onready var _tutorial: CheckButton = %Tutorial
@onready var _idioma: OptionButton = %Idioma

## Opciones del selector de idioma, en el mismo orden que sus entradas.
const OPCIONES_IDIOMA: Array[String] = [Idioma.AUTOMATICO, "es", "en"]


func _ready() -> void:
	Preferencias.iniciar()
	_musica.value = Preferencias.volumen_musica
	_efectos.value = Preferencias.volumen_efectos
	_musica.value_changed.connect(Preferencias.fijar_musica)
	_efectos.value_changed.connect(Preferencias.fijar_efectos)
	_musica.drag_ended.connect(func(_cambio: bool) -> void: Preferencias.guardar())
	_efectos.drag_ended.connect(func(_cambio: bool) -> void: Preferencias.guardar())
	_tutorial.button_pressed = Preferencias.mostrar_tutorial
	_tutorial.toggled.connect(_al_cambiar_tutorial)
	_idioma.item_selected.connect(_al_elegir_idioma)
	_rellenar_idiomas()
	%Volver.pressed.connect(_al_volver)


func _notification(motivo: int) -> void:
	# Al cambiar el idioma se vuelve a escribir la entrada "Automático".
	if motivo == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_rellenar_idiomas()


## Los nombres de los idiomas van en su propio idioma; solo "Automático" se traduce.
func _rellenar_idiomas() -> void:
	_idioma.clear()
	_idioma.add_item(tr("Automático"))
	_idioma.add_item("Español")
	_idioma.add_item("English")
	_idioma.select(maxi(OPCIONES_IDIOMA.find(Preferencias.idioma), 0))


func _al_elegir_idioma(indice: int) -> void:
	Preferencias.fijar_idioma(OPCIONES_IDIOMA[indice])
	Preferencias.guardar()


func _al_cambiar_tutorial(activo: bool) -> void:
	Preferencias.mostrar_tutorial = activo
	Preferencias.guardar()


func _al_volver() -> void:
	Preferencias.guardar()
	cerrado.emit()
