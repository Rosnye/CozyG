extends "res://tests/prueba_base.gd"


func _pieza(id: StringName) -> PiezaDatos:
	var p := PiezaDatos.new()
	p.id = id
	return p


func prueba_primera_pieza_en_cualquier_sitio() -> void:
	var t := Tablero.new()
	afirmar(t.puede_colocar(Vector2i(5, -7)), "tablero vacío acepta cualquier hueco")
	afirmar(t.colocar(Vector2i(5, -7), _pieza(&"a")), "se coloca la primera")
	afirmar_igual(t.cantidad(), 1, "una celda")


func prueba_exige_adyacencia() -> void:
	var t := Tablero.new()
	t.colocar(Vector2i.ZERO, _pieza(&"a"))
	afirmar(not t.puede_colocar(Vector2i(2, 0)), "hueco lejano no vale")
	afirmar(not t.colocar(Vector2i(2, 0), _pieza(&"b")), "colocar lejos falla")
	afirmar(t.colocar(Vector2i(1, 0), _pieza(&"b")), "colocar al lado funciona")
	afirmar(t.puede_colocar(Vector2i(2, 0)), "ahora (2,0) toca a (1,0)")


func prueba_no_pisa_ocupadas() -> void:
	var t := Tablero.new()
	t.colocar(Vector2i.ZERO, _pieza(&"a"))
	afirmar(not t.colocar(Vector2i.ZERO, _pieza(&"b")), "no se pisa")
	afirmar_igual(t.pieza_en(Vector2i.ZERO).id, &"a", "sigue la original")


func prueba_giro_se_normaliza() -> void:
	var t := Tablero.new()
	t.colocar(Vector2i.ZERO, _pieza(&"a"), 8)
	afirmar_igual(t.giro_en(Vector2i.ZERO), 2, "8 -> 2")
	t.colocar(Vector2i(1, 0), _pieza(&"b"), -1)
	afirmar_igual(t.giro_en(Vector2i(1, 0)), 5, "-1 -> 5")


func prueba_pieza_nula_rechazada() -> void:
	var t := Tablero.new()
	afirmar(not t.colocar(Vector2i.ZERO, null), "no se coloca null")
	afirmar(t.esta_vacio(), "sigue vacío")


func prueba_frontera() -> void:
	var t := Tablero.new()
	afirmar_igual(t.frontera().size(), 0, "vacío sin frontera")
	t.colocar(Vector2i.ZERO, _pieza(&"a"))
	afirmar_igual(t.frontera().size(), 6, "una pieza -> 6 huecos")
	t.colocar(Vector2i(1, 0), _pieza(&"b"))
	afirmar_igual(t.frontera().size(), 8, "dos vecinas -> 8 huecos sin repetir")
	for coord in t.frontera():
		afirmar(t.puede_colocar(coord), "cada hueco de la frontera es válido")
