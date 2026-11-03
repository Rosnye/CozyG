extends "res://tests/prueba_base.gd"

const A: StringName = &"agua"
const P: StringName = &"prado"
const B: StringName = &"bosque"


func _pieza(id: StringName, bordes: Array[StringName]) -> PiezaDatos:
	var p := PiezaDatos.new()
	p.id = id
	p.bordes = bordes
	return p


func _prado() -> PiezaDatos:
	return _pieza(&"prado", [P, P, P, P, P, P] as Array[StringName])


## Río recto: agua en este y oeste.
func _rio() -> PiezaDatos:
	return _pieza(&"rio", [A, P, P, A, P, P] as Array[StringName])


func prueba_borde_sin_giro() -> void:
	var rio := _rio()
	afirmar_igual(rio.borde(0), A, "este es agua")
	afirmar_igual(rio.borde(1), P, "sureste es prado")
	afirmar_igual(rio.borde(3), A, "oeste es agua")


func prueba_borde_con_giro() -> void:
	var curva := _pieza(&"curva", [A, P, A, P, P, P] as Array[StringName])
	# Girada 1 paso, el borde 0 pasa a mirar al sureste (dirección 1).
	afirmar_igual(curva.borde(1, 1), A, "el agua del este ahora mira al sureste")
	afirmar_igual(curva.borde(0, 1), P, "el este queda con el borde que miraba al noreste")
	# Seis giros dan la vuelta completa.
	for d in 6:
		afirmar_igual(curva.borde(d, 6), curva.borde(d, 0), "giro 6 = giro 0 en dirección %d" % d)
	afirmar_igual(curva.borde(2, -1), curva.borde(2, 5), "giro negativo se normaliza")


func prueba_borde_sin_datos_usa_id() -> void:
	var p := PiezaDatos.new()
	p.id = &"x"
	afirmar_igual(p.borde(2, 3), &"x", "sin bordes, todo es del terreno id")


func prueba_rio_continua() -> void:
	var t := Tablero.new()
	t.colocar(Vector2i.ZERO, _rio(), 0)
	# A la derecha del río, otro río recto: agua con agua.
	afirmar(t.encaja_perfecto(Vector2i(1, 0), _rio(), 0), "río junto a río recto encaja")
	var r := t.evaluar(Vector2i(1, 0), _rio(), 0)
	afirmar_igual(r["vecinos"], 1, "un vecino")
	afirmar_igual(r["coinciden"], 1, "coincide")


func prueba_rio_girado_no_encaja_y_se_corrige_girando() -> void:
	var t := Tablero.new()
	t.colocar(Vector2i.ZERO, _rio(), 0)
	# Río girado 1 paso: su agua mira al sureste y noroeste, no al oeste.
	afirmar(not t.encaja_perfecto(Vector2i(1, 0), _rio(), 1), "río girado no continúa")
	afirmar(t.encaja_perfecto(Vector2i(1, 0), _rio(), 3), "río girado 180° vuelve a encajar")


func prueba_varios_vecinos() -> void:
	var t := Tablero.new()
	t.colocar(Vector2i.ZERO, _prado(), 0)
	t.colocar(Vector2i(1, 0), _prado(), 0)
	# (0,1) toca (0,0) y (1,0). Un lago (todo agua) no coincide con ninguno.
	var lago := _pieza(&"agua", [A, A, A, A, A, A] as Array[StringName])
	var r := t.evaluar(Vector2i(0, 1), lago, 0)
	afirmar_igual(r["vecinos"], 2, "dos vecinos")
	afirmar_igual(r["coinciden"], 0, "ninguna coincidencia")
	afirmar(not t.encaja_perfecto(Vector2i(0, 1), lago, 0), "no es perfecto")
	afirmar(t.encaja_perfecto(Vector2i(0, 1), _prado(), 0), "prado con prado sí")


func prueba_sin_vecinos_no_es_perfecto() -> void:
	var t := Tablero.new()
	t.colocar(Vector2i.ZERO, _prado(), 0)
	afirmar(not t.encaja_perfecto(Vector2i(5, 5), _prado(), 0), "sin vecinos no hay encaje")
	afirmar_igual(t.evaluar(Vector2i(5, 5), _prado(), 0)["vecinos"], 0, "cero vecinos")


func prueba_evaluar_no_modifica_el_tablero() -> void:
	var t := Tablero.new()
	t.colocar(Vector2i.ZERO, _prado(), 0)
	t.evaluar(Vector2i(1, 0), _prado(), 0)
	afirmar_igual(t.cantidad(), 1, "evaluar no coloca")
