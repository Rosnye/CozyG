class_name ConstruccionDatos
extends Resource
## Una construcción que se puede levantar sobre una pieza y produce un recurso.
## Rinde más o menos según los terrenos de los bordes de la pieza (`afinidad`).

@export var id: StringName = &""
@export var nombre: String = ""
@export var color: Color = Color.WHITE
## Recurso que produce.
@export var produce: StringName = &""
## Unidades por minuto con rendimiento del 100 %.
@export var por_minuto: float = 12.0
## Terreno -> aprovechamiento (1 = pleno). Cada borde de la pieza aporta 1/6.
@export var afinidad: Dictionary = {}
## Recurso -> cantidad que cuesta construirla.
@export var costo: Dictionary = {}
@export var arte: Texture2D


## Nombre en el idioma actual. El campo `nombre` está en español y es la clave de traducción.
func nombre_visible() -> String:
	return tr(nombre)
