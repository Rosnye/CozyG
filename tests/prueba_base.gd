extends RefCounted
## Base de las pruebas: cada archivo `prueba_*.gd` hereda de aquí y define
## métodos que empiezan por `prueba_`. Ver `ejecutar_pruebas.gd`.

var fallos: Array[String] = []


func afirmar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		fallos.append(mensaje)


func afirmar_igual(obtenido: Variant, esperado: Variant, mensaje: String) -> void:
	if obtenido != esperado:
		fallos.append("%s (obtenido %s, esperado %s)" % [mensaje, str(obtenido), str(esperado)])
