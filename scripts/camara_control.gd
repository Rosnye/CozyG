class_name CamaraControl
extends Camera2D
## Cámara con arrastre y zoom, igual con mouse (toque emulado) y con dedos.
## Un toque corto sin moverse se avisa con la señal `toque`.

signal toque(posicion_pantalla: Vector2, posicion_mundo: Vector2)

@export var zoom_min: float = 0.3
@export var zoom_max: float = 3.0
## Factor por cada paso de la rueda del mouse.
@export var paso_rueda: float = 1.1
## Píxeles de movimiento a partir de los cuales un toque deja de ser un "toque".
@export var umbral_toque: float = 12.0

var _dedos: Dictionary = {}  # índice de dedo -> posición en pantalla
var _movimiento: float = 0.0
var _hubo_multitoque: bool = false
var _distancia_previa: float = 0.0


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


func _al_tocar_pantalla(evento: InputEventScreenTouch) -> void:
	if evento.pressed:
		if _dedos.is_empty():
			_movimiento = 0.0
			_hubo_multitoque = false
		_dedos[evento.index] = evento.position
		if _dedos.size() == 2:
			_hubo_multitoque = true
			_distancia_previa = _distancia_entre_dedos()
	else:
		var era_un_solo_dedo: bool = _dedos.size() == 1 and _dedos.has(evento.index)
		_dedos.erase(evento.index)
		if era_un_solo_dedo and not _hubo_multitoque and _movimiento < umbral_toque:
			toque.emit(evento.position, _a_mundo(evento.position))


func _al_arrastrar(evento: InputEventScreenDrag) -> void:
	if not _dedos.has(evento.index):
		return
	_dedos[evento.index] = evento.position
	if _dedos.size() == 1:
		_movimiento += evento.relative.length()
		position -= evento.relative / zoom.x
	elif _dedos.size() == 2:
		var distancia: float = _distancia_entre_dedos()
		if _distancia_previa > 0.0 and distancia > 0.0:
			var centro: Vector2 = (_dedos.values()[0] + _dedos.values()[1]) / 2.0
			_zoom_en(centro, distancia / _distancia_previa)
		_distancia_previa = distancia


func _distancia_entre_dedos() -> float:
	var posiciones: Array = _dedos.values()
	return (posiciones[0] as Vector2).distance_to(posiciones[1])


## Zoom manteniendo fijo el punto de mundo que está bajo `posicion_pantalla`.
func _zoom_en(posicion_pantalla: Vector2, factor: float) -> void:
	var antes: Vector2 = _a_mundo(posicion_pantalla)
	var nuevo: float = clampf(zoom.x * factor, zoom_min, zoom_max)
	zoom = Vector2(nuevo, nuevo)
	position += antes - _a_mundo(posicion_pantalla)


func _a_mundo(posicion_pantalla: Vector2) -> Vector2:
	return position + (posicion_pantalla - get_viewport_rect().size / 2.0) / zoom.x
