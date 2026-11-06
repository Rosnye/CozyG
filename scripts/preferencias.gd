class_name Preferencias
extends RefCounted
## Preferencias del jugador (por ahora, volúmenes) y los buses de audio que las aplican.
## `iniciar()` es seguro llamarlo varias veces desde cualquier escena.

const RUTA: String = "user://ajustes.cfg"
const BUS_MUSICA: StringName = &"Musica"
const BUS_EFECTOS: StringName = &"Efectos"

static var volumen_musica: float = 0.8
static var volumen_efectos: float = 0.8
## Si las partidas nuevas empiezan con el mini tutorial.
static var mostrar_tutorial: bool = true
## "auto" (sigue al sistema), "es" o "en".
static var idioma: String = Idioma.AUTOMATICO

static var _iniciado: bool = false


static func iniciar() -> void:
	if _iniciado:
		return
	_iniciado = true
	_asegurar_bus(BUS_MUSICA)
	_asegurar_bus(BUS_EFECTOS)
	cargar()
	aplicar()
	Idioma.aplicar(idioma)


static func fijar_musica(valor: float) -> void:
	volumen_musica = clampf(valor, 0.0, 1.0)
	aplicar()


static func fijar_efectos(valor: float) -> void:
	volumen_efectos = clampf(valor, 0.0, 1.0)
	aplicar()


## Cambia el idioma ahora y lo recuerda. Los textos con traducción se actualizan solos.
static func fijar_idioma(preferencia: String) -> void:
	idioma = preferencia
	Idioma.aplicar(idioma)


## Volumen lineal 0..1 a decibelios (0 es silencio total).
static func volumen_a_db(valor: float) -> float:
	if valor <= 0.001:
		return -80.0
	return linear_to_db(valor)


static func aplicar() -> void:
	_poner_volumen(BUS_MUSICA, volumen_musica)
	_poner_volumen(BUS_EFECTOS, volumen_efectos)


static func guardar() -> void:
	var archivo := ConfigFile.new()
	archivo.set_value("audio", "musica", volumen_musica)
	archivo.set_value("audio", "efectos", volumen_efectos)
	archivo.set_value("juego", "mostrar_tutorial", mostrar_tutorial)
	archivo.set_value("juego", "idioma", idioma)
	archivo.save(RUTA)


static func cargar() -> void:
	var archivo := ConfigFile.new()
	if archivo.load(RUTA) != OK:
		return
	volumen_musica = clampf(float(archivo.get_value("audio", "musica", volumen_musica)), 0.0, 1.0)
	volumen_efectos = clampf(float(archivo.get_value("audio", "efectos", volumen_efectos)), 0.0, 1.0)
	mostrar_tutorial = bool(archivo.get_value("juego", "mostrar_tutorial", mostrar_tutorial))
	idioma = str(archivo.get_value("juego", "idioma", idioma))


static func _asegurar_bus(nombre: StringName) -> void:
	if AudioServer.get_bus_index(nombre) != -1:
		return
	AudioServer.add_bus()
	var indice: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(indice, nombre)
	AudioServer.set_bus_send(indice, &"Master")


static func _poner_volumen(bus: StringName, valor: float) -> void:
	var indice: int = AudioServer.get_bus_index(bus)
	if indice != -1:
		AudioServer.set_bus_volume_db(indice, volumen_a_db(valor))
