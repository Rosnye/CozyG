class_name LluviaVista
extends Control
## Gotas de lluvia en pantalla. Con intensidad 0 no dibuja ni gasta nada.

const GOTAS: int = 140

@export var color_gota: Color = Color(0.75, 0.85, 1.0, 0.4)

## 0 sin lluvia, 1 lluvia completa.
var intensidad: float = 0.0:
	set(valor):
		intensidad = clampf(valor, 0.0, 1.0)
		set_process(intensidad > 0.01)
		queue_redraw()

## Cada gota: x e y normalizados (0..1), velocidad y largo.
var _gotas: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var azar := RandomNumberGenerator.new()
	azar.seed = 99
	for i in GOTAS:
		_gotas.append({
			"x": azar.randf(), "y": azar.randf(),
			"velocidad": azar.randf_range(0.9, 1.5), "largo": azar.randf_range(14.0, 28.0),
		})
	set_process(false)


func _process(delta: float) -> void:
	for gota in _gotas:
		gota["y"] += delta * gota["velocidad"] * 0.9
		if gota["y"] > 1.05:
			gota["y"] -= 1.1
	queue_redraw()


func _draw() -> void:
	if intensidad <= 0.01:
		return
	var visibles: int = int(GOTAS * intensidad)
	var color: Color = color_gota
	color.a *= intensidad
	for i in visibles:
		var gota: Dictionary = _gotas[i]
		var inicio := Vector2(gota["x"] * size.x, gota["y"] * size.y)
		draw_line(inicio, inicio + Vector2(-3.0, gota["largo"]), color, 2.0, true)
