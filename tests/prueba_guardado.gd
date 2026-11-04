extends "res://tests/prueba_base.gd"

const RUTA: String = "user://prueba_guardado.json"


func _pieza(id: StringName) -> PiezaDatos:
	var p := PiezaDatos.new()
	p.id = id
	return p


func _catalogo() -> Dictionary:
	return {&"prado": _pieza(&"prado"), &"rio": _pieza(&"rio")}


func _tablero_de_ejemplo(piezas: Dictionary) -> Tablero:
	var t := Tablero.new()
	t.colocar(Vector2i.ZERO, piezas[&"prado"], 0)
	t.colocar(Vector2i(1, 0), piezas[&"rio"], 3)
	t.colocar(Vector2i(-1, 1), piezas[&"rio"], 5)
	return t


func prueba_ida_y_vuelta_en_memoria() -> void:
	var piezas := _catalogo()
	var original := _tablero_de_ejemplo(piezas)
	var datos := Guardado.a_diccionario(original, &"rio")
	var cargado := Guardado.desde_diccionario(datos, piezas)
	var t: Tablero = cargado["tablero"]
	afirmar_igual(t.cantidad(), 3, "mismas celdas")
	afirmar_igual(cargado["pieza_actual"], &"rio", "pieza actual conservada")
	for coord in original.coordenadas():
		afirmar_igual(t.pieza_en(coord).id, original.pieza_en(coord).id, "pieza en %s" % str(coord))
		afirmar_igual(t.giro_en(coord), original.giro_en(coord), "giro en %s" % str(coord))


func prueba_ida_y_vuelta_por_archivo() -> void:
	var piezas := _catalogo()
	var original := _tablero_de_ejemplo(piezas)
	afirmar(Guardado.guardar(RUTA, Guardado.a_diccionario(original, &"prado")), "se guarda")
	var cargado := Guardado.desde_diccionario(Guardado.leer(RUTA), piezas)
	afirmar(not cargado.is_empty(), "se carga")
	afirmar_igual((cargado["tablero"] as Tablero).cantidad(), 3, "celdas tras archivo")
	# Guardar encima de un archivo existente también funciona.
	afirmar(Guardado.guardar(RUTA, Guardado.a_diccionario(Tablero.new(), &"")), "se sobrescribe")
	DirAccess.remove_absolute(RUTA)


func prueba_archivo_inexistente_o_corrupto() -> void:
	afirmar(Guardado.leer("user://no_existe_jamas.json").is_empty(), "inexistente -> vacío")
	var f := FileAccess.open(RUTA, FileAccess.WRITE)
	f.store_string("esto { no es json")
	f.close()
	afirmar(Guardado.leer(RUTA).is_empty(), "corrupto -> vacío")
	DirAccess.remove_absolute(RUTA)


func prueba_datos_invalidos() -> void:
	var piezas := _catalogo()
	afirmar(Guardado.desde_diccionario({}, piezas).is_empty(), "vacío")
	afirmar(Guardado.desde_diccionario({"version": 99, "celdas": []}, piezas).is_empty(), "versión futura")
	afirmar(Guardado.desde_diccionario({"version": 1, "celdas": "mal"}, piezas).is_empty(), "celdas no es lista")
	afirmar(Guardado.desde_diccionario({"version": 1, "celdas": []}, piezas).is_empty(), "sin piezas")


func prueba_omite_piezas_desconocidas_sin_perder_el_resto() -> void:
	var piezas := _catalogo()
	var datos := {
		"version": 1,
		"pieza_actual": "prado",
		"celdas": [
			{"q": 0, "r": 0, "pieza": "prado", "giro": 0},
			{"q": 1, "r": 0, "pieza": "dragon", "giro": 0},
			{"q": 0, "r": 1, "pieza": "rio", "giro": 2},
			"basura",
		],
	}
	var cargado := Guardado.desde_diccionario(datos, piezas)
	afirmar_igual((cargado["tablero"] as Tablero).cantidad(), 2, "se conservan las conocidas")
	afirmar_igual(cargado["omitidas"], 2, "dos omitidas")
