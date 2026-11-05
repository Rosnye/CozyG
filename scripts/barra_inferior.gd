class_name BarraInferior
extends BoxContainer
## Barra de la pieza actual. En pantallas estrechas (móvil en vertical) apila los datos
## encima de los botones; en las anchas los pone en una sola fila.

## Ancho (en unidades del juego) por debajo del cual se apila.
@export var ancho_para_apilar: float = 760.0


func _ready() -> void:
	get_tree().root.size_changed.connect(_adaptar)
	_adaptar()


func _adaptar() -> void:
	var estrecha: bool = get_viewport_rect().size.x < ancho_para_apilar
	vertical = estrecha
	var espacio := get_node_or_null("Espacio") as Control
	if espacio != null:
		espacio.visible = not estrecha
	var botones := get_node_or_null("Botones") as Control
	if botones != null:
		botones.size_flags_horizontal = Control.SIZE_FILL if estrecha else Control.SIZE_SHRINK_END
