extends "res://tests/prueba_base.gd"


func _pieza(id: StringName, peso: int) -> PiezaDatos:
	var p := PiezaDatos.new()
	p.id = id
	p.peso = peso
	return p


func prueba_mazo_vacio_devuelve_null() -> void:
	var mazo := Mazo.new([] as Array[PiezaDatos], 1)
	afirmar(mazo.robar() == null, "sin piezas no hay robo")


func prueba_misma_semilla_misma_secuencia() -> void:
	var piezas: Array[PiezaDatos] = [_pieza(&"a", 1), _pieza(&"b", 1), _pieza(&"c", 1)]
	var uno := Mazo.new(piezas, 42)
	var dos := Mazo.new(piezas, 42)
	for i in 30:
		afirmar_igual(uno.robar().id, dos.robar().id, "robo %d" % i)


func prueba_ignora_peso_cero() -> void:
	var piezas: Array[PiezaDatos] = [_pieza(&"a", 0), _pieza(&"b", 2)]
	var mazo := Mazo.new(piezas, 7)
	for i in 50:
		afirmar_igual(mazo.robar().id, &"b", "solo sale la de peso positivo")


func prueba_respeta_pesos_aproximadamente() -> void:
	var piezas: Array[PiezaDatos] = [_pieza(&"raro", 1), _pieza(&"comun", 9)]
	var mazo := Mazo.new(piezas, 123)
	var raros: int = 0
	for i in 4000:
		if mazo.robar().id == &"raro":
			raros += 1
	afirmar(raros > 250 and raros < 550, "~10%% raras, salieron %d de 4000" % raros)
