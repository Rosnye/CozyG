class_name CamaraControl
extends Camera2D
## Cámara con arrastre y zoom, igual con mouse (toque emulado) y con dedos.
## Un toque corto sin moverse se avisa con la señal `toque`.
##
## El movimiento usa un ancla: al empezar un gesto se recuerda qué punto del mundo hay bajo
## los dedos, y en cada evento se coloca la cámara para que ese punto siga bajo ellos. Así no
## se acumulan errores aunque se pierdan o repitan eventos táctiles.

signal toque(posicion_pantalla: Vector2, posicion_mundo: Vector2)

@export var zoom_min: float = 0.3
@export var zoom_max: float = 3.0
## Factor por cada paso de la rueda del mouse.
@export var paso_rueda: float = 1.1
## Píxeles de movimiento a partir de los cuales un toque deja de ser un "toque".
@export var umbral_toque: float = 12.0
## Distancia mínima entre dos dedos para usarla como base del zoom (evita saltos).
@export var distancia_minima: float = 24.0

var _dedos: Dictionary = {}  # índice de dedo -> posición en pantalla
var _movimiento: float = 0.0
var _hubo_multitoque: bool = false
var _ancla: Vector2 = Vector2.ZERO  # punto del mundo que debe seguir bajo los dedos
var _zoom_inicial: float = 1.0
var _distancia_inicial: float = 0.0


func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventScreenTouch:
		_al_tocar_pantalla(evento)
	elif evento is InputEventScreenDrag:
		_al_arrastrar(evento)
	elif evento is InputEventMouseButton and evento.pressed:
		if evento.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_en(evento.position, paso_rueda)
		elif evento.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_en(evento.position, 1.0 / paso_rueda)


func _notification(motivo: int) -> void:
	# Si se pierde el foco a mitad de un gesto no llegará el "soltar": se olvidan los dedos.
	if motivo == NOTIFICATION_APPLICATION_FOCUS_OUT or motivo == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_dedos.clear()


func _al_tocar_pantalla(evento: InputEventScreenTouch) -> void:
	if evento.pressed:
		if _dedos.is_empty():
			_movimiento = 0.0
			_hubo_multitoque = false
		_dedos[evento.index] = evento.position
		if _dedos.size() >= 2:
			_hubo_multitoque = true
	else:
		var era_un_solo_dedo: bool = _dedos.size() == 1 and _dedos.has(evento.index)
		_dedos.erase(evento.index)
		if era_un_solo_dedo and not _hubo_multitoque and not evento.canceled and _movimiento < umbral_toque:
			toque.emit(evento.position, _a_mundo(evento.position))
	_reanclar()


func _al_arrastrar(evento: InputEventScreenDrag) -> void:
	if not _dedos.has(evento.index):
		return
	_dedos[evento.index] = evento.position
	if _dedos.size() == 1:
		_movimiento += evento.relative.length()
		_seguir(evento.position)
	elif _dedos.size() == 2 and _distancia_inicial >= distancia_minima:
		var posiciones: Array = _dedos.values()
		var distancia: float = (posiciones[0] as Vector2).distance_to(posiciones[1])
		var nuevo: float = clampf(_zoom_inicial * distancia / _distancia_inicial, zoom_min, zoom_max)
		zoom = Vector2(nuevo, nuevo)
		_seguir(((posiciones[0] as Vector2) + (posiciones[1] as Vector2)) / 2.0)
	# Con tres o más dedos (p. ej. la palma apoyada) no se mueve nada.


## Fija el ancla con los dedos que haya ahora; se llama al cambiar el número de dedos.
func _reanclar() -> void:
	if _dedos.size() == 1:
		_ancla = _a_mundo(_dedos.values()[0])
		_distancia_inicial = 0.0
	elif _dedos.size() == 2:
		var posiciones: Array = _dedos.values()
		_ancla = _a_mundo(((posiciones[0] as Vector2) + (posiciones[1] as Vector2)) / 2.0)
		_zoom_inicial = zoom.x
		_distancia_inicial = (posiciones[0] as Vector2).distance_to(posiciones[1])


## Coloca la cámara para que el ancla quede bajo `posicion_pantalla`.
func _seguir(posicion_pantalla: Vector2) -> void:
	position = _ancla - (posicion_pantalla - get_viewport_rect().size / 2.0) / zoom.x


## Zoom (rueda del mouse) manteniendo fijo el punto de mundo bajo `posicion_pantalla`.
func _zoom_en(posicion_pantalla: Vector2, factor: float) -> void:
	var antes: Vector2 = _a_mundo(posicion_pantalla)
	var nuevo: float = clampf(zoom.x * factor, zoom_min, zoom_max)
	zoom = Vector2(nuevo, nuevo)
	position += antes - _a_mundo(posicion_pantalla)


func _a_mundo(posicion_pantalla: Vector2) -> Vector2:
	return position + (posicion_pantalla - get_viewport_rect().size / 2.0) / zoom.x
