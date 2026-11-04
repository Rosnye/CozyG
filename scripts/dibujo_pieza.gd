class_name DibujoPieza
extends RefCounted
## Dibuja una pieza en cualquier CanvasItem (tablero y vista previa comparten esto).
## Con arte definitivo se pinta la textura; mientras no exista, un sector de color por borde.


static func dibujar(
	item: CanvasItem, centro: Vector2, tamano: float, pieza: PiezaDatos, giro: int,
	terrenos: TerrenosDatos, opacidad: float = 1.0, escala: float = 1.0
) -> void:
	var radio: float = tamano * escala
	if pieza.arte != null:
		# La imagen es un hexágono con el borde 0 mirando al este: se gira de 60° en 60°.
		var tamano_imagen := Vector2(radio * Hex.RAIZ3, radio * 2.0)
		item.draw_set_transform(centro, deg_to_rad(60.0 * giro))
		item.draw_texture_rect(pieza.arte, Rect2(-tamano_imagen / 2.0, tamano_imagen), false, Color(1, 1, 1, opacidad))
		item.draw_set_transform(Vector2.ZERO)
		return
	var esquinas: PackedVector2Array = Hex.esquinas(radio * 0.96)
	for direccion in 6:
		var color: Color = pieza.color
		if terrenos != null:
			color = terrenos.color_de(pieza.borde(direccion, giro), pieza.color)
		color.a = opacidad
		# El borde de la dirección d queda entre las esquinas d y d+1.
		var sector := PackedVector2Array([
			centro, centro + esquinas[direccion], centro + esquinas[(direccion + 1) % 6]
		])
		item.draw_colored_polygon(sector, color)
	var contorno := PackedVector2Array()
	for esquina in esquinas:
		contorno.append(centro + esquina)
	contorno.append(contorno[0])
	item.draw_polyline(contorno, Color(0.3, 0.26, 0.2, 0.55 * opacidad), 2.0, true)
