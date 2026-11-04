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
art/      imágenes (low-poly generadas), sonidos, música (provisionales por ahora)
tests/    pruebas automáticas de la lógica
herramientas/  scripts auxiliares (sonidos, arte low-poly, prueba de estilos)
docs/     guías (prueba con jugadores)
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
- Dibujo: `DibujoPieza` pinta la textura `arte` de la pieza (girada); si falta, cae a un sector de color por borde.
- Guardado: `Guardado` (JSON con versión) en `user://guardado.json`, tras cada pieza y al cerrar o pausar la app. Para empezar de cero, borrar ese archivo (en Windows: `%APPDATA%\Godot\app_userdata\Brote\guardado.json`). Una pieza con id desconocido en un guardado se omite sin perder el resto.
- Sonidos provisionales en `art/sonidos/` (generados; se pueden sustituir).
- Criaturas (Etapa 3): `CriaturaDatos` (`data/criaturas/*.tres`) define hábitat y `requisitos` (bordes mínimos por terreno en todo el mundo). `Ecosistema` (lógica pura) decide cuántas hay, dónde llegan y cómo se pasean; `CriaturasVista` solo las dibuja. Añadir un `.tres` basta para una criatura nueva.
- Día/noche y clima: `Ciclo` (fase 0..1, día de 300 s) y `Clima` (despejado/lluvia con transición suave) son lógica pura. `Atmosfera` aplica el tinte (`data/ciclo_dia.tres`), la lluvia (`LluviaVista`) y el volumen de las capas de audio.
- Audio por capas: `Ambiente.volumenes` decide el nivel de base, melodía, agua, aves, grillos y lluvia según luz, clima y lo construido. Los loops están en `art/sonidos/ambiente/` y los genera `python herramientas/generar_sonidos.py` (provisionales; basta reemplazar los `.wav` y mantener `edit/loop_mode=2` en su `.import`).
- Pruebas que usan la escena completa deben fijar `ruta_guardado` en `juego.gd` antes de añadirla al árbol: headless comparte `user://` con el juego real y pisaría la partida guardada.
- Economía (Etapa 4): `RecursoDatos` (`data/recursos/`) y `ConstruccionDatos` (`data/construcciones/`) son datos; `Economia` (lógica pura) lleva los recursos y las construcciones. Cada pieza admite una construcción, que rinde según los terrenos de sus bordes (`afinidad`, cada borde aporta 1/6; 0 = no se puede construir). Tocar una pieza colocada abre `PanelConstruccion`; `RecursosHud` es el indicador de arriba a la derecha. Se guarda en el mismo archivo de partida.
- Bonus por vecinas: cada pieza vecina del **mismo tipo** (mismo id de pieza) suma +5 % (`Economia.BONO_VECINA`) a la producción de la construcción de esa pieza, hasta +30 %. Se calcula en vivo (`Tablero.vecinas_iguales`, `Economia.por_minuto_en`), así que colocar una pieza igual junto a una construcción la mejora al instante. Se muestra en el panel de construcción y al colocar una pieza.
- Biomas: prado, bosque, agua, tierra (café, para trigo), piedra (gris, cantera) y mineral (plateado, mina de plata). Los colores están en `data/terrenos.tres`.
- Menú, pausa y ajustes: `scenes/menu.tscn` es la escena principal; la pausa vive en `juego.tscn` (Esc o botón II). `Preferencias` guarda los volúmenes en `user://ajustes.cfg` y crea los buses `Musica` y `Efectos`.
- Teclas: R gira, Enter/Espacio confirma, Esc pausa.
- Los colores del tablero (huecos, contornos del fantasma) son `@export` de `TableroVista`; los de interfaz van en el tema.

## Decisiones de diseño

- **Estilo visual por ahora: low-poly generado por código.** Se probó isométrico 2.5D, pintado 2D y low-poly (`art/pruebas_estilo/`); el isométrico gustó, pero de momento se usa low-poly porque se puede generar sin artista. Es provisional: el arte definitivo se resolverá más adelante y bastará con cambiar el campo `arte` de cada `.tres`.
- **Cómo se genera el arte:** `python herramientas/generar_arte_lowpoly.py` lee los datos y escribe un SVG por pieza, construcción y criatura en `art/piezas`, `art/construcciones` y `art/criaturas`, y los enlaza en el campo `arte` de cada `.tres` (solo si está vacío). Es determinista. Una pieza nueva solo necesita su `.tres` con `bordes`. Después hay que correr `godot --headless --path . --import`; las imágenes importan con mipmaps (los `.svg.import` llevan `mipmaps/generate=true`).
- **Giro de las piezas con arte:** la imagen de una pieza tiene el borde 0 mirando al este; `DibujoPieza` la gira de 60° en 60° (`60° × giro`). Por eso los detalles de las piezas están pensados para verse bien girados (vista desde arriba).
- Si cambia el estilo a isométrico más adelante, la lógica de `Hex` y `Tablero` no cambia, pero hay que ajustar el dibujo y la detección de la pieza tocada.

## Estado actual

- [x] Etapa 0: cimientos (proyecto, estructura, escena de prueba)
- [x] Etapa 1: prototipo gris (hexágonos, mazo, colocar, girar, cámara)
- [x] Etapa 2: reglas de encaje, recompensa y guardado
- [x] Etapa 3: criaturas, ciclo día/noche, lluvia y audio por capas
- [~] Etapa 4: menú, pausa, ajustes, biomas nuevos, construcciones y recursos listos; prueba de estilos en `art/pruebas_estilo/`; faltan elegir el estilo y probar con 5 a 10 personas (`docs/guia-de-prueba.md`)
