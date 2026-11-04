class_name Clima
extends RefCounted
## Clima ligero: periodos despejados que alternan con lluvia suave.

enum Estado { DESPEJADO, LLUVIA }

## Duración (mín, máx) en segundos de cada periodo.
const DURACION_DESPEJADO: Vector2 = Vector2(90.0, 240.0)
const DURACION_LLUVIA: Vector2 = Vector2(40.0, 100.0)
## Lo que tarda la lluvia en llegar o irse del todo.
const SEGUNDOS_TRANSICION: float = 8.0

var estado: Estado = Estado.DESPEJADO
## 0 sin lluvia, 1 lluvia completa; cambia poco a poco.
var intensidad_lluvia: float = 0.0

var _restante: float = 0.0
var _azar := RandomNumberGenerator.new()


func _init(semilla: int = -1) -> void:
	if semilla >= 0:
		_azar.seed = semilla
	else:
		_azar.randomize()
	_restante = _duracion_de(Estado.DESPEJADO)


func avanzar(delta: float) -> void:
	_restante -= delta
	if _restante <= 0.0:
		estado = Estado.LLUVIA if estado == Estado.DESPEJADO else Estado.DESPEJADO
		_restante = _duracion_de(estado)
	var objetivo: float = 1.0 if estado == Estado.LLUVIA else 0.0
	intensidad_lluvia = move_toward(intensidad_lluvia, objetivo, delta / SEGUNDOS_TRANSICION)


func _duracion_de(para: Estado) -> float:
	var rango: Vector2 = DURACION_LLUVIA if para == Estado.LLUVIA else DURACION_DESPEJADO
	return _azar.randf_range(rango.x, rango.y)
