extends "res://tests/prueba_base.gd"

const A: StringName = &"agua"
const B: StringName = &"bosque"
const P: StringName = &"prado"
const T: StringName = &"tierra"


func _pieza(id: StringName, bordes: Array[StringName]) -> PiezaDatos:
	var p := PiezaDatos.new()
	p.id = id
	p.bordes = bordes
	return p


func _construccion(id: StringName, produce: StringName, afinidad: Dictionary, costo: Dictionary, por_minuto: float = 60.0) -> ConstruccionDatos:
	var c := ConstruccionDatos.new()
	c.id = id
	c.produce = produce
	c.afinidad = afinidad
	c.costo = costo
	c.por_minuto = por_minuto
	return c


func _recurso(id: StringName, inicial: int) -> RecursoDatos:
	var r := RecursoDatos.new()
	r.id = id
	r.inicial = inicial
	return r


func _economia(madera: int = 20) -> Economia:
	var e := Economia.new()
	e.iniciar([_recurso(&"madera", madera), _recurso(&"trigo", 0)] as Array[RecursoDatos])
	return e


func _bosque() -> PiezaDatos:
	return _pieza(&"bosque", [B, B, B, B, B, B] as Array[StringName])


func prueba_eficiencia_segun_los_bordes() -> void:
	var aserradero := _construccion(&"aserradero", &"madera", {B: 1.0}, {})
	afirmar_igual(Economia.eficiencia(aserradero, _bosque()), 1.0, "bosque puro: 100 %")
	var claro := _pieza(&"claro", [B, B, B, P, P, P] as Array[StringName])
	afirmar_igual(Economia.eficiencia(aserradero, claro), 0.5, "mitad bosque: 50 %")
	var agua := _pieza(&"agua", [A, A, A, A, A, A] as Array[StringName])
	afirmar_igual(Economia.eficiencia(aserradero, agua), 0.0, "sin bosque: 0 %")


func prueba_afinidad_parcial() -> void:
	var granja := _construccion(&"granja", &"trigo", {T: 1.0, P: 0.3}, {})
	var campo := _pieza(&"campo", [T, T, T, P, P, P] as Array[StringName])
	afirmar(absf(Economia.eficiencia(granja, campo) - 0.65) < 0.0001, "3 de tierra y 3 de prado a 0.3 = 65 %")


func prueba_inicio_con_recursos_iniciales() -> void:
	var e := _economia(20)
	afirmar_igual(e.cantidad(&"madera"), 20, "madera inicial")
	afirmar_igual(e.cantidad(&"trigo"), 0, "trigo inicial")
	afirmar_igual(e.cantidad(&"desconocido"), 0, "recurso desconocido = 0")


func prueba_construir_cobra_el_costo() -> void:
	var e := _economia(20)
	var t := Tablero.new()
	t.colocar(Vector2i.ZERO, _bosque())
	var aserradero := _construccion(&"aserradero", &"madera", {B: 1.0}, {&"madera": 8})
	afirmar(e.construir(Vector2i.ZERO, aserradero, t), "se construye")
	afirmar_igual(e.cantidad(&"madera"), 12, "se cobraron 8")
	afirmar(not e.construir(Vector2i.ZERO, aserradero, t), "no se construye dos veces en la misma pieza")
	afirmar_igual(e.cantidad(&"madera"), 12, "y no se cobra de nuevo")


func prueba_no_se_construye_sin_fondos_ni_sin_pieza_ni_sin_rendimiento() -> void:
	var e := _economia(5)
	var t := Tablero.new()
	t.colocar(Vector2i.ZERO, _bosque())
	var cara := _construccion(&"cara", &"madera", {B: 1.0}, {&"madera": 8})
	afirmar(not e.construir(Vector2i.ZERO, cara, t), "sin fondos")
	afirmar_igual(e.cantidad(&"madera"), 5, "no se cobra")
	var barata := _construccion(&"barata", &"madera", {B: 1.0}, {&"madera": 1})
	afirmar(not e.construir(Vector2i(3, 3), barata, t), "no hay pieza ahí")
	var pesqueria := _construccion(&"pesqueria", &"pescado", {A: 1.0}, {&"madera": 1})
	afirmar(not e.construir(Vector2i.ZERO, pesqueria, t), "en bosque una pesquería no rinde: no se permite")


