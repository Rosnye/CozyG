# Brote

Juego cozy de pago único (sin anuncios) para móvil y PC. Terrario infinito: el jugador coloca piezas hexagonales (bosque, agua, prado...) y el mundo crece y cobra vida. Sin derrota, sin tiempo, sin presión.

Plan completo por etapas: ver `plan-por-etapas.md` en la raíz del repositorio.

## Reglas del proyecto

1. **Una sola base de código** para móvil y PC. Nada de ramas por plataforma.
2. **El arte nunca va escrito en el código.** Piezas, criaturas y objetos son recursos de datos (`.tres`) en `data/` que apuntan a su arte en `art/`. Así el arte provisional se cambia por el definitivo sin tocar lógica.
3. **Lógica separada de dibujo.** La cuadrícula, las reglas de encaje y el guardado no dependen de nodos visuales.
4. **Colores y tipografías en un tema central** (`Theme` de Godot), no dispersos por las escenas.
5. **Input unificado:** todo debe funcionar con toque y con mouse (ya está activo `emulate_touch_from_mouse`).
6. **Interfaz adaptable:** nada de tamaños fijos en píxeles que rompan en pantallas pequeñas. Usar contenedores y anclas.
7. **Sin anuncios ni telemetría invasiva.** Nunca.

## Estructura

```
scenes/   escenas (.tscn)
scripts/  código GDScript (.gd); la lógica pura está en scripts/hex/ (Hex, Tablero)
data/     recursos de datos: tema_brote.tres, piezas/ (.tres), criaturas, biomas
art/      imágenes, sonidos, música (provisionales por ahora)
tests/    pruebas automáticas de la lógica
```

## Convenciones

- GDScript con tipos estáticos (`var x: int`, `func f() -> void`).
- Nombres de archivos y carpetas en minúsculas con guion bajo.
- Comentarios y mensajes en español.
- Commits pequeños y descriptivos, una rama por etapa (`etapa-1-prototipo`, etc.).
- Probar con la lógica en pruebas automáticas; lo que es "sensación" se prueba jugando.

## Cómo correr

- Abrir la carpeta en Godot 4.7 (versión estándar, no .NET; el proyecto nació en 4.3 y se migró a 4.7) y pulsar F5.
- Renderizador: GL Compatibility (necesario para que funcione bien en Web y móviles modestos).

## Pruebas automáticas

Scripts propios, sin dependencias. Cada `tests/prueba_*.gd` hereda de `tests/prueba_base.gd` y define métodos `prueba_*`. Correr todas (desde la raíz del proyecto, con la ruta absoluta de Godot):

```
godot --headless --path . --script res://tests/ejecutar_pruebas.gd
```

Tras añadir un `class_name` nuevo, correr antes `godot --headless --path . --import`. Sale con código 1 si alguna falla.

## Juego (Etapas 1 y 2)

- Escena principal: `scenes/juego.tscn` (`scripts/juego.gd` une todo).
- `Tablero` guarda las celdas, la regla de colocación (junto a otra pieza) y el encaje (`evaluar`, `encaja_perfecto`); `TableroVista` solo dibuja y anima; `CamaraControl` hace arrastre, zoom (rueda y pellizco) y avisa de los toques.
- Las piezas son `PiezaDatos` (`data/piezas/*.tres`): añadir un `.tres` ahí basta para que entre en el mazo. Cada pieza tiene 6 `bordes` (terreno por dirección, en el orden de `Hex.DIRECCIONES`); girar la pieza gira sus bordes. Los colores de los terrenos están en `data/terrenos.tres`.
- Regla de encaje: se puede colocar siempre junto a otra pieza (no hay derrota). Si todos los bordes compartidos coinciden es un "encaje perfecto": onda, partículas y sonido. El contorno del fantasma es verde si encaja y naranja si no.
- Dibujo provisional: un sector de color por borde (`DibujoPieza`). Cuando una pieza tenga `arte`, se dibuja la textura en su lugar.
- Guardado: `Guardado` (JSON con versión) en `user://guardado.json`, tras cada pieza y al cerrar o pausar la app. Para empezar de cero, borrar ese archivo (en Windows: `%APPDATA%\Godot\app_userdata\Brote\guardado.json`). Una pieza con id desconocido en un guardado se omite sin perder el resto.
- Sonidos provisionales en `art/sonidos/` (generados; se pueden sustituir).
- Teclas: R gira, Enter/Espacio confirma.
- Los colores del tablero (huecos, contornos del fantasma) son `@export` de `TableroVista`; los de interfaz van en el tema.

## Estado actual

- [x] Etapa 0: cimientos (proyecto, estructura, escena de prueba)
- [x] Etapa 1: prototipo gris (hexágonos, mazo, colocar, girar, cámara)
- [~] Etapa 2: encaje, recompensa y guardado implementados; falta juzgar jugando si colocar bien se siente premiado
