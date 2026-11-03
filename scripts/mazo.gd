class_name Mazo
extends RefCounted
## Mazo infinito: cada robo devuelve una pieza al azar según su peso.

var _piezas: Array[PiezaDatos] = []
var _peso_total: int = 0
var _azar := RandomNumberGenerator.new()


## `semilla` fija el azar (útil en pruebas); con -1 es aleatorio.
func _init(piezas: Array[PiezaDatos], semilla: int = -1) -> void:
	for pieza in piezas:
		if pieza != null and pieza.peso > 0:
			_piezas.append(pieza)
			_peso_total += pieza.peso
	if semilla >= 0:
		_azar.seed = semilla
	else:
		_azar.randomize()


func robar() -> PiezaDatos:
	if _piezas.is_empty():
		return null
	var punto: int = _azar.randi_range(0, _peso_total - 1)
	for pieza in _piezas:
		if punto < pieza.peso:
			return pieza
		punto -= pieza.peso
	return _piezas[-1]
