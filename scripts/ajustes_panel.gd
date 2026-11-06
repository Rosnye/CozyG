class_name AjustesPanel
extends PanelContainer
## Panel de ajustes (sonido, idioma, accesibilidad). Se usa en el menú principal y en la pausa.
## Las opciones van en una zona desplazable que nunca pasa del alto de la pantalla.

signal cerrado
## La ayuda para daltonismo cambió: quien dibuja el tablero debe redibujarlo.
signal ayuda_color_cambiada

## Hueco que se deja arriba y abajo del panel, en unidades de la interfaz.
const MARGEN_PANTALLA: float = 24.0

@onready var _musica: HSlider = %Musica
@onready var _efectos: HSlider = %Efectos
@onready var _tutorial: CheckButton = %Tutorial
@onready var _idioma: OptionButton = %Idioma
@onready var _texto: OptionButton = %Texto
@onready var _ayuda_color: CheckButton = %AyudaColor
@onready var _desplazable: ScrollContainer = %Desplazable
@onready var _opciones: VBoxContainer = %Opciones

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
	_texto.item_selected.connect(_al_elegir_texto)
	_rellenar_textos()
	_ayuda_color.button_pressed = Preferencias.ayuda_color
	_ayuda_color.toggled.connect(_al_cambiar_ayuda_color)
	%Volver.pressed.connect(_al_volver)
	get_viewport().size_changed.connect(_ajustar_alto)
	_opciones.minimum_size_changed.connect(_ajustar_alto)
	visibility_changed.connect(_ajustar_alto)
	_ajustar_alto.call_deferred()


func _notification(motivo: int) -> void:
	# Al cambiar el idioma se vuelve a escribir la entrada "Automático".
	if motivo == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_rellenar_idiomas()
		_rellenar_textos()


## La zona de opciones mide lo que necesita, salvo que no quepa en la pantalla:
## entonces se limita y se desplaza (con el dedo o la rueda).
func _ajustar_alto() -> void:
	if not is_node_ready() or not is_inside_tree():
		return
	var resto: float = get_combined_minimum_size().y - _desplazable.custom_minimum_size.y
	var disponible: float = get_viewport_rect().size.y - 2.0 * MARGEN_PANTALLA - resto
	var alto: float = clampf(_opciones.get_combined_minimum_size().y, 0.0, maxf(disponible, 120.0))
	if not is_equal_approx(_desplazable.custom_minimum_size.y, alto):
		_desplazable.custom_minimum_size.y = alto


func _rellenar_textos() -> void:
	_texto.clear()
	_texto.add_item(tr("Normal"))
	_texto.add_item(tr("Grande"))
	_texto.add_item(tr("Muy grande"))
	_texto.select(maxi(Accesibilidad.ESCALAS_TEXTO.find(Preferencias.escala_texto), 0))


func _al_elegir_texto(indice: int) -> void:
	Preferencias.fijar_escala_texto(Accesibilidad.ESCALAS_TEXTO[indice])
	Preferencias.guardar()


func _al_cambiar_ayuda_color(activo: bool) -> void:
	Preferencias.ayuda_color = activo
	Preferencias.guardar()
	ayuda_color_cambiada.emit()


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
