# Guía para probar Brote con otras personas (Etapa 4)

Objetivo: darle el juego a 5 a 10 personas y **observar sin explicar**. El resultado esperado es una lista de lo que confunde o aburre.

## Preparar la versión
1. Exportar a Web (en Godot: Proyecto → Exportar → Web, o por línea de comandos: `godot --headless --path . --export-release Web build/web/index.html`).
2. Comprimir el **contenido** de `build/web/` en un `.zip` (con `index.html` en la raíz).
3. Subirlo a itch.io como proyecto HTML en modo **restringido o borrador** y compartir el enlace privado. También sirve probarlo en la red local (`python -m http.server 8060 --directory build/web --bind 0.0.0.0`).
4. Para cada persona, pedir que use "Nueva partida" al empezar.

## Cómo observar
- No expliques nada antes. Di solo: "es un juego tranquilo, juega como quieras unos 10 minutos".
- Anota, sin interrumpir:
  - Qué intenta hacer primero y cuánto tarda en colocar la primera pieza.
  - Si encuentra solo cómo girar, confirmar, mover la cámara y hacer zoom.
  - Si descubre que se puede tocar una pieza para **construir**, y cuánto tarda.
  - Si entiende el indicador de recursos de arriba a la derecha.
  - Si se fija en las criaturas, el día/noche y la lluvia.
  - Cuándo se aburre, se frustra o deja de jugar.
- No guardes datos personales. El juego no recoge telemetría y así debe seguir.

## Preguntas al final (una a una, sin sugerir la respuesta)
1. ¿Qué has hecho durante el juego?
2. ¿Qué ha sido lo más agradable? ¿Y lo más confuso?
3. ¿Qué esperabas que pasara y no pasó?
4. ¿Volverías a abrirlo? ¿Cuándo y para qué?
5. Mira las tres propuestas de estilo (`art/pruebas_estilo/comparacion.html`): ¿cuál te parece más acogedora? ¿Por qué?

## Qué recopilar
Una tabla simple: persona, dispositivo, cuánto jugó, momento en que se confundió, comentario literal, estilo elegido. Con eso se decide el estilo para la Etapa 5 y los ajustes de la Etapa 4.
