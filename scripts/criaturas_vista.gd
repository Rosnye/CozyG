class_name CriaturasVista
extends Node2D
## Dibuja las criaturas del ecosistema y las desliza suavemente entre piezas.
## Solo lee datos: la lógica de dónde están vive en `Ecosistema`.

const DURACION_APARICION: float = 0.6

var ecosistema: Ecosistema
var tamano_hex: float = 64.0
## 1 de día, 0 de noche (lo usan las criaturas que solo salen de noche).
var luz: float = 1.0

## id de individuo -> { "pos": Vector2, "edad": float }
var _visuales: Dictionary = {}
var _reloj: float = 0.0


func _process(delta: float) -> void:
	if ecosistema == null or ecosistema.individuos.is_empty():
		return
	_reloj += delta
	var presentes: Dictionary = {}
	for individuo in ecosistema.individuos:
		var id: int = individuo["id"]
		presentes[id] = true
		var destino: Vector2 = _destino(individuo)
		if not _visuales.has(id):
			_visuales[id] = {"pos": destino, "edad": 0.0}
		var visual: Dictionary = _visuales[id]
		visual["edad"] += delta
		visual["pos"] = visual["pos"].lerp(destino, 1.0 - exp(-delta * 1.6))
	for id: int in _visuales.keys():
		if not presentes.has(id):
			_visuales.erase(id)
	queue_redraw()


func _destino(individuo: Dictionary) -> Vector2:
	# Cada individuo se coloca en un punto propio de la pieza para no tapar a otros.
	var id: int = individuo["id"]
	var desvio: Vector2 = Vector2(cos(id * 2.4), sin(id * 2.4)) * tamano_hex * 0.28
	return Hex.axial_a_pixel(individuo["coord"], tamano_hex) + desvio


func _draw() -> void:
	if ecosistema == null:
		return
	for individuo in ecosistema.individuos:
		var visual: Variant = _visuales.get(individuo["id"])
		if visual == null:
			continue
		_dibujar_criatura(individuo, visual)


func _dibujar_criatura(individuo: Dictionary, visual: Dictionary) -> void:
	var criatura: CriaturaDatos = individuo["criatura"]
	var opacidad: float = 1.0
	if criatura.solo_de_noche:
		opacidad = 1.0 - smoothstep(0.2, 0.55, luz)
		if opacidad < 0.02:
			return
	var aparicion: float = clampf(visual["edad"] / DURACION_APARICION, 0.0, 1.0)
	var escala: float = _rebote(aparicion)
	var saltito: float = sin(_reloj * 3.0 + individuo["id"]) * 1.5
	var pos: Vector2 = visual["pos"] + Vector2(0, saltito)
	var radio: float = criatura.tamano * escala
	var color: Color = criatura.color
	color.a = opacidad
	if criatura.solo_de_noche:
		# Resplandor suave alrededor.
		for capa in 3:
			var halo: Color = color
			halo.a = opacidad * 0.12
			draw_circle(pos, radio * (2.0 + capa * 1.4), halo)
	if criatura.arte != null:
		var lado: float = radio * 3.2
		draw_texture_rect(criatura.arte, Rect2(pos - Vector2(lado, lado * 0.8), Vector2(lado, lado)), false, Color(1, 1, 1, opacidad))
		return
	draw_circle(pos + Vector2(0, radio * 0.9), radio * 0.8, Color(0, 0, 0, 0.15 * opacidad))
	draw_circle(pos, radio, color)
	draw_circle(pos + Vector2(radio * 0.45, -radio * 0.35), radio * 0.55, color.lightened(0.1))
	draw_circle(pos + Vector2(radio * 0.62, -radio * 0.42), maxf(radio * 0.12, 1.2), Color(0.2, 0.17, 0.14, opacidad))


## Rebote suave al aparecer.
func _rebote(t: float) -> float:
	var c1: float = 1.70158
	var c3: float = c1 + 1.0
	return 1.0 + c3 * pow(t - 1.0, 3.0) + c1 * pow(t - 1.0, 2.0)
