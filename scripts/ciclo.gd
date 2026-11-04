class_name Ciclo
extends RefCounted
## Ciclo día/noche lento. La fase va de 0 a 1 y vuelve a empezar:
## 0 amanecer, 0.25 mediodía, 0.5 atardecer, 0.75 medianoche.

## Segundos que dura un día completo.
var duracion: float = 300.0
var tiempo: float = 0.0


func _init(duracion_dia: float = 300.0, fase_inicial: float = 0.1) -> void:
	duracion = maxf(duracion_dia, 1.0)
	fijar_fase(fase_inicial)


func avanzar(delta: float) -> void:
	tiempo = fposmod(tiempo + delta, duracion)


func fase() -> float:
	return tiempo / duracion


func fijar_fase(valor: float) -> void:
	tiempo = fposmod(valor, 1.0) * duracion


## 1 a pleno día, 0 en plena noche.
func luz() -> float:
	return 0.5 + 0.5 * sin(TAU * fase())


func es_noche() -> bool:
	return luz() < 0.3
