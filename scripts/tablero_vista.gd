class_name TableroVista
extends Node2D
## Dibuja el tablero. Solo lee datos: no decide reglas.
## Mientras una pieza no tenga `arte`, se pinta su color plano (arte provisional).

@export var tamano_hex: float = 64.0
@export var color_contorno: Color = Color(0.3, 0.26, 0.2, 0.55)
@export var color_hueco: Color = Color(0.42, 0.36, 0.28, 0.3)
@export var color_marca: Color = Color(1, 1, 1, 0.85)
@export var color_seleccion: Color = Color(1, 1, 1, 0.95)

var tablero: Tablero

var _hay_pendiente: bool = false
var _pendiente_coord: Vector2i = Vector2i.ZERO
var _pendiente_pieza: PiezaDatos
var _pendiente_giro: int = 0


func mostrar_pendiente(coord: Vector2i, pieza: PiezaDatos, giro: int) -> void:
	_hay_pendiente = true
	_pendiente_coord = coord
	_pendiente_pieza = pieza
	_pendiente_giro = giro
	queue_redraw()


func ocultar_pendiente() -> void:
	_hay_pendiente = false
	queue_redraw()


func _draw() -> void:
	if tablero == null:
		return
	for coord in tablero.frontera():
		var contorno := _poligono(coord, 0.94)
		contorno.append(contorno[0])
		draw_polyline(contorno, color_hueco, 2.0, true)
	for coord in tablero.coordenadas():
		_dibujar_pieza(coord, tablero.pieza_en(coord), tablero.giro_en(coord), 1.0)
	if _hay_pendiente and _pendiente_pieza != null:
		_dibujar_pieza(_pendiente_coord, _pendiente_pieza, _pendiente_giro, 0.75)
		var borde := _poligono(_pendiente_coord, 0.97)
		borde.append(borde[0])
		draw_polyline(borde, color_seleccion, 4.0, true)


func _dibujar_pieza(coord: Vector2i, pieza: PiezaDatos, giro: int, opacidad: float) -> void:
	var color: Color = pieza.color
	color.a = opacidad
	var centro: Vector2 = Hex.axial_a_pixel(coord, tamano_hex)
	if pieza.arte != null:
		var lado: float = tamano_hex * Hex.RAIZ3
		draw_texture_rect(pieza.arte, Rect2(centro - Vector2(lado, lado) / 2.0, Vector2(lado, lado)), false, Color(1, 1, 1, opacidad))
	else:
		draw_colored_polygon(_poligono(coord, 0.96), color)
	var contorno := _poligono(coord, 0.96)
	contorno.append(contorno[0])
	draw_polyline(contorno, color_contorno, 2.0, true)
	# Marca hacia el borde 0 de la pieza: hace visible el giro mientras el arte es provisional.
	var direccion: Vector2 = Hex.axial_a_pixel(Hex.DIRECCIONES[posmod(giro, 6)], tamano_hex).normalized()
	var marca: Color = color_marca
	marca.a *= opacidad
	draw_circle(centro + direccion * tamano_hex * 0.6, tamano_hex * 0.11, marca)


func _poligono(coord: Vector2i, escala: float) -> PackedVector2Array:
	var centro: Vector2 = Hex.axial_a_pixel(coord, tamano_hex)
	var puntos: PackedVector2Array = Hex.esquinas(tamano_hex * escala)
	for i in puntos.size():
		puntos[i] += centro
	return puntos
