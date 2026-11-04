class_name PiezaDatos
extends Resource
## Datos de un tipo de pieza (bosque, río, prado...).
## El arte vive aquí como dato: mientras `arte` esté vacío se dibuja con colores planos.

@export var id: StringName = &""
@export var nombre: String = ""
## Color de respaldo (miniaturas, terrenos sin color definido).
@export var color: Color = Color.WHITE
## Probabilidad relativa de salir en el mazo.
@export var peso: int = 1
## Terreno de cada uno de los 6 bordes, en el orden de `Hex.DIRECCIONES`
## (este, sureste, suroeste, oeste, noroeste, noreste). Vacío = todos del terreno `id`.
@export var bordes: Array[StringName] = []
@export var arte: Texture2D


## Terreno del borde que mira hacia `direccion` cuando la pieza está girada `giro` pasos
## (cada paso gira 60° en el sentido de las agujas del reloj).
func borde(direccion: int, giro: int = 0) -> StringName:
	if bordes.size() != 6:
		return id
	return bordes[posmod(direccion - giro, 6)]
