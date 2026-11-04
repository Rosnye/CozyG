extends "res://tests/prueba_base.gd"


func prueba_empieza_en_la_bienvenida() -> void:
	var t := Tutorial.new()
	afirmar(t.terminado(), "sin iniciar no está activo")
	t.iniciar()
	afirmar(not t.terminado(), "activo tras iniciar")
	afirmar_igual(t.paso, Tutorial.Paso.BIENVENIDA, "primer paso")
	afirmar(t.tiene_boton(), "la bienvenida tiene botón")
	afirmar(t.texto().contains("aserradero"), "sugiere empezar con un aserradero")


func prueba_recorrido_normal() -> void:
	var t := Tutorial.new()
	t.iniciar()
	t.siguiente()
	afirmar_igual(t.paso, Tutorial.Paso.COLOCAR, "tras el botón")
	afirmar(not t.tiene_boton(), "los pasos de acción no tienen botón")
	afirmar(t.evento(&"hueco_elegido"), "elegir hueco avanza")
	afirmar_igual(t.paso, Tutorial.Paso.GIRAR, "girar")
	t.evento(&"girado")
	afirmar_igual(t.paso, Tutorial.Paso.CONFIRMAR, "confirmar")
	t.evento(&"pieza_colocada")
	afirmar_igual(t.paso, Tutorial.Paso.ELEGIR_PIEZA, "elegir pieza")
	t.evento(&"pieza_seleccionada")
	afirmar_igual(t.paso, Tutorial.Paso.CONSTRUIR, "construir")
	t.evento(&"construido")
	afirmar_igual(t.paso, Tutorial.Paso.FINAL, "final")
	afirmar(t.tiene_boton(), "el final tiene botón")
	t.siguiente()
	afirmar(t.terminado(), "termina con el botón del final")


func prueba_si_el_jugador_se_adelanta_no_se_queda_atras() -> void:
	var t := Tutorial.new()
	t.iniciar()
	t.siguiente()
	t.evento(&"pieza_colocada")  # confirma sin haber girado
	afirmar_igual(t.paso, Tutorial.Paso.ELEGIR_PIEZA, "salta directo a elegir la pieza")


func prueba_nunca_retrocede() -> void:
	var t := Tutorial.new()
	t.iniciar()
	t.siguiente()
	t.evento(&"pieza_colocada")
	afirmar(not t.evento(&"hueco_elegido"), "un evento antiguo no cambia nada")
	afirmar_igual(t.paso, Tutorial.Paso.ELEGIR_PIEZA, "sigue donde estaba")


func prueba_la_bienvenida_y_el_final_solo_se_cierran_con_su_boton() -> void:
	var t := Tutorial.new()
	t.iniciar()
	afirmar(not t.evento(&"hueco_elegido"), "en la bienvenida las acciones no avanzan")
	afirmar_igual(t.paso, Tutorial.Paso.BIENVENIDA, "sigue en la bienvenida")
	t.paso = Tutorial.Paso.FINAL
	afirmar(not t.evento(&"construido"), "en el final tampoco")


func prueba_saltar_en_cualquier_momento() -> void:
	var t := Tutorial.new()
	t.iniciar()
	t.siguiente()
	t.evento(&"girado")
	t.saltar()
	afirmar(t.terminado(), "saltado")
	afirmar(not t.evento(&"construido"), "ya no reacciona")
	afirmar_igual(t.texto(), "", "sin texto")
	afirmar(not t.tiene_boton(), "sin botón")


func prueba_eventos_desconocidos_se_ignoran() -> void:
	var t := Tutorial.new()
	t.iniciar()
	t.siguiente()
	afirmar(not t.evento(&"algo_raro"), "ignorado")
	afirmar_igual(t.paso, Tutorial.Paso.COLOCAR, "sin cambios")


func prueba_guardar_y_restaurar() -> void:
	var t := Tutorial.new()
	t.iniciar()
	t.siguiente()
	t.evento(&"girado")
	var otro := Tutorial.new()
	otro.desde_diccionario(t.a_diccionario())
	afirmar(not otro.terminado(), "sigue activo")
	afirmar_igual(otro.paso, Tutorial.Paso.CONFIRMAR, "mismo paso")
	var viejo := Tutorial.new()
	viejo.desde_diccionario({})
	afirmar(viejo.terminado(), "una partida antigua sin datos no muestra tutorial")
	var raro := Tutorial.new()
	raro.desde_diccionario({"activo": true, "paso": 99})
	afirmar(raro.terminado(), "un paso fuera de rango se da por terminado")


func prueba_todos_los_pasos_con_texto_tienen_texto() -> void:
	for paso in [Tutorial.Paso.BIENVENIDA, Tutorial.Paso.COLOCAR, Tutorial.Paso.GIRAR, Tutorial.Paso.CONFIRMAR,
			Tutorial.Paso.ELEGIR_PIEZA, Tutorial.Paso.CONSTRUIR, Tutorial.Paso.FINAL]:
		afirmar(Tutorial.TEXTOS.has(paso) and Tutorial.TEXTOS[paso] != "", "el paso %d tiene texto" % paso)
