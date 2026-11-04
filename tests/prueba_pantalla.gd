extends "res://tests/prueba_base.gd"


func _casi(a: float, b: float, margen: float = 0.01) -> bool:
	return absf(a - b) <= margen


func prueba_escritorio_no_cambia() -> void:
	afirmar_igual(Pantalla.factor_para(Vector2(1280, 720), 1.0, false), 1.0, "sin tacto: 1")
	afirmar_igual(Pantalla.factor_para(Vector2(1920, 1080), 1.0, false), 1.0, "ventana grande sin tacto: 1")
	afirmar_igual(Pantalla.factor_para(Vector2(1280, 720), 1.25, false), 1.0, "con escala del sistema pero sin tacto: 1")


func prueba_portatil_tactil_con_ventana_grande_no_cambia() -> void:
	afirmar_igual(Pantalla.factor_para(Vector2(1920, 1080), 1.0, true), 1.0, "tacto pero ventana grande: 1")
	afirmar_igual(Pantalla.factor_para(Vector2(1536, 2048), 2.0, true), 1.0, "tableta: 1")


func prueba_movil_horizontal() -> void:
	var tam := Vector2(2532, 1170)  # 844×390 px CSS a 3 px por px CSS
	var factor: float = Pantalla.factor_para(tam, 3.0, true)
	afirmar(factor > 1.0, "horizontal amplía la interfaz (factor %.2f)" % factor)
	# La interfaz acaba midiendo UNIDADES_POR_PIXEL_CSS unidades por píxel CSS.
	var escala_base: float = minf(tam.x / 1280.0, tam.y / 720.0)
	var logico: Vector2 = tam / (factor * escala_base)
	afirmar(_casi(logico.x, 844.0 * Pantalla.UNIDADES_POR_PIXEL_CSS, 1.0), "ancho lógico ≈ ancho CSS × constante (%.0f)" % logico.x)
	afirmar(_casi(logico.y, 390.0 * Pantalla.UNIDADES_POR_PIXEL_CSS, 1.0), "alto lógico ≈ alto CSS × constante (%.0f)" % logico.y)


func prueba_movil_vertical() -> void:
	var tam := Vector2(1170, 2532)  # 390×844 px CSS
	var factor: float = Pantalla.factor_para(tam, 3.0, true)
	var horizontal: float = Pantalla.factor_para(Vector2(2532, 1170), 3.0, true)
	afirmar(factor > horizontal, "vertical amplía más que horizontal (%.2f > %.2f)" % [factor, horizontal])
	var escala_base: float = minf(tam.x / 1280.0, tam.y / 720.0)
	var logico: Vector2 = tam / (factor * escala_base)
	afirmar(_casi(logico.x, 390.0 * Pantalla.UNIDADES_POR_PIXEL_CSS, 1.0), "ancho lógico ≈ 390 × constante (%.0f)" % logico.x)


func prueba_un_boton_mide_lo_mismo_en_cualquier_movil() -> void:
	# Un botón de 72 unidades debe medir lo mismo en píxeles CSS en vertical y en horizontal.
	var medidas: Array[float] = []
	for caso in [[Vector2(2532, 1170), 3.0], [Vector2(1170, 2532), 3.0], [Vector2(750, 1334), 2.0], [Vector2(1334, 750), 2.0]]:
		var tam: Vector2 = caso[0]
		var dpr: float = caso[1]
		var factor: float = Pantalla.factor_para(tam, dpr, true)
		var escala: float = factor * minf(tam.x / 1280.0, tam.y / 720.0)
		medidas.append(72.0 * escala / dpr)
	for medida in medidas:
		afirmar(_casi(medida, 72.0 / Pantalla.UNIDADES_POR_PIXEL_CSS, 0.5), "72 unidades ≈ 48 px CSS (%.1f)" % medida)
		afirmar(medida >= 47.5, "un botón de 72 unidades mide al menos 48 px CSS (%.1f)" % medida)


func prueba_entradas_raras() -> void:
	afirmar_igual(Pantalla.factor_para(Vector2(1000, 500), 0.0, true), 1.0, "escala 0 no rompe")
	afirmar_igual(Pantalla.factor_para(Vector2(0, 0), 2.0, true), 1.0, "ventana vacía no rompe")
	var enorme: float = Pantalla.factor_para(Vector2(100, 60), 1.0, true)
	afirmar(enorme <= Pantalla.FACTOR_MAXIMO, "el factor nunca pasa del máximo (%.2f)" % enorme)
