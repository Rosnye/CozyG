class_name Economia
extends RefCounted
## Recursos y construcciones. Lógica pura: no dibuja ni usa nodos.

## Parte del costo que se devuelve al quitar una construcción.
const DEVOLUCION: float = 0.5

## id de recurso (StringName) -> cantidad (float, para acumular fracciones)
var recursos: Dictionary = {}
## Vector2i -> ConstruccionDatos
var construcciones: Dictionary = {}


## Empieza con las cantidades iniciales de cada recurso.
func iniciar(datos: Array[RecursoDatos]) -> void:
	recursos.clear()
	construcciones.clear()
	for recurso in datos:
		recursos[recurso.id] = float(recurso.inicial)


func cantidad(id: StringName) -> int:
	# El pequeño margen evita que 2.9999999 se muestre como 2.
	return floori(float(recursos.get(id, 0.0)) + 0.000001)


## Rendimiento (0 a 1 o más) de una construcción sobre una pieza, según sus 6 bordes.
static func eficiencia(construccion: ConstruccionDatos, pieza: PiezaDatos) -> float:
	var total: float = 0.0
	for direccion in 6:
		total += float(construccion.afinidad.get(pieza.borde(direccion), 0.0))
	return total / 6.0


static func por_minuto(construccion: ConstruccionDatos, pieza: PiezaDatos) -> float:
	return construccion.por_minuto * eficiencia(construccion, pieza)


func puede_pagar(costo: Dictionary) -> bool:
	for id: StringName in costo:
		if cantidad(id) < int(costo[id]):
			return false
	return true


func puede_construir(coord: Vector2i, construccion: ConstruccionDatos, tablero: Tablero) -> bool:
	if not tablero.esta_ocupado(coord) or construcciones.has(coord):
		return false
	if eficiencia(construccion, tablero.pieza_en(coord)) <= 0.0:
		return false
	return puede_pagar(construccion.costo)


func construir(coord: Vector2i, construccion: ConstruccionDatos, tablero: Tablero) -> bool:
	if not puede_construir(coord, construccion, tablero):
		return false
	for id: StringName in construccion.costo:
		recursos[id] = float(recursos.get(id, 0.0)) - float(construccion.costo[id])
	construcciones[coord] = construccion
	return true


## Quita la construcción de una pieza y devuelve parte del costo.
func quitar(coord: Vector2i) -> bool:
	if not construcciones.has(coord):
		return false
	var construccion: ConstruccionDatos = construcciones[coord]
	for id: StringName in construccion.costo:
		recursos[id] = float(recursos.get(id, 0.0)) + floorf(float(construccion.costo[id]) * DEVOLUCION)
	construcciones.erase(coord)
	return true


## Produce lo que toca en `delta` segundos.
func avanzar(delta: float, tablero: Tablero) -> void:
	for coord: Vector2i in construcciones:
		var construccion: ConstruccionDatos = construcciones[coord]
		var pieza: PiezaDatos = tablero.pieza_en(coord)
		if pieza == null:
			continue
		var ganado: float = por_minuto(construccion, pieza) / 60.0 * delta
		recursos[construccion.produce] = float(recursos.get(construccion.produce, 0.0)) + ganado


func a_diccionario() -> Dictionary:
	var guardados: Dictionary = {}
	for id: StringName in recursos:
		guardados[String(id)] = recursos[id]
	var lista: Array = []
	for coord: Vector2i in construcciones:
		lista.append({"q": coord.x, "r": coord.y, "construccion": String(construcciones[coord].id)})
	return {"recursos": guardados, "construcciones": lista}


## Restaura lo guardado encima de los valores iniciales. `catalogo` mapea id -> ConstruccionDatos.
## Ignora construcciones desconocidas o sobre piezas que ya no existen.
func desde_diccionario(datos: Dictionary, catalogo: Dictionary, tablero: Tablero) -> void:
	if datos.get("recursos") is Dictionary:
		for id in datos["recursos"]:
			recursos[StringName(str(id))] = float(datos["recursos"][id])
	construcciones.clear()
	if not datos.get("construcciones") is Array:
		return
	for dato in datos["construcciones"]:
		if not dato is Dictionary or not (dato.has("q") and dato.has("r") and dato.has("construccion")):
			continue
		var id := StringName(str(dato["construccion"]))
		var coord := Vector2i(int(dato["q"]), int(dato["r"]))
		if catalogo.has(id) and tablero.esta_ocupado(coord):
			construcciones[coord] = catalogo[id]
