extends "res://tests/prueba_base.gd"


func prueba_volumen_a_decibelios() -> void:
	afirmar_igual(Preferencias.volumen_a_db(0.0), -80.0, "silencio total")
	afirmar_igual(Preferencias.volumen_a_db(0.0005), -80.0, "casi cero también es silencio")
	afirmar(absf(Preferencias.volumen_a_db(1.0)) < 0.0001, "volumen máximo = 0 dB")
	afirmar(absf(Preferencias.volumen_a_db(0.5) - (-6.0206)) < 0.01, "la mitad = unos -6 dB")


func prueba_los_volumenes_se_limitan_a_0_1() -> void:
	var musica: float = Preferencias.volumen_musica
	var efectos: float = Preferencias.volumen_efectos
	Preferencias.fijar_musica(3.0)
	afirmar_igual(Preferencias.volumen_musica, 1.0, "máximo 1")
	Preferencias.fijar_efectos(-2.0)
	afirmar_igual(Preferencias.volumen_efectos, 0.0, "mínimo 0")
	Preferencias.fijar_musica(musica)
	Preferencias.fijar_efectos(efectos)
