class_name Ecosistema
extends RefCounted
## Criaturas que llegan según lo que se construye y se pasean por su hábitat.
## Lógica pura: no dibuja nada ni usa nodos.

## Cada individuo: { "id": int, "criatura": CriaturaDatos, "coord": Vector2i }
var individuos: Array[Dictionary] = []

var _siguiente_id: int = 1
var _azar := RandomNumberGenerator.new()


## `semilla` fija el azar (útil en pruebas); con -1 es aleatorio.
func _init(semilla: int = -1) -> void:
	if semilla >= 0:
		_azar.seed = semilla
	else:
		_azar.randomize()


## Cuántos individuos de `criatura` debe haber dado el conteo de bordes del mundo.
static func poblacion_objetivo(criatura: CriaturaDatos, conteo: Dictionary) -> int:
	var veces: int = -1
	for terreno: StringName in criatura.requisitos:
		var minimo: int = int(criatura.requisitos[terreno])
		if minimo <= 0:
			continue
		var cumplido: int = floori(float(int(conteo.get(terreno, 0))) / float(minimo))
		veces = cumplido if veces < 0 else mini(veces, cumplido)
	if veces < 1:
		return 0
	return mini(veces, criatura.maximo)


func cantidad() -> int:
	return individuos.size()


func cantidad_de(id: StringName) -> int:
	var total: int = 0
	for individuo in individuos:
		if individuo["criatura"].id == id:
			total += 1
	return total


## Hace llegar las criaturas que ya se merecen. Devuelve los individuos recién llegados.
func actualizar(tablero: Tablero, criaturas: Array[CriaturaDatos]) -> Array[Dictionary]:
	var llegadas: Array[Dictionary] = []
	var conteo: Dictionary = tablero.conteo_bordes()
	for criatura in criaturas:
		var objetivo: int = poblacion_objetivo(criatura, conteo)
		var actuales: int = cantidad_de(criatura.id)
		if actuales >= objetivo:
			continue
		var candidatas: Array[Vector2i] = tablero.celdas_habitat(criatura.habitat)
		while actuales < objetivo and not candidatas.is_empty():
			var coord: Vector2i = candidatas[_azar.randi_range(0, candidatas.size() - 1)]
			var individuo := {"id": _siguiente_id, "criatura": criatura, "coord": coord}
			_siguiente_id += 1
			individuos.append(individuo)
			llegadas.append(individuo)
			actuales += 1
	return llegadas


## Mueve a un individuo al azar a una pieza vecina de su hábitat.
## Devuelve el individuo movido, o un diccionario vacío si nadie pudo moverse.
func mover_uno(tablero: Tablero) -> Dictionary:
	if individuos.is_empty():
		return {}
	var individuo: Dictionary = individuos[_azar.randi_range(0, individuos.size() - 1)]
	var criatura: CriaturaDatos = individuo["criatura"]
	var opciones: Array[Vector2i] = []
	for vecino in Hex.vecinos(individuo["coord"]):
		if tablero.es_habitat(vecino, criatura.habitat):
			opciones.append(vecino)
	if opciones.is_empty():
		return {}
	individuo["coord"] = opciones[_azar.randi_range(0, opciones.size() - 1)]
	return individuo


func a_array() -> Array:
	var resultado: Array = []
	for individuo in individuos:
		var coord: Vector2i = individuo["coord"]
		resultado.append({"criatura": String(individuo["criatura"].id), "q": coord.x, "r": coord.y})
	return resultado


## Restaura individuos guardados. `criaturas` mapea id (StringName) -> CriaturaDatos.
## Los de ids desconocidos se omiten.
func desde_array(datos: Array, criaturas: Dictionary) -> void:
	individuos.clear()
	for dato in datos:
		if not dato is Dictionary or not (dato.has("criatura") and dato.has("q") and dato.has("r")):
			continue
		var id := StringName(str(dato["criatura"]))
		if not criaturas.has(id):
			continue
		individuos.append({
			"id": _siguiente_id,
			"criatura": criaturas[id],
			"coord": Vector2i(int(dato["q"]), int(dato["r"])),
		})
		_siguiente_id += 1
