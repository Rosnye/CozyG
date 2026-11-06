extends SceneTree
## Ejecuta todas las pruebas de `tests/prueba_*.gd` y sale con código 1 si alguna falla.
## Uso: godot --headless --path . --script tests/ejecutar_pruebas.gd

const CARPETA: String = "res://tests"


func _init() -> void:
	# Los textos de las pruebas están en español: se fija el idioma, no el del sistema.
	TranslationServer.set_locale("es")
	var total: int = 0
	var fallidas: int = 0
	var archivos: PackedStringArray = DirAccess.get_files_at(CARPETA)
	archivos.sort()
	for archivo in archivos:
		if not (archivo.begins_with("prueba_") and archivo.ends_with(".gd")) or archivo == "prueba_base.gd":
			continue
		var script: GDScript = load(CARPETA + "/" + archivo)
		var metodos: Array[String] = []
		for info in script.get_script_method_list():
			if String(info["name"]).begins_with("prueba_"):
				metodos.append(info["name"])
		metodos.sort()
		for metodo in metodos:
			var caso = script.new()
			caso.call(metodo)
			total += 1
			if caso.fallos.is_empty():
				print("  ok   %s::%s" % [archivo, metodo])
			else:
				fallidas += 1
				print("  FALLA %s::%s" % [archivo, metodo])
				for fallo in caso.fallos:
					print("        - " + fallo)
	print("\n%d pruebas, %d fallidas" % [total, fallidas])
	quit(1 if fallidas > 0 else 0)
