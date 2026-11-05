class_name Economia
extends RefCounted
## Recursos y construcciones. Lógica pura: no dibuja ni usa nodos.

## Parte del costo que se devuelve al quitar una construcción.
const DEVOLUCION: float = 0.5
## Bonus de producción por cada pieza vecina del mismo tipo (0.05 = +5 %).
const BONO_VECINA: float = 0.05

## id de recurso (StringName) -> cantidad (float, para acumular fracciones)
var recursos: Dictionary = {}
## Vector2i -> ConstruccionDatos
var construcciones: Dictionary = {}

# Producción total por segundo de cada recurso. Se recalcula solo cuando cambia algo
# (en vez de rehacer en cada fotograma los bonus de todas las construcciones).
var _tasas: Dictionary = {}
var _sucia: bool = true
var _ultimo_tablero: Tablero
var _ultima_version: int = -1


## Empieza con las cantidades iniciales de cada recurso.
func iniciar(datos: Array[RecursoDatos]) -> void:
	recursos.clear()
	construcciones.clear()
	_sucia = true
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


## Multiplicador por vecinas iguales: cada una suma `BONO_VECINA` (1.0 = sin bonus).
static func multiplicador(vecinas_iguales: int) -> float:
	return 1.0 + BONO_VECINA * float(vecinas_iguales)


## Producción real por minuto de una construcción en `coord`, con el bonus por vecinas iguales.
func por_minuto_en(coord: Vector2i, construccion: ConstruccionDatos, tablero: Tablero) -> float:
	var pieza: PiezaDatos = tablero.pieza_en(coord)
	if pieza == null:
		return 0.0
	return por_minuto(construccion, pieza) * multiplicador(tablero.vecinas_iguales(coord, pieza))


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
	_sucia = true
	return true


## Quita la construcción de una pieza y devuelve parte del costo.
func quitar(coord: Vector2i) -> bool:
	if not construcciones.has(coord):
		return false
	var construccion: ConstruccionDatos = construcciones[coord]
	for id: StringName in construccion.costo:
		recursos[id] = float(recursos.get(id, 0.0)) + floorf(float(construccion.costo[id]) * DEVOLUCION)
	construcciones.erase(coord)
	_sucia = true
	return true


## Avisa de que `construcciones` se tocó por fuera de `construir` y `quitar`.
func invalidar() -> void:
	_sucia = true


## Produce lo que toca en `delta` segundos.
func avanzar(delta: float, tablero: Tablero) -> void:
	if _sucia or tablero != _ultimo_tablero or tablero.version != _ultima_version:
		_recalcular_tasas(tablero)
	for id: StringName in _tasas:
		recursos[id] = float(recursos.get(id, 0.0)) + float(_tasas[id]) * delta


func _recalcular_tasas(tablero: Tablero) -> void:
	_tasas.clear()
	for coord: Vector2i in construcciones:
		var construccion: ConstruccionDatos = construcciones[coord]
		var por_segundo: float = por_minuto_en(coord, construccion, tablero) / 60.0
		if por_segundo > 0.0:
			_tasas[construccion.produce] = float(_tasas.get(construccion.produce, 0.0)) + por_segundo
	_sucia = false
	_ultimo_tablero = tablero
	_ultima_version = tablero.version


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
	_sucia = true
	if not datos.get("construcciones") is Array:
		return
	for dato in datos["construcciones"]:
		if not dato is Dictionary or not (dato.has("q") and dato.has("r") and dato.has("construccion")):
			continue
		var id := StringName(str(dato["construccion"]))
		var coord := Vector2i(int(dato["q"]), int(dato["r"]))
		if catalogo.has(id) and tablero.esta_ocupado(coord):
			construcciones[coord] = catalogo[id]
