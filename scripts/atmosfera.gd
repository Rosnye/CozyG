class_name Atmosfera
extends Node
## Pone luz, lluvia y sonido al mundo según la hora del día, el clima y lo construido.
## Solo aplica: las decisiones salen de `Ciclo`, `Clima` y `Ambiente`.

## Volumen (dB) de cada capa cuando su nivel es 1.
const GANANCIA_DB: Dictionary = {
	&"base": -12.0, &"melodia": -13.0, &"agua": -15.0,
	&"aves": -17.0, &"grillos": -19.0, &"lluvia": -14.0,
}
const SILENCIO_DB: float = -80.0
## Rapidez con que las capas suben y bajan de volumen.
const SUAVIZADO: float = 1.2

## Color por fase del día (0 = amanecer ... 0.75 = medianoche).
@export var gradiente_dia: Gradient
## Tinte que añade la lluvia al color del día.
@export var tinte_lluvia: Color = Color(0.82, 0.88, 0.98)
@export var modulacion_mundo: CanvasModulate
@export var modulacion_fondo: CanvasModulate
@export var lluvia: LluviaVista

var _capas: Dictionary = {}


func _ready() -> void:
	Preferencias.iniciar()
	for capa: StringName in Ambiente.CAPAS:
		var reproductor := get_node_or_null("Capas/" + String(capa).capitalize()) as AudioStreamPlayer
		if reproductor != null:
			reproductor.volume_db = SILENCIO_DB
			reproductor.bus = Preferencias.BUS_MUSICA
			# La música sigue sonando con el juego en pausa.
			reproductor.process_mode = Node.PROCESS_MODE_ALWAYS
			_capas[capa] = reproductor


func actualizar(delta: float, ciclo: Ciclo, clima: Clima, conteo: Dictionary, piezas: int) -> void:
	_aplicar_luz(ciclo, clima)
	_aplicar_audio(delta, ciclo.luz(), clima.intensidad_lluvia, conteo, piezas)
	if lluvia != null:
		lluvia.intensidad = clima.intensidad_lluvia


func _aplicar_luz(ciclo: Ciclo, clima: Clima) -> void:
	var color: Color = Color.WHITE
	if gradiente_dia != null:
		color = gradiente_dia.sample(ciclo.fase())
	color = color * Color.WHITE.lerp(tinte_lluvia, clima.intensidad_lluvia)
	color.a = 1.0
	if modulacion_mundo != null:
		modulacion_mundo.color = color
	if modulacion_fondo != null:
		modulacion_fondo.color = color


func _aplicar_audio(delta: float, luz: float, lluvia_nivel: float, conteo: Dictionary, piezas: int) -> void:
	var niveles: Dictionary = Ambiente.volumenes(luz, lluvia_nivel, conteo, piezas)
	var paso: float = 1.0 - exp(-delta * SUAVIZADO)
	for capa: StringName in _capas:
		var reproductor: AudioStreamPlayer = _capas[capa]
		var nivel: float = niveles.get(capa, 0.0)
		var objetivo: float = SILENCIO_DB
		if nivel > 0.001:
			objetivo = maxf(GANANCIA_DB[capa] + linear_to_db(nivel), SILENCIO_DB)
		reproductor.volume_db = lerpf(reproductor.volume_db, objetivo, paso)
