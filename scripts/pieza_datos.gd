class_name PiezaDatos
extends Resource
## Datos de un tipo de pieza (bosque, agua, prado...).
## El arte vive aquí como dato: mientras `arte` esté vacío se dibuja el color plano.

@export var id: StringName = &""
@export var nombre: String = ""
@export var color: Color = Color.WHITE
## Probabilidad relativa de salir en el mazo.
@export var peso: int = 1
@export var arte: Texture2D
