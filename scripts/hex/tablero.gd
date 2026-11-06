class_name Tablero
extends RefCounted
## Mundo de piezas: qué pieza hay en cada hexágono y con qué giro.
## Infinito: solo guarda las celdas ocupadas. No depende de nodos visuales.

## Vector2i -> { "pieza": PiezaDatos, "giro": int }
var _celdas: Dictionary = {}

## Sube cada vez que cambia el contenido del tablero; sirve para invalidar cachés.
var version: int = 0

var _frontera_cache: Array[Vector2i] = []
var _frontera_version: int = -1


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
	version += 1
	return true


## Cómo encajaría `pieza` girada `giro` en `coord`: cuántos vecinos ocupados tiene
## y en cuántos coincide el terreno del borde compartido.
## Devuelve { "vecinos": int, "coinciden": int }. No coloca nada.
func evaluar(coord: Vector2i, pieza: PiezaDatos, giro: int) -> Dictionary:
	var vecinos: int = 0
	var coinciden: int = 0
	for direccion in 6:
		var otro := Hex.vecino(coord, direccion)
		if not _celdas.has(otro):
			continue
		vecinos += 1
		var mi_borde: StringName = pieza.borde(direccion, giro)
		var su_borde: StringName = _celdas[otro]["pieza"].borde(direccion + 3, _celdas[otro]["giro"])
		if mi_borde == su_borde:
			coinciden += 1
	return {"vecinos": vecinos, "coinciden": coinciden}


## Cuántas piezas vecinas son del mismo tipo (mismo id) que `pieza` si esta se pusiera en `coord`.
func vecinas_iguales(coord: Vector2i, pieza: PiezaDatos) -> int:
	var iguales: int = 0
	for vecino in Hex.vecinos(coord):
		if _celdas.has(vecino) and _celdas[vecino]["pieza"].id == pieza.id:
			iguales += 1
	return iguales


## Encaje perfecto: toca al menos una pieza y todos los bordes compartidos coinciden.
func encaja_perfecto(coord: Vector2i, pieza: PiezaDatos, giro: int) -> bool:
	var resultado := evaluar(coord, pieza, giro)
	return resultado["vecinos"] > 0 and resultado["coinciden"] == resultado["vecinos"]


## Coloca sin comprobar reglas (para cargar una partida guardada).
func restaurar(coord: Vector2i, pieza: PiezaDatos, giro: int) -> void:
	_celdas[coord] = {"pieza": pieza, "giro": posmod(giro, 6)}
	version += 1


## Cuántos bordes de un terreno necesita una pieza para ser hábitat de ese terreno.
const BORDES_HABITAT: int = 2


## Bordes de cada terreno sumados en todo el mundo: { terreno: cantidad }.
func conteo_bordes() -> Dictionary:
	var conteo: Dictionary = {}
	for coord: Vector2i in _celdas:
		var pieza: PiezaDatos = _celdas[coord]["pieza"]
		for direccion in 6:
			var terreno: StringName = pieza.borde(direccion)
			conteo[terreno] = int(conteo.get(terreno, 0)) + 1
	return conteo


func es_habitat(coord: Vector2i, terreno: StringName) -> bool:
	if not _celdas.has(coord):
		return false
	var pieza: PiezaDatos = _celdas[coord]["pieza"]
	var bordes: int = 0
	for direccion in 6:
		if pieza.borde(direccion) == terreno:
			bordes += 1
	return bordes >= BORDES_HABITAT


func celdas_habitat(terreno: StringName) -> Array[Vector2i]:
	var resultado: Array[Vector2i] = []
	for coord: Vector2i in _celdas:
		if es_habitat(coord, terreno):
			resultado.append(coord)
	return resultado


## Huecos libres donde se puede colocar (sin repetidos). Se guarda en caché hasta que cambie el tablero.
func frontera() -> Array[Vector2i]:
	if _frontera_version == version:
		return _frontera_cache
	var vistos: Dictionary = {}
	var resultado: Array[Vector2i] = []
	for coord: Vector2i in _celdas:
		for vecino in Hex.vecinos(coord):
			if not _celdas.has(vecino) and not vistos.has(vecino):
				vistos[vecino] = true
				resultado.append(vecino)
	_frontera_cache = resultado
	_frontera_version = version
	return resultado