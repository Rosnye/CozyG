class_name RecursosHud
extends PanelContainer
## Pequeño indicador de recursos (arriba a la derecha). Se construye a partir de los datos.

var _etiquetas: Dictionary = {}  # id -> Label
var _anteriores: Dictionary = {}  # id -> int


func configurar(datos: Array[RecursoDatos]) -> void:
	var rejilla := GridContainer.new()
	rejilla.columns = 2
	rejilla.add_theme_constant_override("h_separation", 18)
	rejilla.add_theme_constant_override("v_separation", 4)
	add_child(rejilla)
	for recurso in datos:
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		fila.tooltip_text = recurso.nombre
		if recurso.icono != null:
			var icono := TextureRect.new()
			icono.texture = recurso.icono
			icono.custom_minimum_size = Vector2(30, 30)
			icono.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			fila.add_child(icono)
		else:
			var muestra := ColorRect.new()
			muestra.color = recurso.color
			muestra.custom_minimum_size = Vector2(18, 18)
			muestra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			fila.add_child(muestra)
		var etiqueta := Label.new()
		etiqueta.theme_type_variation = &"EtiquetaPequena"
		etiqueta.text = "0"
		etiqueta.custom_minimum_size = Vector2(48, 0)
		fila.add_child(etiqueta)
		rejilla.add_child(fila)
		_etiquetas[recurso.id] = etiqueta
		_anteriores[recurso.id] = 0


func actualizar(economia: Economia) -> void:
	for id: StringName in _etiquetas:
		var cantidad: int = economia.cantidad(id)
		if cantidad == _anteriores[id]:
			continue
		var etiqueta: Label = _etiquetas[id]
		etiqueta.text = str(cantidad)
		if cantidad > _anteriores[id]:
			_resaltar(etiqueta)
		_anteriores[id] = cantidad


## Pequeño "pop" cuando un recurso sube.
func _resaltar(etiqueta: Label) -> void:
	etiqueta.pivot_offset = etiqueta.size / 2.0
	etiqueta.scale = Vector2(1.3, 1.3)
	var tween := create_tween()
	tween.tween_property(etiqueta, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
