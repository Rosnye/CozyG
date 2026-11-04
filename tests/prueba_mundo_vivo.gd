extends "res://tests/prueba_base.gd"


func prueba_ciclo_da_la_vuelta() -> void:
	var ciclo := Ciclo.new(100.0, 0.0)
	afirmar(absf(ciclo.fase()) < 0.0001, "empieza en 0")
	ciclo.avanzar(30.0)
	afirmar(absf(ciclo.fase() - 0.3) < 0.0001, "30 de 100 = 0.3")
	ciclo.avanzar(80.0)
	afirmar(absf(ciclo.fase() - 0.1) < 0.0001, "da la vuelta")


func prueba_ciclo_luz_y_noche() -> void:
	var ciclo := Ciclo.new(100.0, 0.25)
	afirmar(ciclo.luz() > 0.99, "mediodía: plena luz")
	afirmar(not ciclo.es_noche(), "mediodía no es noche")
	ciclo.fijar_fase(0.75)
	afirmar(ciclo.luz() < 0.01, "medianoche: sin luz")
	afirmar(ciclo.es_noche(), "medianoche es noche")
	ciclo.fijar_fase(1.25)
	afirmar(absf(ciclo.fase() - 0.25) < 0.0001, "fijar_fase normaliza")


func prueba_ciclo_con_duracion_invalida() -> void:
	var ciclo := Ciclo.new(0.0, 0.5)
	ciclo.avanzar(10.0)
	afirmar(ciclo.fase() >= 0.0 and ciclo.fase() < 1.0, "la fase sigue en rango")


func prueba_clima_empieza_despejado() -> void:
	var clima := Clima.new(1)
	afirmar_igual(clima.estado, Clima.Estado.DESPEJADO, "despejado")
	afirmar(clima.intensidad_lluvia == 0.0, "sin lluvia")


func prueba_clima_llueve_y_para() -> void:
	var clima := Clima.new(7)
	var vio_lluvia: bool = false
	var vio_despejado_tras_lluvia: bool = false
	for i in 20000:  # ~5.5 horas simuladas a 1 s por paso
		clima.avanzar(1.0)
		afirmar(clima.intensidad_lluvia >= 0.0 and clima.intensidad_lluvia <= 1.0, "intensidad en rango")
		if clima.intensidad_lluvia > 0.99:
			vio_lluvia = true
		if vio_lluvia and clima.intensidad_lluvia == 0.0:
			vio_despejado_tras_lluvia = true
	afirmar(vio_lluvia, "llegó a llover del todo")
	afirmar(vio_despejado_tras_lluvia, "luego volvió a despejar")


func prueba_clima_cambia_gradualmente() -> void:
	var clima := Clima.new(3)
	var anterior: float = 0.0
	for i in 20000:
		clima.avanzar(0.5)
		afirmar(absf(clima.intensidad_lluvia - anterior) <= 0.5 / Clima.SEGUNDOS_TRANSICION + 0.0001, "sin saltos bruscos")
		anterior = clima.intensidad_lluvia


func prueba_ambiente_mundo_vacio() -> void:
	var v := Ambiente.volumenes(1.0, 0.0, {}, 0)
	afirmar_igual(v[&"base"], 1.0, "la base siempre suena")
	for capa in [&"melodia", &"agua", &"aves", &"grillos", &"lluvia"]:
		afirmar_igual(v[capa], 0.0, "%s en silencio" % capa)


func prueba_ambiente_dia_y_noche() -> void:
	var conteo := {&"bosque": 30, &"prado": 30}
	var dia := Ambiente.volumenes(1.0, 0.0, conteo, 10)
	var noche := Ambiente.volumenes(0.0, 0.0, conteo, 10)
	afirmar(dia[&"aves"] > 0.5, "de día cantan aves")
	afirmar(dia[&"grillos"] < 0.01, "de día no hay grillos")
	afirmar(noche[&"grillos"] > 0.5, "de noche hay grillos")
	afirmar(noche[&"aves"] < 0.01, "de noche no hay aves")


func prueba_ambiente_agua_y_lluvia() -> void:
	var con_agua := Ambiente.volumenes(1.0, 0.0, {&"agua": 40, &"prado": 10}, 10)
	var sin_agua := Ambiente.volumenes(1.0, 0.0, {&"prado": 40}, 10)
	afirmar(con_agua[&"agua"] > 0.5, "con mucha agua suena")
	afirmar_igual(sin_agua[&"agua"], 0.0, "sin agua no suena")
	var lloviendo := Ambiente.volumenes(1.0, 1.0, {&"bosque": 30, &"prado": 30}, 10)
	afirmar_igual(lloviendo[&"lluvia"], 1.0, "capa de lluvia a tope")
	afirmar_igual(lloviendo[&"aves"], 0.0, "con lluvia callan las aves")


func prueba_ambiente_melodia_crece_con_el_mundo() -> void:
	var pocas := Ambiente.volumenes(1.0, 0.0, {&"prado": 6}, 2)
	var muchas := Ambiente.volumenes(1.0, 0.0, {&"prado": 6}, 30)
	afirmar(muchas[&"melodia"] > pocas[&"melodia"], "más piezas, más melodía")
	for capa in Ambiente.CAPAS:
		afirmar(muchas[capa] >= 0.0 and muchas[capa] <= 1.0, "%s en rango" % capa)


func prueba_guardado_conserva_datos_extra() -> void:
	var t := Tablero.new()
	var p := PiezaDatos.new()
	p.id = &"prado"
	t.colocar(Vector2i.ZERO, p)
	var datos := Guardado.a_diccionario(t, &"prado", {"fase": 0.4, "criaturas": [{"criatura": "conejo", "q": 0, "r": 0}]})
	var texto := JSON.stringify(datos)
	var json := JSON.new()
	afirmar_igual(json.parse(texto), OK, "es JSON válido")
	var cargado := Guardado.desde_diccionario(json.data, {&"prado": p})
	afirmar(absf(float(cargado["datos"]["fase"]) - 0.4) < 0.0001, "la fase sobrevive")
	afirmar_igual((cargado["datos"]["criaturas"] as Array).size(), 1, "las criaturas sobreviven")
