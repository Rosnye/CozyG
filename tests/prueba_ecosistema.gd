extends "res://tests/prueba_base.gd"

const A: StringName = &"agua"
const P: StringName = &"prado"
const B: StringName = &"bosque"


func _pieza(id: StringName) -> PiezaDatos:
	var p := PiezaDatos.new()
	p.id = id
	p.bordes = [id, id, id, id, id, id] as Array[StringName]
	return p


func _criatura(id: StringName, habitat: StringName, requisitos: Dictionary, maximo: int = 3) -> CriaturaDatos:
	var c := CriaturaDatos.new()
	c.id = id
	c.habitat = habitat
	c.requisitos = requisitos
	c.maximo = maximo
	return c


## Fila de prados en (0,0), (1,0), (2,0)...
func _fila_de_prados(cantidad: int) -> Tablero:
	var t := Tablero.new()
	var prado := _pieza(P)
	for i in cantidad:
		t.colocar(Vector2i(i, 0), prado)
	return t


func prueba_conteo_de_bordes() -> void:
	var t := _fila_de_prados(2)
	t.colocar(Vector2i(0, 1), _pieza(A))
	var conteo := t.conteo_bordes()
	afirmar_igual(conteo[P], 12, "dos prados = 12 bordes")
	afirmar_igual(conteo[A], 6, "un lago = 6 bordes")


func prueba_habitat_necesita_bordes_suficientes() -> void:
	var t := Tablero.new()
	var rio := PiezaDatos.new()
	rio.id = &"rio"
	rio.bordes = [A, P, P, A, P, P] as Array[StringName]
	t.colocar(Vector2i.ZERO, rio)
	afirmar(t.es_habitat(Vector2i.ZERO, A), "río con 2 bordes de agua es hábitat de agua")
	afirmar(t.es_habitat(Vector2i.ZERO, P), "río con 4 de prado es hábitat de prado")
	afirmar(not t.es_habitat(Vector2i.ZERO, B), "sin bosque no")
	afirmar(not t.es_habitat(Vector2i(9, 9), A), "celda vacía no")
	afirmar_igual(t.celdas_habitat(A).size(), 1, "una celda de agua")


func prueba_poblacion_objetivo() -> void:
	var conejo := _criatura(&"conejo", P, {P: 18}, 3)
	afirmar_igual(Ecosistema.poblacion_objetivo(conejo, {}), 0, "sin mundo, nadie")
	afirmar_igual(Ecosistema.poblacion_objetivo(conejo, {P: 17}), 0, "justo por debajo")
	afirmar_igual(Ecosistema.poblacion_objetivo(conejo, {P: 18}), 1, "llega el primero")
	afirmar_igual(Ecosistema.poblacion_objetivo(conejo, {P: 36}), 2, "al duplicar, el segundo")
	afirmar_igual(Ecosistema.poblacion_objetivo(conejo, {P: 999}), 3, "tope en el máximo")


func prueba_poblacion_con_varios_requisitos() -> void:
	var garza := _criatura(&"garza", A, {A: 18, P: 18}, 2)
	afirmar_igual(Ecosistema.poblacion_objetivo(garza, {A: 100, P: 10}), 0, "falta prado")
	afirmar_igual(Ecosistema.poblacion_objetivo(garza, {A: 18, P: 18}), 1, "ambos cumplidos")
	afirmar_igual(Ecosistema.poblacion_objetivo(garza, {A: 100, P: 36}), 2, "manda el requisito más justo")
	var sin_requisitos := _criatura(&"x", A, {})
	afirmar_igual(Ecosistema.poblacion_objetivo(sin_requisitos, {A: 99}), 0, "sin requisitos no llega")


func prueba_llegan_solo_cuando_toca() -> void:
	var conejo := _criatura(&"conejo", P, {P: 18})
	var eco := Ecosistema.new(1)
	var t := _fila_de_prados(2)  # 12 bordes
	afirmar_igual(eco.actualizar(t, [conejo] as Array[CriaturaDatos]).size(), 0, "aún no")
	t.colocar(Vector2i(2, 0), _pieza(P))  # 18 bordes
	var llegadas := eco.actualizar(t, [conejo] as Array[CriaturaDatos])
	afirmar_igual(llegadas.size(), 1, "llega uno")
	afirmar(t.es_habitat(llegadas[0]["coord"], P), "aparece en su hábitat")
	afirmar_igual(eco.actualizar(t, [conejo] as Array[CriaturaDatos]).size(), 0, "no se repite")
	afirmar_igual(eco.cantidad(), 1, "uno en total")


func prueba_no_llegan_sin_habitat() -> void:
	var rana := _criatura(&"rana", A, {P: 6})  # requisito cumplido pero no hay agua
	var eco := Ecosistema.new(1)
	var t := _fila_de_prados(2)
	afirmar_igual(eco.actualizar(t, [rana] as Array[CriaturaDatos]).size(), 0, "sin hábitat no llega")
	afirmar_igual(eco.cantidad(), 0, "nadie")


func prueba_movimiento_se_queda_en_el_habitat() -> void:
	var conejo := _criatura(&"conejo", P, {P: 6})
	var eco := Ecosistema.new(3)
	var t := _fila_de_prados(3)
	t.colocar(Vector2i(3, 0), _pieza(A))  # un lago al final: no es hábitat del conejo
	eco.actualizar(t, [conejo] as Array[CriaturaDatos])
	for i in 200:
		eco.mover_uno(t)
		for individuo in eco.individuos:
			afirmar(t.es_habitat(individuo["coord"], P), "sigue sobre prado (paso %d)" % i)


func prueba_movimiento_sin_vecinos_no_mueve() -> void:
	var conejo := _criatura(&"conejo", P, {P: 6})
	var eco := Ecosistema.new(1)
	var t := _fila_de_prados(1)
	eco.actualizar(t, [conejo] as Array[CriaturaDatos])
	afirmar_igual(eco.cantidad(), 1, "llegó")
	afirmar(eco.mover_uno(t).is_empty(), "una sola pieza: no hay a dónde ir")
	afirmar(Ecosistema.new().mover_uno(t).is_empty(), "sin individuos no hay movimiento")


func prueba_guardar_y_restaurar() -> void:
	var conejo := _criatura(&"conejo", P, {P: 6})
	var eco := Ecosistema.new(5)
	var t := _fila_de_prados(3)
	eco.actualizar(t, [conejo] as Array[CriaturaDatos])
	var datos := eco.a_array()
	var otro := Ecosistema.new(5)
	otro.desde_array(datos, {&"conejo": conejo})
	afirmar_igual(otro.cantidad(), eco.cantidad(), "misma cantidad")
	afirmar_igual(otro.individuos[0]["coord"], eco.individuos[0]["coord"], "misma posición")
	# Un id desconocido o un dato basura se omiten sin romper nada.
	otro.desde_array([{"criatura": "dragon", "q": 0, "r": 0}, "basura", {"criatura": "conejo", "q": 1, "r": 0}], {&"conejo": conejo})
	afirmar_igual(otro.cantidad(), 1, "solo el conejo válido")
