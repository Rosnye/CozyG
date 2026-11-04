extends Node
## Escena de juego: une el tablero (lógica), la vista, la cámara y la interfaz.
## Flujo: tocar un hueco -> pieza fantasma -> girar -> confirmar -> siguiente pieza.
## Se puede colocar aunque no encaje; encajar bien se recompensa. Guarda tras cada pieza.

const CARPETA_PIEZAS: String = "res://data/piezas"
const RUTA_GUARDADO: String = "user://guardado.json"
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
@onready var _muestra: PiezaPreview = %Muestra
@onready var _nombre: Label = %Nombre
@onready var _contador: Label = %Contador
@onready var _encaje: Label = %Encaje
@onready var _girar: Button = %Girar
@onready var _confirmar: Button = %Confirmar
@onready var _sonido_encaje: AudioStreamPlayer = $SonidoEncaje
@onready var _sonido_colocar: AudioStreamPlayer = $SonidoColocar


func _ready() -> void:
	var piezas: Array[PiezaDatos] = _cargar_piezas()
	_mazo = Mazo.new(piezas)
	_muestra.terrenos = _vista.terrenos
	_iniciar_partida(piezas)
	_vista.tablero = _tablero
	_camara.toque.connect(_al_tocar_mundo)
	_girar.pressed.connect(_al_girar)
	_confirmar.pressed.connect(_al_confirmar)
	_actualizar_interfaz()


func _notification(motivo: int) -> void:
	# Cerrar la ventana o mandar la app a segundo plano también guarda.
	if motivo == NOTIFICATION_WM_CLOSE_REQUEST or motivo == NOTIFICATION_APPLICATION_PAUSED \
			or motivo == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_guardar()


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


## Carga la partida guardada o empieza una nueva con la pieza inicial en el centro.
func _iniciar_partida(piezas: Array[PiezaDatos]) -> void:
	var por_id: Dictionary = {}
	for pieza in piezas:
		por_id[pieza.id] = pieza
	var cargada := Guardado.desde_diccionario(Guardado.leer(RUTA_GUARDADO), por_id)
	if not cargada.is_empty():
		_tablero = cargada["tablero"]
		_pieza_actual = por_id.get(cargada["pieza_actual"])
		if _pieza_actual == null:
			_robar()
		return
	_tablero.colocar(Vector2i.ZERO, por_id.get(PIEZA_INICIAL, _mazo.robar()))
	_robar()


func _guardar() -> void:
	if _pieza_actual != null:
		Guardado.guardar(RUTA_GUARDADO, Guardado.a_diccionario(_tablero, _pieza_actual.id))


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
	var perfecta: bool = _tablero.encaja_perfecto(_pendiente, _pieza_actual, _giro)
	var coord: Vector2i = _pendiente
	_tablero.colocar(coord, _pieza_actual, _giro)
	_hay_pendiente = false
	_robar()
	_vista.animar_colocacion(coord, perfecta)
	if perfecta:
		_sonido_encaje.play()
	else:
		_sonido_colocar.play()
	_guardar()
	_actualizar_interfaz()


func _actualizar_interfaz() -> void:
	_nombre.text = _pieza_actual.nombre
	_contador.text = "Piezas: %d" % _tablero.cantidad()
	_muestra.mostrar(_pieza_actual, _giro)
	_confirmar.disabled = not _hay_pendiente
	if _hay_pendiente:
		var resultado := _tablero.evaluar(_pendiente, _pieza_actual, _giro)
		var perfecto: bool = _tablero.encaja_perfecto(_pendiente, _pieza_actual, _giro)
		_encaje.text = "Encaja %d de %d" % [resultado["coinciden"], resultado["vecinos"]]
		_vista.mostrar_pendiente(_pendiente, _pieza_actual, _giro, perfecto)
	else:
		_encaje.text = ""
		_vista.ocultar_pendiente()
	_vista.queue_redraw()