func prueba_costo_con_varios_recursos() -> void:
	var e := Economia.new()
	e.iniciar([_recurso(&"madera", 20), _recurso(&"piedra", 5)] as Array[RecursoDatos])
	var t := Tablero.new()
	t.colocar(Vector2i.ZERO, _bosque())
	var mina := _construccion(&"mina", &"mineral", {B: 1.0}, {&"madera": 15, &"piedra": 10})
	afirmar(not e.puede_construir(Vector2i.ZERO, mina, t), "falta piedra")
	afirmar(not e.puede_pagar(mina.costo), "no puede pagar")


func prueba_quitar_devuelve_la_mitad() -> void:
	var e := _economia(20)
	var t := Tablero.new()
	t.colocar(Vector2i.ZERO, _bosque())
	var aserradero := _construccion(&"aserradero", &"madera", {B: 1.0}, {&"madera": 9})
	e.construir(Vector2i.ZERO, aserradero, t)
	afirmar_igual(e.cantidad(&"madera"), 11, "tras construir")
	afirmar(e.quitar(Vector2i.ZERO), "se quita")
	afirmar_igual(e.cantidad(&"madera"), 15, "se devuelve la mitad redondeada hacia abajo (4 de 9)")
	afirmar(not e.quitar(Vector2i.ZERO), "ya no hay nada que quitar")


func prueba_produce_con_el_tiempo() -> void:
	var e := _economia(20)
	var t := Tablero.new()
	t.colocar(Vector2i.ZERO, _bosque())
	var aserradero := _construccion(&"aserradero", &"madera", {B: 1.0}, {}, 60.0)  # 1 por segundo
	e.construir(Vector2i.ZERO, aserradero, t)
	e.avanzar(10.0, t)
	afirmar_igual(e.cantidad(&"madera"), 30, "10 s = +10")
	# Con 50 % de rendimiento, la mitad.
	var claro := _pieza(&"claro", [B, B, B, P, P, P] as Array[StringName])
	t.colocar(Vector2i(1, 0), claro)
	e.construir(Vector2i(1, 0), aserradero, t)
	e.avanzar(10.0, t)
	afirmar_igual(e.cantidad(&"madera"), 45, "otros 10 s: +10 del primero y +5 del segundo")


func prueba_las_fracciones_se_acumulan() -> void:
	var e := _economia(0)
	var t := Tablero.new()
	t.colocar(Vector2i.ZERO, _bosque())
	var lento := _construccion(&"lento", &"madera", {B: 1.0}, {}, 30.0)  # 0.5 por segundo
	e.construir(Vector2i.ZERO, lento, t)
	for i in 3:
		e.avanzar(1.0, t)
	afirmar_igual(e.cantidad(&"madera"), 1, "1.5 se muestra como 1")
	e.avanzar(1.0, t)
	afirmar_igual(e.cantidad(&"madera"), 2, "2.0 se muestra como 2")


