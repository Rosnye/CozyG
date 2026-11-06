# Idiomas de Brote

El juego está en **español** (idioma de origen) e **inglés**. Los textos están escritos en español en las escenas, el código y los datos, y cada catálogo `data/idiomas/<idioma>.po` los traduce. Si falta una traducción, se ve el texto en español.

## Cómo elige el idioma el juego
- Por defecto, "Automático": sigue al idioma del dispositivo o del navegador (español si empieza por `es`; en cualquier otro caso, inglés).
- El jugador puede fijarlo en Ajustes (Automático / Español / English). El cambio es inmediato y se recuerda (`Preferencias.idioma`).
- La lógica está en `scripts/idioma.gd` (`Idioma.elegir`), con pruebas.

## Cómo escribir textos nuevos
- **En una escena** (`.tscn`): escribir el texto en español en `text`, `title`, etc. Godot lo traduce solo.
- **En el código**: `tr("Texto en español")`. Con formato: `tr("Construido: %s") % nombre`.
- **En los datos** (`.tres`): el campo `nombre` va en español; mostrarlo con `nombre_visible()` (piezas, construcciones, criaturas y recursos).
- No concatenar frases; usar un solo texto con `%s` / `%d` para que se pueda traducir entero.
- Si el texto lo cambia el código (por ejemplo un `Label.text`), volver a escribirlo cuando cambie el idioma (`NOTIFICATION_TRANSLATION_CHANGED`).

## Cómo mantener los catálogos
```
python herramientas/textos.py              # busca textos nuevos, los añade vacíos y lista lo pendiente
python herramientas/textos.py --comprobar  # solo comprueba (sale con error si falta algo)
```
Después traducir lo que aparezca en `data/idiomas/en.po` (`msgstr`). Las pruebas (`tests/prueba_traducciones.gd`) fallan si un texto no tiene traducción, si sobra uno que ya no se usa o si la traducción cambia los marcadores `%s`, `%d` o `%%`.

## Añadir un idioma nuevo (por ejemplo francés)
1. `python herramientas/textos.py --nuevo fr` crea `data/idiomas/fr.po` con todos los textos vacíos; traducirlos.
2. Añadir `"fr"` a `Idioma.SOPORTADOS` y su entrada en el selector de `AjustesPanel` (`OPCIONES_IDIOMA` y `_rellenar_idiomas`).
3. Añadir `res://data/idiomas/fr.po` a `internationalization/locale/translations` en `project.godot`.
4. Ampliar `tests/prueba_traducciones.gd` para el nuevo catálogo.
