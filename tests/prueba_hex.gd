extends "res://tests/prueba_base.gd"


func prueba_seis_vecinos_distintos_a_distancia_uno() -> void:
	var origen := Vector2i(2, -3)
	var vistos: Dictionary = {}
	for vecino in Hex.vecinos(origen):
		afirmar_igual(Hex.distancia(origen, vecino), 1, "vecino a distancia 1")
		vistos[vecino] = true
	afirmar_igual(vistos.size(), 6, "vecinos distintos")


func prueba_direccion_opuesta() -> void:
	for d in 6:
		var ida: Vector2i = Hex.vecino(Vector2i.ZERO, d)
		var vuelta: Vector2i = Hex.vecino(ida, d + 3)
		afirmar_igual(vuelta, Vector2i.ZERO, "dirección %d + 3 vuelve al origen" % d)


func prueba_distancia() -> void:
	afirmar_igual(Hex.distancia(Vector2i.ZERO, Vector2i.ZERO), 0, "misma celda")
	afirmar_igual(Hex.distancia(Vector2i.ZERO, Vector2i(3, 0)), 3, "en línea")
	afirmar_igual(Hex.distancia(Vector2i(0, 0), Vector2i(2, -3)), 3, "diagonal")
	afirmar_igual(Hex.distancia(Vector2i(-2, 1), Vector2i(1, 2)), 4, "cruzada")


func prueba_pixel_ida_y_vuelta() -> void:
	for q in range(-6, 7):
		for r in range(-6, 7):
			var coord := Vector2i(q, r)
			var centro: Vector2 = Hex.axial_a_pixel(coord, 64.0)
			afirmar_igual(Hex.pixel_a_axial(centro, 64.0), coord, "centro de %s" % str(coord))


func prueba_punto_cercano_al_centro_cae_en_su_hexagono() -> void:
	var coord := Vector2i(3, -2)
	var centro: Vector2 = Hex.axial_a_pixel(coord, 50.0)
	for desplazamiento in [Vector2(10, 5), Vector2(-12, 8), Vector2(0, -20), Vector2(20, 0)]:
		afirmar_igual(Hex.pixel_a_axial(centro + desplazamiento, 50.0), coord, "punto %s" % str(desplazamiento))


func prueba_esquinas() -> void:
	var puntos: PackedVector2Array = Hex.esquinas(10.0)
	afirmar_igual(puntos.size(), 6, "seis esquinas")
	for p in puntos:
		afirmar(absf(p.length() - 10.0) < 0.001, "esquina a radio 10")