func prueba_guardar_y_restaurar() -> void:
	var e := _economia(20)
	var t := Tablero.new()
	t.colocar(Vector2i.ZERO, _bosque())
	var aserradero := _construccion(&"aserradero", &"madera", {B: 1.0}, {&"madera": 8})
	e.construir(Vector2i.ZERO, aserradero, t)
	e.avanzar(5.0, t)
	var texto := JSON.stringify(e.a_diccionario())
	var json := JSON.new()
	afirmar_igual(json.parse(texto), OK, "JSON válido")
	var otra := _economia(20)
	otra.desde_diccionario(json.data, {&"aserradero": aserradero}, t)
	afirmar_igual(otra.cantidad(&"madera"), e.cantidad(&"madera"), "misma madera")
	afirmar(otra.construcciones.has(Vector2i.ZERO), "misma construcción")
	# Construcciones desconocidas, basura o sobre piezas inexistentes se ignoran.
	var sucio := {
		"recursos": {"madera": 3.0},
		"construcciones": [
			{"q": 0, "r": 0, "construccion": "dragon"},
			{"q": 9, "r": 9, "construccion": "aserradero"},
			"basura",
		],
	}
	otra.desde_diccionario(sucio, {&"aserradero": aserradero}, t)
	afirmar(otra.construcciones.is_empty(), "nada válido que restaurar")
	afirmar_igual(otra.cantidad(&"madera"), 3, "los recursos sí se restauran")


func prueba_multiplicador_por_vecinas() -> void:
	afirmar_igual(Economia.multiplicador(0), 1.0, "sin vecinas: sin bonus")
	afirmar(absf(Economia.multiplicador(1) - 1.05) < 0.0001, "una vecina: +5 %")
	afirmar(absf(Economia.multiplicador(6) - 1.30) < 0.0001, "seis vecinas: +30 %")


func prueba_vecinas_iguales_cuenta_solo_el_mismo_tipo() -> void:
	var t := Tablero.new()
	var bosque := _bosque()
	var prado := _pieza(&"prado", [P, P, P, P, P, P] as Array[StringName])
	t.colocar(Vector2i.ZERO, bosque)
	t.colocar(Vector2i(1, 0), bosque)   # igual
	t.colocar(Vector2i(0, 1), prado)    # distinta
	t.colocar(Vector2i(-1, 1), bosque)  # igual
	afirmar_igual(t.vecinas_iguales(Vector2i.ZERO, bosque), 2, "dos bosques y un prado alrededor")
	afirmar_igual(t.vecinas_iguales(Vector2i(0, -1), bosque), 1, "un hueco vacío cuenta sus vecinas")
	afirmar_igual(t.vecinas_iguales(Vector2i(5, 5), bosque), 0, "lejos: ninguna")


func prueba_produccion_con_bonus_por_vecinas() -> void:
	var e := _economia(0)
	var t := Tablero.new()
	var bosque := _bosque()
	t.colocar(Vector2i.ZERO, bosque)
	var aserradero := _construccion(&"aserradero", &"madera", {B: 1.0}, {}, 60.0)  # 1 por segundo
	e.construir(Vector2i.ZERO, aserradero, t)
	afirmar(absf(e.por_minuto_en(Vector2i.ZERO, aserradero, t) - 60.0) < 0.0001, "sin vecinas: 60/min")
	t.colocar(Vector2i(1, 0), bosque)
	t.colocar(Vector2i(0, 1), bosque)
	afirmar(absf(e.por_minuto_en(Vector2i.ZERO, aserradero, t) - 66.0) < 0.0001, "dos vecinas iguales: +10 %")
	e.avanzar(10.0, t)
	afirmar_igual(e.cantidad(&"madera"), 11, "10 s a 1,1 por segundo = 11")


func prueba_el_bonus_no_aplica_con_vecinas_de_otro_tipo() -> void:
	var e := _economia(0)
	var t := Tablero.new()
	t.colocar(Vector2i.ZERO, _bosque())
	t.colocar(Vector2i(1, 0), _pieza(&"claro", [B, B, B, P, P, P] as Array[StringName]))
	var aserradero := _construccion(&"aserradero", &"madera", {B: 1.0}, {}, 60.0)
	e.construir(Vector2i.ZERO, aserradero, t)
	afirmar(absf(e.por_minuto_en(Vector2i.ZERO, aserradero, t) - 60.0) < 0.0001, "bosque y claro son tipos distintos")
