class_name TableroVista
extends Node2D
## Dibuja el tablero y sus animaciones. Solo lee datos: no decide reglas.

const DURACION_ASENTAR: float = 0.35
const DURACION_ONDA: float = 0.6

@export var tamano_hex: float = 64.0
@export var terrenos: TerrenosDatos
@export var color_hueco: Color = Color(0.42, 0.36, 0.28, 0.3)
@export var color_seleccion: Color = Color(1, 1, 1, 0.95)
## Contorno del fantasma cuando todos los bordes vecinos coinciden.
@export var color_encaje: Color = Color(0.55, 0.85, 0.45, 1)
## Contorno del fantasma cuando algún borde no coincide (se puede colocar igual).
@export var color_desajuste: Color = Color(0.95, 0.7, 0.35, 1)

var tablero: Tablero

var _hay_pendiente: bool = false
var _pendiente_coord: Vector2i = Vector2i.ZERO
var _pendiente_pieza: PiezaDatos
var _pendiente_giro: int = 0
var _pendiente_encaja: bool = false

## Vector2i -> { "tiempo": float, "perfecta": bool }
var _animaciones: Dictionary = {}

@onready var _particulas: CPUParticles2D = $Particulas


func _ready() -> void:
	set_process(false)


func mostrar_pendiente(coord: Vector2i, pieza: PiezaDatos, giro: int, encaja: bool) -> void:
	_hay_pendiente = true
	_pendiente_coord = coord
	_pendiente_pieza = pieza
	_pendiente_giro = giro
	_pendiente_encaja = encaja
	queue_redraw()


func ocultar_pendiente() -> void:
	_hay_pendiente = false
	queue_redraw()


## Anima la pieza recién colocada; si encaja perfecto, añade una onda y partículas.
func animar_colocacion(coord: Vector2i, perfecta: bool) -> void:
	_animaciones[coord] = {"tiempo": 0.0, "perfecta": perfecta}
	if perfecta:
		_particulas.position = Hex.axial_a_pixel(coord, tamano_hex)
		_particulas.restart()
	set_process(true)


func _process(delta: float) -> void:
	for coord: Vector2i in _animaciones.keys():
		var animacion: Dictionary = _animaciones[coord]
		animacion["tiempo"] += delta
		var duracion: float = DURACION_ONDA if animacion["perfecta"] else DURACION_ASENTAR
		if animacion["tiempo"] >= duracion:
			_animaciones.erase(coord)
	queue_redraw()
	if _animaciones.is_empty():
		set_process(false)


func _draw() -> void:
	if tablero == null:
		return
	for coord in tablero.frontera():
		var contorno := _contorno(coord, 0.94)
		draw_polyline(contorno, color_hueco, 2.0, true)
	for coord in tablero.coordenadas():
		var escala: float = 1.0
		if _animaciones.has(coord):
			escala = _escala_asentar(_animaciones[coord]["tiempo"])
		DibujoPieza.dibujar(
			self, Hex.axial_a_pixel(coord, tamano_hex), tamano_hex,
			tablero.pieza_en(coord), tablero.giro_en(coord), terrenos, 1.0, escala
		)
	for coord: Vector2i in _animaciones:
		if _animaciones[coord]["perfecta"]:
			_dibujar_onda(coord, _animaciones[coord]["tiempo"])
	if _hay_pendiente and _pendiente_pieza != null:
		DibujoPieza.dibujar(
			self, Hex.axial_a_pixel(_pendiente_coord, tamano_hex), tamano_hex,
			_pendiente_pieza, _pendiente_giro, terrenos, 0.75
		)
		var color: Color = color_encaje if _pendiente_encaja else color_desajuste
		draw_polyline(_contorno(_pendiente_coord, 0.97), color, 5.0, true)


## Rebote suave: arranca pequeña, se pasa un poco y se asienta.
func _escala_asentar(tiempo: float) -> float:
	var t: float = clampf(tiempo / DURACION_ASENTAR, 0.0, 1.0)
	var c1: float = 1.70158
	var c3: float = c1 + 1.0
	var curva: float = 1.0 + c3 * pow(t - 1.0, 3.0) + c1 * pow(t - 1.0, 2.0)
	return 0.55 + 0.45 * curva


func _dibujar_onda(coord: Vector2i, tiempo: float) -> void:
	var t: float = clampf(tiempo / DURACION_ONDA, 0.0, 1.0)
	var color: Color = color_encaje
	color.a = (1.0 - t) * 0.9
	var centro: Vector2 = Hex.axial_a_pixel(coord, tamano_hex)
	draw_arc(centro, tamano_hex * (0.9 + 0.8 * t), 0.0, TAU, 48, color, 4.0, true)


func _contorno(coord: Vector2i, escala: float) -> PackedVector2Array:
	var centro: Vector2 = Hex.axial_a_pixel(coord, tamano_hex)
	var puntos: PackedVector2Array = Hex.esquinas(tamano_hex * escala)
	for i in puntos.size():
		puntos[i] += centro
	puntos.append(puntos[0])
	return puntos
