class_name CapaDinamica
extends Node2D
## Capa del tablero que cambia a menudo: fantasma, selección, guías y animaciones.
## Está separada de las piezas fijas para que esas no se redibujen en cada fotograma.
## Solo delega el dibujo en `TableroVista`.

var vista: TableroVista


func _draw() -> void:
	if vista != null:
		vista.dibujar_dinamico(self)
