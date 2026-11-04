class_name RecursoDatos
extends Resource
## Un recurso del juego (madera, trigo...). El icono es un dato: sin él se usa el color.

@export var id: StringName = &""
@export var nombre: String = ""
@export var color: Color = Color.WHITE
## Cantidad con la que empieza una partida nueva.
@export var inicial: int = 0
@export var icono: Texture2D
