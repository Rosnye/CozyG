class_name Tablero
extends RefCounted
## Mundo de piezas: qué pieza hay en cada hexágono y con qué giro.
## Infinito: solo guarda las celdas ocupadas. No depende de nodos visuales.

## Vector2i -> { "pieza": PiezaDatos, "giro": int }
var _celdas: Dictionary = {}


func cantidad() -> int:
	return _celdas.size()


func esta_vacio() -> bool:
	return _celdas.is_empty()


func esta_ocupado(coord: Vector2i) -> bool:
	return _celdas.has(coord)


func pieza_en(coord: Vector2i) -> PiezaDatos:
	if not _celdas.has(coord):
		return null
	return _celdas[coord]["pieza"]


func giro_en(coord: Vector2i) -> int:
	if not _celdas.has(coord):
		return 0
	return _celdas[coord]["giro"]


func coordenadas() -> Array[Vector2i]:
	var resultado: Array[Vector2i] = []
	for coord: Vector2i in _celdas:
		resultado.append(coord)
	return resultado


## Una pieza se puede poner en un hueco libre pegado a otra; la primera, en cualquier sitio.
func puede_colocar(coord: Vector2i) -> bool:
	if esta_ocupado(coord):
		return false
	if esta_vacio():
		return true
	for vecino in Hex.vecinos(coord):
		if esta_ocupado(vecino):
			return true
	return false


func colocar(coord: Vector2i, pieza: PiezaDatos, giro: int = 0) -> bool:
	if pieza == null or not puede_colocar(coord):
		return false
	_celdas[coord] = {"pieza": pieza, "giro": posmod(giro, 6)}
	return true


## Huecos libres donde se puede colocar (sin repetidos).
func frontera() -> Array[Vector2i]:
	var vistos: Dictionary = {}
	var resultado: Array[Vector2i] = []
	for coord: Vector2i in _celdas:
		for vecino in Hex.vecinos(coord):
			if not _celdas.has(vecino) and not vistos.has(vecino):
				vistos[vecino] = true
				resultado.append(vecino)
	return resultado
