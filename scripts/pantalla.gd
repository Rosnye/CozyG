class_name Pantalla
extends RefCounted
## Escala de la interfaz según el dispositivo.
## El juego se dibuja sobre una base de 1280×720; en un móvil esa base se encoge hasta
## caber y los botones quedan diminutos. En pantallas táctiles pequeñas se amplía la
## interfaz (`content_scale_factor`) para que sea cómoda con el dedo.

## Igual que `window/size/viewport_*` en project.godot.
const BASE: Vector2 = Vector2(1280.0, 720.0)
## Unidades del juego por píxel CSS en un móvil: más alto = interfaz más pequeña.
## Con 1,5, un botón de 72 unidades mide 48 px CSS (el mínimo recomendado para el dedo).
const UNIDADES_POR_PIXEL_CSS: float = 1.5
## Una ventana táctil con el lado corto menor que esto (en píxeles CSS) se trata como móvil.
const LADO_CORTO_MOVIL: float = 700.0
const FACTOR_MAXIMO: float = 4.0
const _META: StringName = &"pantalla_vigilada"


## Factor de escala del contenido para una ventana de `tamano_ventana` píxeles, con
## `escala_pantalla` píxeles por píxel CSS. En escritorio (sin tacto) o con ventanas
## grandes vale 1, es decir, no cambia nada.
static func factor_para(tamano_ventana: Vector2, escala_pantalla: float, es_tactil: bool) -> float:
	if not es_tactil or escala_pantalla <= 0.0:
		return 1.0
	var css: Vector2 = tamano_ventana / escala_pantalla
	if minf(css.x, css.y) >= LADO_CORTO_MOVIL:
		return 1.0
	var escala_base: float = minf(tamano_ventana.x / BASE.x, tamano_ventana.y / BASE.y)
	if escala_base <= 0.0:
		return 1.0
	# Con canvas_items + expand: escala final = factor × escala_base. Se busca que sea
	# (píxeles por píxel CSS) / UNIDADES_POR_PIXEL_CSS.
	var deseada: float = escala_pantalla / UNIDADES_POR_PIXEL_CSS
	return clampf(deseada / escala_base, 1.0, FACTOR_MAXIMO)


static func aplicar(ventana: Window) -> void:
	var factor: float = factor_para(
		Vector2(ventana.size), DisplayServer.screen_get_scale(), DisplayServer.is_touchscreen_available()
	)
	if not is_equal_approx(ventana.content_scale_factor, factor):
		ventana.content_scale_factor = factor


## Aplica la escala ahora y cada vez que cambie el tamaño de la ventana (p. ej. al girar el móvil).
static func vigilar(ventana: Window) -> void:
	aplicar(ventana)
	if ventana.has_meta(_META):
		return
	ventana.set_meta(_META, true)
	ventana.size_changed.connect(func() -> void: aplicar(ventana))
