class_name DibujoPieza
extends RefCounted
## Dibuja una pieza en cualquier CanvasItem (tablero y vista previa comparten esto).
## Con arte definitivo se pinta la textura; mientras no exista, un sector de color por borde.
## Con la ayuda para daltonismo (`Preferencias.ayuda_color`) se añade la marca de cada terreno.

## Dónde va la marca de un tramo: fracción del camino del centro al medio de los bordes.
const DISTANCIA_MARCA: float = 0.6
## Lado de la marca, como fracción del radio de la pieza.
const TAMANO_MARCA: float = 0.34


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
		_dibujar_marcas(item, centro, radio, pieza, giro, terrenos, opacidad)
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
	_dibujar_marcas(item, centro, radio, pieza, giro, terrenos, opacidad)


## Una marca por tramo de bordes iguales, hacia el medio del tramo y sin girar (las formas
## se leen siempre derechas). Una pieza de un solo terreno lleva una sola marca.
static func _dibujar_marcas(
	item: CanvasItem, centro: Vector2, radio: float, pieza: PiezaDatos, giro: int,
	terrenos: TerrenosDatos, opacidad: float
) -> void:
	if not Preferencias.ayuda_color or terrenos == null:
		return
	var bordes: Array[StringName] = []
	for direccion in 6:
		bordes.append(pieza.borde(direccion, giro))
	for tramo in Accesibilidad.tramos(bordes):
		var marca: Texture2D = terrenos.marca_de(tramo["terreno"])
		if marca == null:
			continue
		var posicion: Vector2 = centro
		var lado: float = radio * TAMANO_MARCA
		if tramo["largo"] < 6:
			# El punto medio del borde d está a 60°·d; el del tramo, en el medio de sus bordes.
			var angulo: float = deg_to_rad(60.0 * (tramo["inicio"] + (tramo["largo"] - 1) / 2.0))
			posicion += Vector2.from_angle(angulo) * radio * Hex.RAIZ3 / 2.0 * DISTANCIA_MARCA
		else:
			# Un solo terreno: una marca algo mayor, bajo el centro (donde no la tapa una construcción).
			lado *= 1.3
			posicion += Vector2.DOWN * radio * 0.52
		var caja := Rect2(posicion - Vector2(lado, lado) / 2.0, Vector2(lado, lado))
		item.draw_texture_rect(marca, caja, false, Color(1, 1, 1, opacidad))
