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
		var lado: float = radio * Hex.RAIZ3
		item.draw_texture_rect(
			pieza.arte, Rect2(centro - Vector2(lado, lado) / 2.0, Vector2(lado, lado)),
			false, Color(1, 1, 1, opacidad)
		)
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
