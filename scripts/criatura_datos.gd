class_name CriaturaDatos
extends Resource
## Datos de una criatura. El arte es un dato: mientras `arte` esté vacío se dibuja un círculo de color.

@export var id: StringName = &""
@export var nombre: String = ""
@export var color: Color = Color.WHITE
## Terreno donde vive y se mueve (necesita piezas con al menos 2 bordes de este terreno).
@export var habitat: StringName = &""
## Terreno -> bordes mínimos de ese terreno en todo el mundo. Deben cumplirse todos.
## Cada vez que se duplican los mínimos, puede llegar otro individuo (hasta `maximo`).
@export var requisitos: Dictionary = {}
@export var maximo: int = 3
## Solo se deja ver de noche (p. ej. luciérnagas).
@export var solo_de_noche: bool = false
## Radio aproximado en unidades de mundo.
@export var tamano: float = 14.0
@export var arte: Texture2D


## Nombre en el idioma actual. El campo `nombre` está en español y es la clave de traducción.
func nombre_visible() -> String:
	return tr(nombre)
