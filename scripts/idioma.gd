class_name Idioma
extends RefCounted
## Elección del idioma del juego (español e inglés).
## El español es el idioma de origen: los textos del juego están escritos en español y el
## catálogo `data/idiomas/en.po` los traduce. Para añadir un idioma: copiar `en.po` con su
## código y añadirlo a `SOPORTADOS` y a `data/idiomas/` (ver `herramientas/textos.py`).

const AUTOMATICO: String = "auto"
const SOPORTADOS: Array[String] = ["es", "en"]
## Si el idioma del sistema no está soportado se usa este (el más extendido).
const POR_DEFECTO: String = "en"


## Idioma a usar según la preferencia del jugador ("auto", "es" o "en") y el idioma del
## sistema (por ejemplo "es_MX", "en-US" o ""). Una preferencia desconocida cuenta como "auto".
static func elegir(preferencia: String, idioma_sistema: String) -> String:
	if SOPORTADOS.has(preferencia):
		return preferencia
	var base: String = idioma_sistema.replace("-", "_").split("_")[0].to_lower()
	if SOPORTADOS.has(base):
		return base
	return POR_DEFECTO


## Pone el idioma en el juego. Los textos con traducción se actualizan solos.
static func aplicar(preferencia: String) -> void:
	TranslationServer.set_locale(elegir(preferencia, OS.get_locale()))
