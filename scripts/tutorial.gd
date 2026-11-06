class_name Tutorial
extends RefCounted
## Mini tutorial de una partida nueva: una secuencia de pasos que solo avanza.
## Lógica pura: `juego.gd` le avisa de lo que hace el jugador y muestra el texto del paso.

enum Paso { BIENVENIDA, COLOCAR, GIRAR, CONFIRMAR, ELEGIR_PIEZA, CONSTRUIR, FINAL, TERMINADO }

## Pieza que se garantiza al empezar, para poder sugerir el aserradero.
const PIEZA_INICIAL: StringName = &"bosque"
const CONSTRUCCION_SUGERIDA: StringName = &"aserradero"

## Qué paso se alcanza (como mínimo) con cada cosa que hace el jugador.
## Así, si se adelanta, el tutorial no se queda atrás.
const SIGUIENTE_TRAS: Dictionary = {
	&"hueco_elegido": Paso.GIRAR,
	&"girado": Paso.CONFIRMAR,
	&"pieza_colocada": Paso.ELEGIR_PIEZA,
	&"pieza_seleccionada": Paso.CONSTRUIR,
	&"construido": Paso.FINAL,
}

const TEXTOS: Dictionary = {
	Paso.BIENVENIDA: "¡Bienvenido a Brote! Tu mundo crece pieza a pieza. Te sugiero empezar con un aserradero: produce madera, que necesitas para construir todo lo demás.",
	Paso.COLOCAR: "Para empezar, toca uno de los huecos libres junto a tu primera pieza. Ahí irá la pieza de bosque.",
	Paso.GIRAR: "Pulsa Girar (o la tecla R) para rotar la pieza. Cuando el contorno es verde, sus bordes encajan con los vecinos.",
	Paso.CONFIRMAR: "Pulsa Confirmar (o Enter) para colocarla. Encajar bien suena y brilla.",
	Paso.ELEGIR_PIEZA: "¡Muy bien! Ahora toca la pieza de bosque que acabas de colocar para abrir el panel de construcción.",
	Paso.CONSTRUIR: "Elige el Aserradero: rinde al 100% sobre bosque. Ya tienes madera para pagarlo.",
	Paso.FINAL: "¡Listo! Arriba a la derecha verás subir la madera. Junta piezas del mismo tipo para producir +5% por cada vecina. Lo demás, descúbrelo a tu ritmo.",
}

## Pasos que muestran el botón principal (los demás avanzan haciendo la acción).
const CON_BOTON: Array[int] = [Paso.BIENVENIDA, Paso.FINAL]

var paso: int = Paso.BIENVENIDA
var activo: bool = false


func iniciar() -> void:
	activo = true
	paso = Paso.BIENVENIDA


func saltar() -> void:
	activo = false
	paso = Paso.TERMINADO


func terminado() -> bool:
	return not activo


func texto() -> String:
	return tr(TEXTOS.get(paso, ""))


func tiene_boton() -> bool:
	return activo and CON_BOTON.has(paso)


func texto_boton() -> String:
	return tr("¡Entendido!") if paso == Paso.FINAL else tr("Empezar")


## El botón principal: pasa de la bienvenida a la acción, o cierra el tutorial.
func siguiente() -> void:
	if not activo:
		return
	if paso == Paso.BIENVENIDA:
		paso = Paso.COLOCAR
	elif paso == Paso.FINAL:
		saltar()


## Avisa de algo que ha hecho el jugador. Devuelve true si el paso cambió.
func evento(nombre: StringName) -> bool:
	if not activo or not SIGUIENTE_TRAS.has(nombre):
		return false
	# La bienvenida y el final se cierran con su botón, no con acciones.
	if paso == Paso.BIENVENIDA or paso == Paso.FINAL:
		return false
	var destino: int = SIGUIENTE_TRAS[nombre]
	if destino > paso:
		paso = destino
		return true
	return false


func a_diccionario() -> Dictionary:
	return {"activo": activo, "paso": paso}


func desde_diccionario(datos: Dictionary) -> void:
	activo = bool(datos.get("activo", false))
	paso = clampi(int(datos.get("paso", Paso.TERMINADO)), 0, Paso.TERMINADO)
	if paso == Paso.TERMINADO:
		activo = false
