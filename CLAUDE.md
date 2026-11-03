# Brote

Juego cozy de pago único (sin anuncios) para móvil y PC. Terrario infinito: el jugador coloca piezas hexagonales (bosque, agua, prado...) y el mundo crece y cobra vida. Sin derrota, sin tiempo, sin presión.

Plan completo por etapas: ver `plan-por-etapas.md` en el proyecto "Cozy game" de claude.ai.

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
scripts/  código GDScript (.gd)
data/     recursos de datos: piezas, criaturas, biomas (.tres)
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

- Abrir la carpeta en Godot 4.x (versión estándar, no .NET) y pulsar F5.
- Renderizador: GL Compatibility (necesario para que funcione bien en Web y móviles modestos).

## Estado actual

- [x] Etapa 0: cimientos (proyecto, estructura, escena de prueba)
- [ ] Etapa 1: prototipo gris (hexágonos, colocar, girar, cámara)
