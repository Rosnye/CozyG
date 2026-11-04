class_name Ambiente
extends RefCounted
## Decide cuánto suena cada capa de música y sonido ambiente según el mundo.
## Devuelve volúmenes lineales de 0 a 1; el nodo de audio los convierte y los suaviza.

const CAPAS: Array[StringName] = [&"base", &"melodia", &"agua", &"aves", &"grillos", &"lluvia"]


## `luz` 0..1 (día/noche), `lluvia` 0..1, `conteo` bordes por terreno, `piezas` colocadas.
static func volumenes(luz: float, lluvia: float, conteo: Dictionary, piezas: int) -> Dictionary:
	var total: float = 0.0
	for terreno: StringName in conteo:
		total += float(conteo[terreno])
	var fr_agua: float = 0.0
	var fr_bosque: float = 0.0
	var fr_prado: float = 0.0
	if total > 0.0:
		fr_agua = float(conteo.get(&"agua", 0)) / total
		fr_bosque = float(conteo.get(&"bosque", 0)) / total
		fr_prado = float(conteo.get(&"prado", 0)) / total
	var dia: float = smoothstep(0.4, 0.8, luz)
	var noche: float = 1.0 - smoothstep(0.15, 0.5, luz)
	return {
		&"base": 1.0,
		&"melodia": clampf(float(piezas) / 25.0, 0.0, 1.0) * (0.4 + 0.6 * luz) * (1.0 - 0.5 * lluvia),
		&"agua": clampf(fr_agua * 3.0, 0.0, 1.0) * (1.0 - 0.3 * lluvia),
		&"aves": clampf(fr_bosque * 2.5 + fr_prado, 0.0, 1.0) * dia * (1.0 - lluvia),
		&"grillos": clampf((fr_prado + fr_bosque) * 2.0, 0.0, 1.0) * noche * (1.0 - 0.8 * lluvia),
		&"lluvia": lluvia,
	}
