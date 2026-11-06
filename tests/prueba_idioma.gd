extends "res://tests/prueba_base.gd"


func prueba_la_preferencia_manda_sobre_el_sistema() -> void:
	afirmar_igual(Idioma.elegir("es", "en_US"), "es", "español forzado")
	afirmar_igual(Idioma.elegir("en", "es_ES"), "en", "inglés forzado")


func prueba_automatico_sigue_al_sistema() -> void:
	afirmar_igual(Idioma.elegir("auto", "es_MX"), "es", "es_MX -> es")
	afirmar_igual(Idioma.elegir("auto", "es"), "es", "es -> es")
	afirmar_igual(Idioma.elegir("auto", "en_US"), "en", "en_US -> en")
	afirmar_igual(Idioma.elegir("auto", "en-GB"), "en", "con guion: en-GB -> en")
	afirmar_igual(Idioma.elegir("auto", "ES_es"), "es", "mayúsculas: ES_es -> es")


func prueba_idiomas_no_soportados_usan_ingles() -> void:
	afirmar_igual(Idioma.elegir("auto", "fr_FR"), "en", "francés -> inglés")
	afirmar_igual(Idioma.elegir("auto", "pt-BR"), "en", "portugués -> inglés")
	afirmar_igual(Idioma.elegir("auto", ""), "en", "sin idioma -> inglés")


func prueba_preferencia_desconocida_cuenta_como_automatico() -> void:
	afirmar_igual(Idioma.elegir("klingon", "es_AR"), "es", "preferencia rara + sistema español")
	afirmar_igual(Idioma.elegir("", "fr_FR"), "en", "preferencia vacía + sistema no soportado")


func prueba_el_resultado_siempre_es_soportado() -> void:
	for pref in ["auto", "es", "en", "xx", ""]:
		for sistema in ["es_ES", "en_US", "de_DE", "ja", ""]:
			afirmar(Idioma.SOPORTADOS.has(Idioma.elegir(pref, sistema)), "(%s, %s) da un idioma soportado" % [pref, sistema])
