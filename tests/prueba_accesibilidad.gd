extends "res://tests/prueba_base.gd"


func _tema_de_prueba() -> Theme:
	var tema := Theme.new()
	tema.default_font_size = 20
	tema.set_font_size(&"font_size", &"Button", 30)
	tema.set_font_size(&"font_size", &"TituloLabel", 64)
	return tema


func prueba_escalar_tema_multiplica_todos_los_tamanos() -> void:
	var tema: Theme = _tema_de_prueba()
	Accesibilidad.escalar_tema(tema, 1.4)
	afirmar_igual(tema.default_font_size, 28, "tamaño por defecto")
	afirmar_igual(tema.get_font_size(&"font_size", &"Button"), 42, "botones")
	afirmar_igual(tema.get_font_size(&"font_size", &"TituloLabel"), 90, "título (redondeado)")


func prueba_escalar_tema_no_acumula() -> void:
	var tema: Theme = _tema_de_prueba()
	Accesibilidad.escalar_tema(tema, 1.4)
	Accesibilidad.escalar_tema(tema, 1.4)
	afirmar_igual(tema.get_font_size(&"font_size", &"Button"), 42, "dos veces 1,4 sigue siendo 1,4")
	Accesibilidad.escalar_tema(tema, 1.0)
	afirmar_igual(tema.get_font_size(&"font_size", &"Button"), 30, "volver a Normal recupera el original")
	afirmar_igual(tema.default_font_size, 20, "también el tamaño por defecto")


func prueba_escala_valida_elige_la_mas_cercana() -> void:
	afirmar_igual(Accesibilidad.escala_valida(1.0), 1.0, "Normal")
	afirmar_igual(Accesibilidad.escala_valida(1.22), 1.2, "cerca de Grande")
	afirmar_igual(Accesibilidad.escala_valida(9.0), 1.4, "demasiado grande se limita")
	afirmar_igual(Accesibilidad.escala_valida(0.1), 1.0, "demasiado pequeño se limita")


func prueba_cada_terreno_tiene_marca() -> void:
	var terrenos: TerrenosDatos = load("res://data/terrenos.tres")
	afirmar(not terrenos.colores.is_empty(), "hay terrenos")
	for id: StringName in terrenos.colores:
		afirmar(terrenos.marca_de(id) != null, "el terreno %s tiene marca para daltonismo" % id)


func prueba_las_marcas_son_distintas() -> void:
	var terrenos: TerrenosDatos = load("res://data/terrenos.tres")
	var vistas: Dictionary = {}
	for id: StringName in terrenos.marcas:
		var ruta: String = (terrenos.marcas[id] as Texture2D).resource_path
		afirmar(not vistas.has(ruta), "la marca de %s no se repite" % id)
		vistas[ruta] = true


func prueba_los_colores_del_fantasma_se_distinguen_sin_verde() -> void:
	# Azul frente a naranja: la diferencia de azul tiene que ser grande (no solo de verde/rojo).
	var encaje: Color = Accesibilidad.COLOR_ENCAJE_DALTONISMO
	var desajuste: Color = Accesibilidad.COLOR_DESAJUSTE_DALTONISMO
	afirmar(encaje.b - desajuste.b > 0.6, "el encaje es claramente más azul que el desajuste")


func prueba_tramos_de_una_pieza_de_un_solo_terreno() -> void:
	var t: Array[Dictionary] = Accesibilidad.tramos([&"prado", &"prado", &"prado", &"prado", &"prado", &"prado"])
	afirmar_igual(t.size(), 1, "un solo tramo")
	afirmar_igual(t[0]["largo"], 6, "con los seis bordes")


func prueba_tramos_que_dan_la_vuelta() -> void:
	# Agua en 5, 0 y 1 (un tramo que cruza el final de la lista) y bosque en 2, 3 y 4.
	var t: Array[Dictionary] = Accesibilidad.tramos([&"agua", &"agua", &"bosque", &"bosque", &"bosque", &"agua"])
	afirmar_igual(t.size(), 2, "dos tramos")
	var por_terreno: Dictionary = {}
	for tramo in t:
		por_terreno[tramo["terreno"]] = tramo
	afirmar_igual(por_terreno[&"agua"]["inicio"], 5, "el agua empieza en el borde 5")
	afirmar_igual(por_terreno[&"agua"]["largo"], 3, "y ocupa tres bordes")
	afirmar_igual(por_terreno[&"bosque"]["inicio"], 2, "el bosque empieza en el 2")


func prueba_tramos_alternos() -> void:
	var t: Array[Dictionary] = Accesibilidad.tramos([&"agua", &"prado", &"agua", &"prado", &"agua", &"prado"])
	afirmar_igual(t.size(), 6, "seis tramos de uno")
