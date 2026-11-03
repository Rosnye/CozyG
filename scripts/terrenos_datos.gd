class_name TerrenosDatos
extends Resource
## Colores de cada tipo de terreno (agua, bosque, prado...), como dato.
## Los bordes de las piezas usan estos ids; el dibujo pide aquí su color.

## StringName (id del terreno) -> Color
@export var colores: Dictionary = {}


func color_de(id: StringName, por_defecto: Color = Color.MAGENTA) -> Color:
	return colores.get(id, por_defecto)
