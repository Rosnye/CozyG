class_name PanelConstruccion
extends PanelContainer
## Panel para construir sobre la pieza elegida, o ver y quitar lo que ya hay.
## No decide nada: avisa con señales y `juego.gd` aplica los cambios a `Economia`.

signal construir_pedido(construccion: ConstruccionDatos)
signal quitar_pedido
signal cerrado

var _titulo: Label
var _rejilla: GridContainer
var _quitar: Button
var _botones: Array[Dictionary] = []  # { "boton": Button, "construccion": ConstruccionDatos }
var _coord: Vector2i = Vector2i.ZERO
var _nombres_recursos: Dictionary = {}


func _ready() -> void:
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 10)
	add_child(caja)
	_titulo = Label.new()
	_titulo.theme_type_variation = &"EtiquetaPequena"
	caja.add_child(_titulo)
	_rejilla = GridContainer.new()
	_rejilla.columns = 2
	_rejilla.add_theme_constant_override("h_separation", 10)
	_rejilla.add_theme_constant_override("v_separation", 10)
	caja.add_child(_rejilla)
	_quitar = Button.new()
	_quitar.theme_type_variation = &"BotonPequeno"
	_quitar.text = "Quitar (devuelve la mitad)"
	_quitar.custom_minimum_size = Vector2(0, 72)
	_quitar.pressed.connect(func() -> void: quitar_pedido.emit())
	caja.add_child(_quitar)
	var cerrar := Button.new()
	cerrar.theme_type_variation = &"BotonPequeno"
	cerrar.text = "Cerrar"
	cerrar.custom_minimum_size = Vector2(0, 72)
	cerrar.pressed.connect(func() -> void: cerrado.emit())
	caja.add_child(cerrar)
	visible = false


## `nombres_recursos` mapea id de recurso -> nombre para mostrar los costos.
func configurar(nombres_recursos: Dictionary) -> void:
	_nombres_recursos = nombres_recursos


func mostrar(coord: Vector2i, pieza: PiezaDatos, actual: ConstruccionDatos, catalogo: Array[ConstruccionDatos], economia: Economia, tablero: Tablero) -> void:
	_coord = coord
	for hijo in _rejilla.get_children():
		hijo.queue_free()
	_botones.clear()
	var iguales: int = tablero.vecinas_iguales(coord, pieza)
	var bonus: String = "" if iguales == 0 else " · %d vecinas iguales (+%d%%)" % [iguales, roundi(iguales * Economia.BONO_VECINA * 100.0)]
	if actual != null:
		_titulo.text = "%s · %s/min (%d%%)%s" % [
			actual.nombre, _formatear(economia.por_minuto_en(coord, actual, tablero)),
			roundi(Economia.eficiencia(actual, pieza) * 100.0), bonus,
		]
		_rejilla.visible = false
		_quitar.visible = true
	else:
		_titulo.text = "%s: %s%s" % [pieza.nombre, _describir_bordes(pieza), bonus]
		_rejilla.visible = true
		_rejilla.columns = _columnas()
		_quitar.visible = false
		for construccion in catalogo:
			var boton := Button.new()
			boton.theme_type_variation = &"BotonPequeno"
			boton.text = _texto_boton(construccion, pieza)
			boton.custom_minimum_size = Vector2(0, 72)
			boton.pressed.connect(func() -> void: construir_pedido.emit(construccion))
			_rejilla.add_child(boton)
			_botones.append({"boton": boton, "construccion": construccion})
	visible = true
	refrescar(economia, tablero)


## Una columna en pantallas estrechas (móvil en vertical), tres en las anchas y bajitas
## (móvil en horizontal, para no tapar el mapa) y dos en el resto.
func _columnas() -> int:
	var tamano: Vector2 = get_viewport_rect().size
	if tamano.x < 760.0:
		return 1
	if tamano.y < 620.0:
		return 3
	return 2


func ocultar() -> void:
	visible = false


## El botón de una construcción (para guiar al jugador), o null si no está.
func boton_de(id: StringName) -> Button:
	for entrada in _botones:
		if (entrada["construccion"] as ConstruccionDatos).id == id:
			return entrada["boton"]
	return null


## Activa o desactiva los botones según lo que se pueda pagar ahora.
func refrescar(economia: Economia, tablero: Tablero) -> void:
	for entrada in _botones:
		(entrada["boton"] as Button).disabled = not economia.puede_construir(_coord, entrada["construccion"], tablero)


func _texto_boton(construccion: ConstruccionDatos, pieza: PiezaDatos) -> String:
	var rendimiento: float = Economia.eficiencia(construccion, pieza)
	var linea: String
	if rendimiento <= 0.0:
		linea = "no rinde aquí"
	else:
		linea = "%s · %d%%" % [_describir_costo(construccion.costo), roundi(rendimiento * 100.0)]
	return "%s\n%s" % [construccion.nombre, linea]


func _describir_costo(costo: Dictionary) -> String:
	var partes: PackedStringArray = []
	for id: StringName in costo:
		partes.append("%d %s" % [int(costo[id]), String(_nombres_recursos.get(id, id)).to_lower()])
	return ", ".join(partes) if not partes.is_empty() else "gratis"


func _describir_bordes(pieza: PiezaDatos) -> String:
	var cuenta: Dictionary = {}
	for direccion in 6:
		var terreno: StringName = pieza.borde(direccion)
		cuenta[terreno] = int(cuenta.get(terreno, 0)) + 1
	var partes: PackedStringArray = []
	for terreno: StringName in cuenta:
		partes.append("%s ×%d" % [terreno, cuenta[terreno]])
	return ", ".join(partes)


func _formatear(valor: float) -> String:
	return ("%.1f" % valor).trim_suffix(".0")
