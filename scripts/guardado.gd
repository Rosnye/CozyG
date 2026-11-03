class_name Guardado
extends RefCounted
## Guardado y carga de la partida (formato JSON con versión). No depende de nodos.

const VERSION: int = 1


static func a_diccionario(tablero: Tablero, pieza_actual: StringName) -> Dictionary:
	var celdas: Array = []
	for coord in tablero.coordenadas():
		celdas.append({
			"q": coord.x,
			"r": coord.y,
			"pieza": String(tablero.pieza_en(coord).id),
			"giro": tablero.giro_en(coord),
		})
	return {"version": VERSION, "pieza_actual": String(pieza_actual), "celdas": celdas}


## Reconstruye una partida. `piezas` mapea id (StringName) -> PiezaDatos.
## Devuelve { "tablero": Tablero, "pieza_actual": StringName, "omitidas": int },
## o un diccionario vacío si los datos no son válidos o no hay ninguna pieza reconocible.
## Las piezas de ids desconocidos se omiten (p. ej. si una actualización las quitó).
static func desde_diccionario(datos: Dictionary, piezas: Dictionary) -> Dictionary:
	if int(datos.get("version", 0)) != VERSION or not datos.get("celdas") is Array:
		return {}
	var tablero := Tablero.new()
	var omitidas: int = 0
	for celda in datos["celdas"]:
		if not celda is Dictionary or not (celda.has("q") and celda.has("r") and celda.has("pieza")):
			omitidas += 1
			continue
		var id := StringName(str(celda["pieza"]))
		if not piezas.has(id):
			omitidas += 1
			continue
		tablero.restaurar(Vector2i(int(celda["q"]), int(celda["r"])), piezas[id], int(celda.get("giro", 0)))
	if tablero.esta_vacio():
		return {}
	return {
		"tablero": tablero,
		"pieza_actual": StringName(str(datos.get("pieza_actual", ""))),
		"omitidas": omitidas,
	}


static func guardar(ruta: String, datos: Dictionary) -> bool:
	# Se escribe en un archivo temporal y luego se renombra, para no dejar un guardado a medias.
	var temporal: String = ruta + ".tmp"
	var archivo := FileAccess.open(temporal, FileAccess.WRITE)
	if archivo == null:
		return false
	archivo.store_string(JSON.stringify(datos))
	archivo.close()
	if DirAccess.rename_absolute(temporal, ruta) == OK:
		return true
	var directo := FileAccess.open(ruta, FileAccess.WRITE)
	if directo == null:
		return false
	directo.store_string(JSON.stringify(datos))
	directo.close()
	return true


## Lee el guardado; devuelve un diccionario vacío si no existe o está corrupto.
static func leer(ruta: String) -> Dictionary:
	if not FileAccess.file_exists(ruta):
		return {}
	var texto: String = FileAccess.get_file_as_string(ruta)
	var json := JSON.new()
	if json.parse(texto) == OK and json.data is Dictionary:
		return json.data
	return {}
