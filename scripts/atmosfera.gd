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
## Cambios de volumen menores que esto (dB) no se aplican: en la web, cada cambio es una
## llamada al audio del navegador, y por debajo de este valor no se oye la diferencia.
const CAMBIO_MINIMO_DB: float = 0.05
## Cada cuántos segundos se recalculan la luz y los niveles de audio.
const PERIODO_CALCULO: float = 0.1

## Color por fase del día (0 = amanecer ... 0.75 = medianoche).
@export var gradiente_dia: Gradient
## Tinte que añade la lluvia al color del día.
@export var tinte_lluvia: Color = Color(0.82, 0.88, 0.98)
@export var modulacion_mundo: CanvasModulate
@export var modulacion_fondo: CanvasModulate
@export var lluvia: LluviaVista

var _capas: Dictionary = {}
var _niveles: Dictionary = {}
## Volumen suavizado (dB) de cada capa; al reproductor solo se le pasa si cambia lo bastante.
var _volumenes: Dictionary = {}
var _acumulado: float = 1.0  # fuerza el primer cálculo


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
			_volumenes[capa] = SILENCIO_DB


func actualizar(delta: float, ciclo: Ciclo, clima: Clima, conteo: Dictionary, piezas: int) -> void:
	# La luz y los niveles de audio cambian despacio: se recalculan 10 veces por segundo.
	_acumulado += delta
	if _acumulado >= PERIODO_CALCULO:
		_acumulado = 0.0
		_aplicar_luz(ciclo, clima)
		_niveles = Ambiente.volumenes(ciclo.luz(), clima.intensidad_lluvia, conteo, piezas)
		if lluvia != null:
			lluvia.intensidad = clima.intensidad_lluvia
	_suavizar_audio(delta)


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


## Acerca poco a poco el volumen de cada capa a su objetivo. Las capas que no se oyen se pausan
## para que el motor no gaste CPU (ni batería) mezclándolas.
func _suavizar_audio(delta: float) -> void:
	var paso: float = 1.0 - exp(-delta * SUAVIZADO)
	for capa: StringName in _capas:
		var reproductor: AudioStreamPlayer = _capas[capa]
		var nivel: float = _niveles.get(capa, 0.0)
		var objetivo: float = SILENCIO_DB
		if nivel > 0.001:
			objetivo = maxf(GANANCIA_DB[capa] + linear_to_db(nivel), SILENCIO_DB)
		var volumen: float = lerpf(_volumenes[capa], objetivo, paso)
		_volumenes[capa] = volumen
		if absf(volumen - reproductor.volume_db) >= CAMBIO_MINIMO_DB:
			reproductor.volume_db = volumen
		var pausar: bool = objetivo <= SILENCIO_DB and volumen <= SILENCIO_DB + 2.0
		# Solo si cambia: en la web, cada `stream_paused = false` reinicia el sonido y copia
		# todo su búfer. Hacerlo en cada fotograma generaba cientos de MB de basura por segundo
		# (tirones y, al rato, el navegador cerraba la pestaña por falta de memoria).
		if reproductor.stream_paused != pausar:
			reproductor.stream_paused = pausar
