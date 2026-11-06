class_name Accesibilidad
extends RefCounted
## Ayudas de accesibilidad: tamaño del texto y ayuda para daltonismo.
## Solo cálculos y cambios sobre el tema; quién dibuja decide cómo usarlos.

## Tamaños de texto que ofrece Ajustes (Normal, Grande, Muy grande).
const ESCALAS_TEXTO: Array[float] = [1.0, 1.2, 1.4]
## Con la ayuda para daltonismo, el fantasma usa azul y naranja: se distinguen con
## cualquier tipo común de daltonismo (el verde y el naranja, no).
const COLOR_ENCAJE_DALTONISMO: Color = Color(0.25, 0.55, 1.0, 1)
const COLOR_DESAJUSTE_DALTONISMO: Color = Color(1.0, 0.55, 0.05, 1)

const _META_BASE: StringName = &"tamanos_base"
const _CLAVE_DEFECTO: String = "__defecto"


## La escala de la lista más cercana a `valor` (los ajustes guardados podrían traer otra).
static func escala_valida(valor: float) -> float:
	var mejor: float = ESCALAS_TEXTO[0]
	for escala in ESCALAS_TEXTO:
		if absf(escala - valor) < absf(mejor - valor):
			mejor = escala
	return mejor


## Multiplica todos los tamaños de letra del tema por `factor`, siempre a partir de los
## originales (que se guardan en el propio tema la primera vez), así que repetirlo no acumula.
static func escalar_tema(tema: Theme, factor: float) -> void:
	if tema == null:
		return
	var base: Dictionary = _tamanos_base(tema)
	for clave: String in base:
		var tamano: int = maxi(roundi(base[clave] * factor), 1)
		if clave == _CLAVE_DEFECTO:
			tema.default_font_size = tamano
		else:
			var partes: PackedStringArray = clave.split("|")
			tema.set_font_size(partes[1], partes[0], tamano)


static func _tamanos_base(tema: Theme) -> Dictionary:
	if tema.has_meta(_META_BASE):
		return tema.get_meta(_META_BASE)
	var base: Dictionary = {_CLAVE_DEFECTO: tema.default_font_size}
	for tipo in tema.get_font_size_type_list():
		for nombre in tema.get_font_size_list(tipo):
			base["%s|%s" % [tipo, nombre]] = tema.get_font_size(nombre, tipo)
	tema.set_meta(_META_BASE, base)
	return base


## Agrupa los 6 bordes (en orden de dirección) en tramos seguidos del mismo terreno, para
## dibujar una marca por tramo y no seis. Cada tramo: { "terreno", "inicio", "largo" }.
## La lista es circular: el borde 5 sigue al 0. Si los 6 son iguales, hay un solo tramo.
static func tramos(bordes: Array[StringName]) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	var n: int = bordes.size()
	if n == 0:
		return resultado
	var inicio: int = -1
	for i in n:
		if bordes[i] != bordes[(i - 1 + n) % n]:
			inicio = i
			break
	if inicio == -1:
		resultado.append({"terreno": bordes[0], "inicio": 0, "largo": n})
		return resultado
	var actual: Dictionary = {}
	for paso in n:
		var i: int = (inicio + paso) % n
		if actual.is_empty() or bordes[i] != actual["terreno"]:
			actual = {"terreno": bordes[i], "inicio": i, "largo": 0}
			resultado.append(actual)
		actual["largo"] += 1
	return resultado
