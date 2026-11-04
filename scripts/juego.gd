extends Node
## Escena de juego: une el tablero (lógica), la vista, la cámara y la interfaz.
## Flujo: tocar un hueco -> pieza fantasma -> girar -> confirmar -> siguiente pieza.
## Tocar una pieza ya colocada abre el panel de construcción.
## Se puede colocar aunque no encaje; encajar bien se recompensa. Guarda tras cada cambio.

const CARPETA_PIEZAS: String = "res://data/piezas"
const CARPETA_CRIATURAS: String = "res://data/criaturas"
const CARPETA_RECURSOS: String = "res://data/recursos"
const CARPETA_CONSTRUCCIONES: String = "res://data/construcciones"
const ESCENA_MENU: String = "res://scenes/menu.tscn"
const PIEZA_INICIAL: StringName = &"prado"
## Segundos de un día completo (lento a propósito).
const DURACION_DIA: float = 300.0
const FASE_INICIAL: float = 0.1
## Cada cuántos segundos (mín, máx) se pasea una criatura.
const PASEO: Vector2 = Vector2(2.5, 6.0)
## Cada cuántos segundos se actualizan los botones del panel de construcción.
const REFRESCO_PANEL: float = 0.4

## Dónde se guarda la partida (se cambia antes de añadir la escena en pruebas, para no pisar la real).
var ruta_guardado: String = "user://guardado.json"

var _tablero := Tablero.new()
var _mazo: Mazo
var _pieza_actual: PiezaDatos
var _giro: int = 0
var _hay_pendiente: bool = false
var _pendiente: Vector2i = Vector2i.ZERO
var _hay_seleccion: bool = false
var _seleccion: Vector2i = Vector2i.ZERO
var _criaturas: Array[CriaturaDatos] = []
var _recursos: Array[RecursoDatos] = []
var _construcciones: Array[ConstruccionDatos] = []
var _ecosistema := Ecosistema.new()
var _economia := Economia.new()
var _ciclo := Ciclo.new(DURACION_DIA, FASE_INICIAL)
var _clima := Clima.new()
var _conteo: Dictionary = {}
var _espera_paseo: float = 4.0
var _espera_panel: float = 0.0
var _partida_nueva: bool = false
var _aviso_tween: Tween
var _azar := RandomNumberGenerator.new()

@onready var _vista: TableroVista = $Tablero
@onready var _criaturas_vista: CriaturasVista = $Criaturas
@onready var _atmosfera: Atmosfera = $Atmosfera
@onready var _aviso: Label = $Interfaz/Aviso
@onready var _hud_recursos: RecursosHud = $Interfaz/Recursos
@onready var _panel: PanelConstruccion = $Interfaz/PanelConstruccion
@onready var _boton_pausa: Button = $Interfaz/BotonPausa
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
@onready var _pausa: CanvasLayer = $Pausa
@onready var _menu_pausa: Control = %MenuPausa
@onready var _ajustes: Control = %AjustesPausa


func _ready() -> void:
	Preferencias.iniciar()
	_sonido_encaje.bus = Preferencias.BUS_EFECTOS
	_sonido_colocar.bus = Preferencias.BUS_EFECTOS
	var piezas: Array[PiezaDatos] = []
	piezas.assign(_cargar_carpeta(CARPETA_PIEZAS))
	_criaturas.assign(_cargar_carpeta(CARPETA_CRIATURAS))
	_recursos.assign(_cargar_carpeta(CARPETA_RECURSOS))
	_construcciones.assign(_cargar_carpeta(CARPETA_CONSTRUCCIONES))
	_mazo = Mazo.new(piezas)
	_muestra.terrenos = _vista.terrenos
	_azar.randomize()
	_economia.iniciar(_recursos)
	_iniciar_partida(piezas)
	_vista.tablero = _tablero
	_vista.construcciones = _economia.construcciones
	_criaturas_vista.ecosistema = _ecosistema
	_criaturas_vista.tamano_hex = _vista.tamano_hex
	_conteo = _tablero.conteo_bordes()
	_ecosistema.actualizar(_tablero, _criaturas)
	var nombres_recursos: Dictionary = {}
	for recurso in _recursos:
		nombres_recursos[recurso.id] = recurso.nombre
	_panel.configurar(nombres_recursos)
	_hud_recursos.configurar(_recursos)
	_hud_recursos.actualizar(_economia)
	_aviso.modulate.a = 0.0
	_camara.toque.connect(_al_tocar_mundo)
	_girar.pressed.connect(_al_girar)
	_confirmar.pressed.connect(_al_confirmar)
	_panel.construir_pedido.connect(_al_pedir_construir)
	_panel.quitar_pedido.connect(_al_pedir_quitar)
	_panel.cerrado.connect(_deseleccionar)
	_boton_pausa.pressed.connect(_pausar)
	%PausaContinuar.pressed.connect(_reanudar)
	%PausaAjustes.pressed.connect(_abrir_ajustes_pausa)
	%PausaMenu.pressed.connect(_volver_al_menu)
	_ajustes.cerrado.connect(_cerrar_ajustes_pausa)
	_pausa.visible = false
	_actualizar_interfaz()
	if _partida_nueva:
		_avisar("Toca una pieza colocada para construir sobre ella")


