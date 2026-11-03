extends Node
## Escena de juego: une el tablero (lógica), la vista, la cámara y la interfaz.
## Flujo: tocar un hueco -> pieza fantasma -> girar -> confirmar -> siguiente pieza.

const CARPETA_PIEZAS: String = "res://data/piezas"
const PIEZA_INICIAL: StringName = &"prado"

var _tablero := Tablero.new()
var _mazo: Mazo
var _pieza_actual: PiezaDatos
var _giro: int = 0
var _hay_pendiente: bool = false
var _pendiente: Vector2i = Vector2i.ZERO

@onready var _vista: TableroVista = $Tablero
@onready var _camara: CamaraControl = $Camara
@onready var _barra: PanelContainer = $Interfaz/Barra
@onready var _muestra: ColorRect = %Muestra
@onready var _nombre: Label = %Nombre
@onready var _contador: Label = %Contador
@onready var _girar: Button = %Girar
@onready var _confirmar: Button = %Confirmar


func _ready() -> void:
	var piezas: Array[PiezaDatos] = _cargar_piezas()
	_mazo = Mazo.new(piezas)
	_vista.tablero = _tablero
	_colocar_pieza_inicial(piezas)
	_robar()
	_camara.toque.connect(_al_tocar_mundo)
	_girar.pressed.connect(_al_girar)
	_confirmar.pressed.connect(_al_confirmar)
	_muestra.pivot_offset = _muestra.custom_minimum_size / 2.0
	_actualizar_interfaz()


func _unhandled_key_input(evento: InputEvent) -> void:
	if evento is InputEventKey and evento.pressed and not evento.echo:
		if evento.keycode == KEY_R:
			_al_girar()
		elif evento.keycode == KEY_ENTER or evento.keycode == KEY_SPACE:
			_al_confirmar()


func _cargar_piezas() -> Array[PiezaDatos]:
	var resultado: Array[PiezaDatos] = []
	for archivo in DirAccess.get_files_at(CARPETA_PIEZAS):
		# En una exportación los recursos aparecen como "nombre.tres.remap".
		var nombre: String = archivo.trim_suffix(".remap")
		if nombre.ends_with(".tres"):
			var pieza := load(CARPETA_PIEZAS + "/" + nombre) as PiezaDatos
			if pieza != null:
				resultado.append(pieza)
	resultado.sort_custom(func(a: PiezaDatos, b: PiezaDatos) -> bool: return a.id < b.id)
	return resultado


func _colocar_pieza_inicial(piezas: Array[PiezaDatos]) -> void:
	var inicial: PiezaDatos = null
	for pieza in piezas:
		if pieza.id == PIEZA_INICIAL:
			inicial = pieza
	if inicial == null:
		inicial = _mazo.robar()
	_tablero.colocar(Vector2i.ZERO, inicial)


func _robar() -> void:
	_pieza_actual = _mazo.robar()
	_giro = 0


func _al_tocar_mundo(posicion_pantalla: Vector2, posicion_mundo: Vector2) -> void:
	if _barra.get_global_rect().has_point(posicion_pantalla):
		return
	var coord: Vector2i = Hex.pixel_a_axial(posicion_mundo, _vista.tamano_hex)
	if not _tablero.puede_colocar(coord):
		return
	_hay_pendiente = true
	_pendiente = coord
	_actualizar_interfaz()


func _al_girar() -> void:
	_giro = posmod(_giro + 1, 6)
	_actualizar_interfaz()


func _al_confirmar() -> void:
	if not _hay_pendiente:
		return
	_tablero.colocar(_pendiente, _pieza_actual, _giro)
	_hay_pendiente = false
	_robar()
	_actualizar_interfaz()


func _actualizar_interfaz() -> void:
	_nombre.text = _pieza_actual.nombre
	_contador.text = "Piezas: %d" % _tablero.cantidad()
	_muestra.color = _pieza_actual.color
	_muestra.rotation_degrees = 60.0 * _giro
	_confirmar.disabled = not _hay_pendiente
	if _hay_pendiente:
		_vista.mostrar_pendiente(_pendiente, _pieza_actual, _giro)
	else:
		_vista.ocultar_pendiente()
	_vista.queue_redraw()
