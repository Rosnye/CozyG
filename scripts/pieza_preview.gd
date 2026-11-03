class_name PiezaPreview
extends Control
## Miniatura de la pieza actual (con su giro) para la barra de interfaz.

@export var tamano_hex: float = 36.0

var terrenos: TerrenosDatos

var _pieza: PiezaDatos
var _giro: int = 0


func mostrar(pieza: PiezaDatos, giro: int) -> void:
	_pieza = pieza
	_giro = giro
	queue_redraw()


func _draw() -> void:
	if _pieza != null:
		DibujoPieza.dibujar(self, size / 2.0, tamano_hex, _pieza, _giro, terrenos)
