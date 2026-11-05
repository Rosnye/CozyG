extends SceneTree
## Mide el coste por fotograma del juego con un mundo grande, en modo headless.
## Sirve para comparar antes y después de optimizar (los números absolutos de un PC son
## mucho menores que los de un móvil; lo que importa es la proporción).
##
## Uso, desde la raíz del proyecto:
##   godot --headless --path . --script res://herramientas/medir_rendimiento.gd
##
## Usa su propio archivo de guardado para no tocar la partida real.

const RUTA: String = "user://medicion_rendimiento.json"
const RADIO_MUNDO: int = 22  # hexágonos desde el centro: unas 1.500 piezas
const FOTOGRAMAS: int = 300


func _init() -> void:
	root.set_meta(&"pantalla_vigilada", true)
	var juego: Node = load("res://scenes/juego.tscn").instantiate()
	juego.ruta_guardado = RUTA
	root.add_child(juego)
	await process_frame
	root.content_scale_factor = 1.0
	await _esperar(5)
	juego._al_saltar_tutorial()
	var coordenadas: Array[Vector2i] = _poblar(juego)
	await _esperar(10)
	print("Mundo: %d piezas, %d construcciones, %d criaturas" % [
		juego._tablero.cantidad(), juego._economia.construcciones.size(), juego._ecosistema.cantidad()
	])

	var logica: Dictionary = _medir_proceso(juego)
	var quieto: Dictionary = await _medir_fotogramas(juego, coordenadas, false)
	var animando: Dictionary = await _medir_fotogramas(juego, coordenadas, true)
	print("Lógica de _process:        medio %.3f ms  | peor %.3f ms" % [logica["medio"], logica["peor"]])
	print("Fotograma en reposo:       medio %.3f ms  | peor %.3f ms" % [quieto["medio"], quieto["peor"]])
	print("Fotograma con animaciones: medio %.3f ms  | peor %.3f ms" % [animando["medio"], animando["peor"]])
	DirAccess.remove_absolute(RUTA)
	quit()


func _esperar(fotogramas: int) -> void:
	for i in fotogramas:
		await process_frame


## Rellena un hexágono grande de piezas al azar y reparte construcciones.
func _poblar(juego: Node) -> Array[Vector2i]:
	var azar := RandomNumberGenerator.new()
	azar.seed = 1
	var piezas: Array[PiezaDatos] = []
	for archivo in DirAccess.get_files_at("res://data/piezas"):
		var nombre: String = archivo.trim_suffix(".remap")
		if nombre.ends_with(".tres"):
			piezas.append(load("res://data/piezas/" + nombre))
	var construcciones: Array[ConstruccionDatos] = []
	for archivo in DirAccess.get_files_at("res://data/construcciones"):
		var nombre: String = archivo.trim_suffix(".remap")
		if nombre.ends_with(".tres"):
			construcciones.append(load("res://data/construcciones/" + nombre))
	var tablero: Tablero = juego._tablero
	var coordenadas: Array[Vector2i] = []
	for q in range(-RADIO_MUNDO, RADIO_MUNDO + 1):
		for r in range(maxi(-RADIO_MUNDO, -q - RADIO_MUNDO), mini(RADIO_MUNDO, -q + RADIO_MUNDO) + 1):
			var coord := Vector2i(q, r)
			tablero.restaurar(coord, piezas[azar.randi_range(0, piezas.size() - 1)], azar.randi_range(0, 5))
			coordenadas.append(coord)
	var contador: int = 0
	for coord in coordenadas:
		contador += 1
		if contador % 10 == 0:
			juego._economia.construcciones[coord] = construcciones[contador % construcciones.size()]
	juego._conteo = tablero.conteo_bordes()
	juego._ecosistema.actualizar(tablero, juego._criaturas)
	juego._vista.queue_redraw()
	return coordenadas


## Tiempo de la lógica del juego por fotograma, sin dibujar.
func _medir_proceso(juego: Node) -> Dictionary:
	var total: int = 0
	var peor: int = 0
	for i in FOTOGRAMAS:
		var inicio: int = Time.get_ticks_usec()
		juego._process(0.016)
		var duracion: int = Time.get_ticks_usec() - inicio
		total += duracion
		peor = maxi(peor, duracion)
	return {"medio": total / float(FOTOGRAMAS) / 1000.0, "peor": peor / 1000.0}


## Tiempo de un fotograma completo (lógica + dibujo). Con `animar`, coloca animaciones cada 20.
func _medir_fotogramas(juego: Node, coordenadas: Array[Vector2i], animar: bool) -> Dictionary:
	var azar := RandomNumberGenerator.new()
	azar.seed = 7
	var total: int = 0
	var peor: int = 0
	for i in FOTOGRAMAS:
		if animar and i % 20 == 0:
			juego._vista.animar_colocacion(coordenadas[azar.randi_range(0, coordenadas.size() - 1)], true)
		var inicio: int = Time.get_ticks_usec()
		await process_frame
		var duracion: int = Time.get_ticks_usec() - inicio
		total += duracion
		peor = maxi(peor, duracion)
	return {"medio": total / float(FOTOGRAMAS) / 1000.0, "peor": peor / 1000.0}
