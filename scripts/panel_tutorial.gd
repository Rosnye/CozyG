class_name PanelTutorial
extends PanelContainer
## Cuadro de texto del mini tutorial, con "Saltar tutorial" siempre a mano.
## No decide nada: avisa con señales y `juego.gd` mueve el tutorial.

signal siguiente_pedido
signal saltar_pedido

var _texto: Label
var _principal: Button


func _ready() -> void:
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 10)
	add_child(caja)
	_texto = Label.new()
	_texto.theme_type_variation = &"EtiquetaPequena"
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.custom_minimum_size = Vector2(560, 0)
	caja.add_child(_texto)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	caja.add_child(fila)
	var saltar := Button.new()
	saltar.theme_type_variation = &"BotonPequeno"
	saltar.text = "Saltar tutorial"
	saltar.pressed.connect(func() -> void: saltar_pedido.emit())
	fila.add_child(saltar)
	var espacio := Control.new()
	espacio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(espacio)
	_principal = Button.new()
	_principal.theme_type_variation = &"BotonPequeno"
	_principal.pressed.connect(func() -> void: siguiente_pedido.emit())
	fila.add_child(_principal)
	visible = false


func mostrar(texto: String, con_boton: bool, texto_boton: String) -> void:
	_texto.text = texto
	_principal.visible = con_boton
	_principal.text = texto_boton
	visible = true


func ocultar() -> void:
	visible = false