func _process(delta: float) -> void:
	_ciclo.avanzar(delta)
	_clima.avanzar(delta)
	_economia.avanzar(delta, _tablero)
	_hud_recursos.actualizar(_economia)
	_criaturas_vista.luz = _ciclo.luz()
	_atmosfera.actualizar(delta, _ciclo, _clima, _conteo, _tablero.cantidad())
	_espera_paseo -= delta
	if _espera_paseo <= 0.0:
		_espera_paseo = _azar.randf_range(PASEO.x, PASEO.y)
		_ecosistema.mover_uno(_tablero)
	_espera_panel -= delta
	if _espera_panel <= 0.0:
		_espera_panel = REFRESCO_PANEL
		if _panel.visible:
			_panel.refrescar(_economia, _tablero)


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
		elif evento.keycode == KEY_ESCAPE:
			_pausar()


## Carga todos los `.tres` de una carpeta de datos, ordenados por id.
func _cargar_carpeta(carpeta: String) -> Array[Resource]:
	var resultado: Array[Resource] = []
	for archivo in DirAccess.get_files_at(carpeta):
		# En una exportación los recursos aparecen como "nombre.tres.remap".
		var nombre: String = archivo.trim_suffix(".remap")
		if nombre.ends_with(".tres"):
			var recurso: Resource = load(carpeta + "/" + nombre)
			if recurso != null:
				resultado.append(recurso)
	resultado.sort_custom(func(a: Resource, b: Resource) -> bool: return String(a.id) < String(b.id))
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
			var criaturas_por_id: Dictionary = {}
			for criatura in _criaturas:
				criaturas_por_id[criatura.id] = criatura
			_ecosistema.desde_array(datos["criaturas"], criaturas_por_id)
		if datos.get("economia") is Dictionary:
			var construcciones_por_id: Dictionary = {}
			for construccion in _construcciones:
				construcciones_por_id[construccion.id] = construccion
			_economia.desde_diccionario(datos["economia"], construcciones_por_id, _tablero)
		return
	_partida_nueva = true
	_tablero.colocar(Vector2i.ZERO, por_id.get(PIEZA_INICIAL, _mazo.robar()))
	_robar()


func _guardar() -> void:
	if _pieza_actual != null:
		var extra: Dictionary = {
			"fase": _ciclo.fase(),
			"criaturas": _ecosistema.a_array(),
			"economia": _economia.a_diccionario(),
		}
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
	for control: Control in [_barra, _panel, _hud_recursos, _boton_pausa]:
		if control.visible and control.get_global_rect().has_point(posicion_pantalla):
			return
	var coord: Vector2i = Hex.pixel_a_axial(posicion_mundo, _vista.tamano_hex)
	if _tablero.esta_ocupado(coord):
		_seleccionar(coord)
		return
	_deseleccionar()
	if not _tablero.puede_colocar(coord):
		return
	_hay_pendiente = true
	_pendiente = coord
	_actualizar_interfaz()


func _seleccionar(coord: Vector2i) -> void:
	_hay_seleccion = true
	_seleccion = coord
	_vista.seleccionar(coord)
	_mostrar_panel()


func _deseleccionar() -> void:
	_hay_seleccion = false
	_vista.deseleccionar()
	_panel.ocultar()


func _mostrar_panel() -> void:
	_panel.mostrar(
		_seleccion, _tablero.pieza_en(_seleccion), _economia.construcciones.get(_seleccion),
		_construcciones, _economia, _tablero
	)


func _al_pedir_construir(construccion: ConstruccionDatos) -> void:
	if not _hay_seleccion or not _economia.construir(_seleccion, construccion, _tablero):
		return
	_sonido_colocar.play()
	_vista.animar_colocacion(_seleccion, true)
	_avisar("Construido: " + construccion.nombre)
	_guardar()
	_hud_recursos.actualizar(_economia)
	_mostrar_panel()
	_vista.queue_redraw()


func _al_pedir_quitar() -> void:
	if not _hay_seleccion or not _economia.quitar(_seleccion):
		return
	_avisar("Construcción quitada")
	_guardar()
	_hud_recursos.actualizar(_economia)
	_mostrar_panel()
	_vista.queue_redraw()


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


func _pausar() -> void:
	if get_tree().paused:
		return
	get_tree().paused = true
	_menu_pausa.visible = true
	_ajustes.visible = false
	_pausa.visible = true


func _reanudar() -> void:
	_pausa.visible = false
	get_tree().paused = false


func _abrir_ajustes_pausa() -> void:
	_menu_pausa.visible = false
	_ajustes.visible = true


func _cerrar_ajustes_pausa() -> void:
	_ajustes.visible = false
	_menu_pausa.visible = true


func _volver_al_menu() -> void:
	_guardar()
	get_tree().paused = false
	get_tree().change_scene_to_file(ESCENA_MENU)


func _actualizar_interfaz() -> void:
	_nombre.text = _pieza_actual.nombre
	_contador.text = "Piezas: %d  ·  Criaturas: %d" % [_tablero.cantidad(), _ecosistema.cantidad()]
	_muestra.mostrar(_pieza_actual, _giro)
	_confirmar.disabled = not _hay_pendiente
	if _hay_pendiente:
		var resultado := _tablero.evaluar(_pendiente, _pieza_actual, _giro)
		var perfecto: bool = _tablero.encaja_perfecto(_pendiente, _pieza_actual, _giro)
		_encaje.text = "Encaja %d de %d" % [resultado["coinciden"], resultado["vecinos"]]
		var iguales: int = _tablero.vecinas_iguales(_pendiente, _pieza_actual)
		if iguales > 0:
			_encaje.text += " · +%d%% producción" % roundi(iguales * Economia.BONO_VECINA * 100.0)
		_vista.mostrar_pendiente(_pendiente, _pieza_actual, _giro, perfecto)
	else:
		_encaje.text = ""
		_vista.ocultar_pendiente()
	_vista.queue_redraw()
