extends Node
## Escena de juego: une el tablero (lógica), la vista, la cámara y la interfaz.
## Flujo: tocar un hueco -> pieza fantasma -> girar -> confirmar -> siguiente pieza.
## Se puede colocar aunque no encaje; encajar bien se recompensa. Guarda tras cada pieza.

const CARPETA_PIEZAS: String = "res://data/piezas"
const CARPETA_CRIATURAS: String = "res://data/criaturas"
const PIEZA_INICIAL: StringName = &"prado"
## Segundos de un día completo (lento a propósito).
const DURACION_DIA: float = 300.0
const FASE_INICIAL: float = 0.1
## Cada cuántos segundos (mín, máx) se pasea una criatura.
const PASEO: Vector2 = Vector2(2.5, 6.0)

## Dónde se guarda la partida (se cambia antes de añadir la escena en pruebas, para no pisar la real).
var ruta_guardado: String = "user://guardado.json"

var _tablero := Tablero.new()
var _mazo: Mazo
var _pieza_actual: PiezaDatos
var _giro: int = 0
var _hay_pendiente: bool = false
var _pendiente: Vector2i = Vector2i.ZERO
var _criaturas: Array[CriaturaDatos] = []
var _ecosistema := Ecosistema.new()
var _ciclo := Ciclo.new(DURACION_DIA, FASE_INICIAL)
var _clima := Clima.new()
var _conteo: Dictionary = {}
var _espera_paseo: float = 4.0
var _aviso_tween: Tween
var _azar := RandomNumberGenerator.new()

@onready var _vista: TableroVista = $Tablero
@onready var _criaturas_vista: CriaturasVista = $Criaturas
@onready var _atmosfera: Atmosfera = $Atmosfera
@onready var _aviso: Label = $Interfaz/Aviso
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
	_azar.randomize()
	_criaturas = _cargar_criaturas()
	_iniciar_partida(piezas)
	_vista.tablero = _tablero
	_criaturas_vista.ecosistema = _ecosistema
	_criaturas_vista.tamano_hex = _vista.tamano_hex
	_conteo = _tablero.conteo_bordes()
	_ecosistema.actualizar(_tablero, _criaturas)
	_aviso.modulate.a = 0.0
	_camara.toque.connect(_al_tocar_mundo)
	_girar.pressed.connect(_al_girar)
	_confirmar.pressed.connect(_al_confirmar)
	_actualizar_interfaz()


func _process(delta: float) -> void:
	_ciclo.avanzar(delta)
	_clima.avanzar(delta)
	_criaturas_vista.luz = _ciclo.luz()
	_atmosfera.actualizar(delta, _ciclo, _clima, _conteo, _tablero.cantidad())
	_espera_paseo -= delta
	if _espera_paseo <= 0.0:
		_espera_paseo = _azar.randf_range(PASEO.x, PASEO.y)
		_ecosistema.mover_uno(_tablero)


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


func _cargar_criaturas() -> Array[CriaturaDatos]:
	var resultado: Array[CriaturaDatos] = []
	for archivo in DirAccess.get_files_at(CARPETA_CRIATURAS):
		var nombre: String = archivo.trim_suffix(".remap")
		if nombre.ends_with(".tres"):
			var criatura := load(CARPETA_CRIATURAS + "/" + nombre) as CriaturaDatos
			if criatura != null:
				resultado.append(criatura)
	resultado.sort_custom(func(a: CriaturaDatos, b: CriaturaDatos) -> bool: return a.id < b.id)
	return resultado


## Carga la partida guardada o empieza una nueva con la pieza inicial en el centro.
func _iniciar_partida(piezas: Array[PiezaDatos]) -> void:
	var por_id: Dictionary = {}
	for pieza in piezas:
		por_id[pieza.id] = pieza
	var cargada := Guardado.desde_diccionario(Guardado.leer(ruta_guardado), por_id)
	if not cargada.is_empty():
		_tablero = cargada["tablero"]
		_pieza_actual = por_id.get(cargada["pieza_actual"])
		if _pieza_actual == null:
			_robar()
		var datos: Dictionary = cargada["datos"]
		if datos.has("fase"):
			_ciclo.fijar_fase(float(datos["fase"]))
		if datos.get("criaturas") is Array:
			var por_id_criaturas: Dictionary = {}
			for criatura in _criaturas:
				por_id_criaturas[criatura.id] = criatura
			_ecosistema.desde_array(datos["criaturas"], por_id_criaturas)
		return
	_tablero.colocar(Vector2i.ZERO, por_id.get(PIEZA_INICIAL, _mazo.robar()))
	_robar()


func _guardar() -> void:
	if _pieza_actual != null:
		var extra: Dictionary = {"fase": _ciclo.fase(), "criaturas": _ecosistema.a_array()}
		Guardado.guardar(ruta_guardado, Guardado.a_diccionario(_tablero, _pieza_actual.id, extra))


## Muestra un aviso breve arriba que se desvanece solo.
func _avisar(texto: String) -> void:
	_aviso.text = texto
	if _aviso_tween != null:
		_aviso_tween.kill()
	_aviso.modulate.a = 1.0
	_aviso_tween = create_tween()
	_aviso_tween.tween_interval(2.5)
	_aviso_tween.tween_property(_aviso, "modulate:a", 0.0, 1.2)


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
	_conteo = _tablero.conteo_bordes()
	var llegadas := _ecosistema.actualizar(_tablero, _criaturas)
	if not llegadas.is_empty():
		var nombres: PackedStringArray = []
		for llegada in llegadas:
			if not nombres.has(llegada["criatura"].nombre):
				nombres.append(llegada["criatura"].nombre)
		_avisar("Ha llegado: " + " y ".join(nombres))
	_guardar()
	_actualizar_interfaz()


func _actualizar_interfaz() -> void:
	_nombre.text = _pieza_actual.nombre
	_contador.text = "Piezas: %d  ·  Criaturas: %d" % [_tablero.cantidad(), _ecosistema.cantidad()]
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
