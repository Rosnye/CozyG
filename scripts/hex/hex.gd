class_name Hex
extends RefCounted
## Matemática de cuadrículas hexagonales (coordenadas axiales q, r; "pointy-top").
## No depende de nodos ni de cómo se dibuja.

## Vecinos en el sentido de las agujas del reloj, empezando por el este.
const DIRECCIONES: Array[Vector2i] = [
	Vector2i(1, 0),   # este
	Vector2i(0, 1),   # sureste
	Vector2i(-1, 1),  # suroeste
	Vector2i(-1, 0),  # oeste
	Vector2i(0, -1),  # noroeste
	Vector2i(1, -1),  # noreste
]

const RAIZ3: float = 1.7320508075688772


static func vecino(coord: Vector2i, direccion: int) -> Vector2i:
	return coord + DIRECCIONES[posmod(direccion, 6)]


static func vecinos(coord: Vector2i) -> Array[Vector2i]:
	var resultado: Array[Vector2i] = []
	for d: Vector2i in DIRECCIONES:
		resultado.append(coord + d)
	return resultado


static func distancia(a: Vector2i, b: Vector2i) -> int:
	var dq: int = a.x - b.x
	var dr: int = a.y - b.y
	return (absi(dq) + absi(dq + dr) + absi(dr)) / 2


## Centro del hexágono en píxeles (o unidades de mundo) para un tamaño dado.
static func axial_a_pixel(coord: Vector2i, tamano: float) -> Vector2:
	return Vector2(
		tamano * (RAIZ3 * coord.x + RAIZ3 / 2.0 * coord.y),
		tamano * 1.5 * coord.y
	)


## Hexágono que contiene un punto del mundo.
static func pixel_a_axial(punto: Vector2, tamano: float) -> Vector2i:
	var q: float = (RAIZ3 / 3.0 * punto.x - punto.y / 3.0) / tamano
	var r: float = (2.0 / 3.0 * punto.y) / tamano
	return _redondear(q, r)


## Esquinas del hexágono respecto a su centro (orden horario en pantalla).
static func esquinas(tamano: float) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for i in 6:
		var angulo: float = deg_to_rad(60.0 * i - 30.0)
		puntos.append(Vector2(cos(angulo), sin(angulo)) * tamano)
	return puntos


static func _redondear(q: float, r: float) -> Vector2i:
	var x: float = q
	var z: float = r
	var y: float = -x - z
	var rx: float = roundf(x)
	var ry: float = roundf(y)
	var rz: float = roundf(z)
	var dx: float = absf(rx - x)
	var dy: float = absf(ry - y)
	var dz: float = absf(rz - z)
	if dx > dy and dx > dz:
		rx = -ry - rz
	elif dy > dz:
		ry = -rx - rz
	else:
		rz = -rx - ry
	return Vector2i(int(rx), int(rz))
