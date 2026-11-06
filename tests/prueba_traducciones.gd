extends "res://tests/prueba_base.gd"
## Comprueba que cada texto del juego tiene traducción y que ésta es coherente.
## Los textos se buscan igual que lo hace `herramientas/textos.py`.

const RUTA_EN: String = "res://data/idiomas/en.po"
const CADENA: String = "((?:[^\"\\\\]|\\\\.)*)"

var _en: Translation


func _catalogo() -> Translation:
	if _en == null:
		_en = load(RUTA_EN) as Translation
	return _en


## Quita los escapes de GDScript (\n, \", \\) para comparar con lo que lee el catálogo.
func _desescapar(texto: String) -> String:
	return texto.replace("\\n", "\n").replace("\\\"", "\"").replace("\\\\", "\\")


func _archivos(carpeta: String, extension: String) -> Array[String]:
	var resultado: Array[String] = []
	for archivo in DirAccess.get_files_at(carpeta):
		if archivo.ends_with(extension):
			resultado.append(carpeta.path_join(archivo))
	for sub in DirAccess.get_directories_at(carpeta):
		resultado.append_array(_archivos(carpeta.path_join(sub), extension))
	return resultado


func _extraer(ruta: String, expresion: String) -> Array[String]:
	var regex := RegEx.new()
	regex.compile(expresion)
	var contenido: String = FileAccess.get_file_as_string(ruta)
	var resultado: Array[String] = []
	for coincidencia in regex.search_all(contenido):
		resultado.append(_desescapar(coincidencia.get_string(1)))
	return resultado


## Todos los textos que el juego muestra en español y que deben traducirse.
func _textos_del_juego() -> Array[String]:
	var textos: Array[String] = []
	for ruta in _archivos("res://scenes", ".tscn"):
		textos.append_array(_extraer(ruta, "(?m)^(?:text|title|dialog_text|ok_button_text|cancel_button_text|tooltip_text|placeholder_text) = \"" + CADENA + "\"$"))
	for ruta in _archivos("res://scripts", ".gd"):
		textos.append_array(_extraer(ruta, "\\btr\\(\"" + CADENA + "\"\\)"))
	for ruta in _archivos("res://data", ".tres"):
		textos.append_array(_extraer(ruta, "(?m)^nombre = \"" + CADENA + "\"$"))
	textos.append_array(_extraer("res://data/terrenos.tres", "&\"(\\w+)\": Color"))
	for texto in Tutorial.TEXTOS.values():
		textos.append(texto)
	var utiles: Array[String] = []
	var letras := RegEx.new()
	letras.compile("[A-Za-zÁÉÍÓÚÜáéíóúüñÑ]")
	for texto in textos:
		if letras.search(texto) != null and texto != "II" and not utiles.has(texto):
			utiles.append(texto)
	return utiles


func prueba_el_catalogo_ingles_existe() -> void:
	var catalogo := _catalogo()
	afirmar(catalogo != null, "se carga %s" % RUTA_EN)
	if catalogo != null:
		afirmar_igual(catalogo.locale, "en", "el catálogo es de inglés")


func prueba_todos_los_textos_tienen_traduccion_al_ingles() -> void:
	var catalogo := _catalogo()
	if catalogo == null:
		afirmar(false, "no se pudo cargar el catálogo")
		return
	var textos := _textos_del_juego()
	afirmar(textos.size() > 50, "se encontraron los textos del juego (%d)" % textos.size())
	for texto in textos:
		var traduccion: String = String(catalogo.get_message(texto))
		afirmar(traduccion != "", "sin traducción al inglés: \"%s\"" % texto)


func prueba_las_traducciones_conservan_los_marcadores_de_formato() -> void:
	var catalogo := _catalogo()
	if catalogo == null:
		return
	var marcadores := RegEx.new()
	marcadores.compile("%[sd%]")
	for texto in _textos_del_juego():
		var traduccion: String = String(catalogo.get_message(texto))
		if traduccion == "":
			continue
		var original: Array[String] = []
		for m in marcadores.search_all(texto):
			original.append(m.get_string())
		var traducido: Array[String] = []
		for m in marcadores.search_all(traduccion):
			traducido.append(m.get_string())
		original.sort()
		traducido.sort()
		afirmar_igual(traducido, original, "marcadores de \"%s\"" % texto)


func prueba_el_catalogo_no_tiene_textos_sin_uso() -> void:
	var catalogo := _catalogo()
	if catalogo == null:
		return
	var usados := _textos_del_juego()
	for clave in catalogo.get_message_list():
		afirmar(usados.has(String(clave)), "texto del catálogo que ya no se usa: \"%s\"" % clave)


func prueba_el_juego_se_muestra_en_ingles_y_vuelve_al_espanol() -> void:
	var catalogo := _catalogo()
	if catalogo == null:
		return
	if TranslationServer.get_translation_object("en") == null:
		TranslationServer.add_translation(catalogo)
	var prado := PiezaDatos.new()
	prado.nombre = "Prado"
	TranslationServer.set_locale("en")
	afirmar_igual(prado.nombre_visible(), "Meadow", "nombre de pieza en inglés")
	var tutorial := Tutorial.new()
	tutorial.iniciar()
	afirmar(tutorial.texto().begins_with("Welcome to Brote"), "texto del tutorial en inglés")
	afirmar_igual(tutorial.texto_boton(), "Start", "botón del tutorial en inglés")
	TranslationServer.set_locale("es")
	afirmar_igual(prado.nombre_visible(), "Prado", "vuelve al español")
	afirmar(tutorial.texto().begins_with("¡Bienvenido a Brote!"), "tutorial otra vez en español")
