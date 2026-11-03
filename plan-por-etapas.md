# Brote: plan de desarrollo por etapas (para trabajar con Claude Code)

## Decisiones técnicas
- **Una sola base de código, no dos versiones.** Móvil y PC comparten lógica, arte y guardado. Solo cambian el input (toque vs mouse) y la interfaz (adaptable). Mantener dos versiones duplica el trabajo de mantenimiento y de bugs, y para un equipo pequeño es el error más caro.
- **Motor: Godot 4.** Es gratuito y sin regalías, exporta a Android, iOS, Windows, Mac, Linux y Web desde el mismo proyecto. Sus escenas y scripts (GDScript) son texto plano, lo que funciona muy bien con Claude Code. La versión Web sirve para probar rápido en el navegador y compartir prototipos (por ejemplo en itch.io).
- **Estilo visual: se decide después, el código no debe depender de él.** Visión final: acogedor, colores cálidos, formas suaves. Para eso:
  - Cada pieza, criatura y objeto es un *dato* (recurso de Godot) que apunta a su arte; nada de arte "escrito" en el código.
  - La lógica del mundo (la cuadrícula hexagonal, reglas de encaje) está separada de cómo se dibuja.
  - Colores y tipografías viven en un tema central, para poder cambiarlos de un solo lugar.
  - Se usa arte provisional (formas de colores planas) hasta la etapa 5.

## Etapas

### Etapa 0: Cimientos (1 a 2 días)
- Crear el proyecto Godot y el repositorio git.
- Escribir `CLAUDE.md` con las reglas del proyecto (estructura de carpetas, convenciones, "arte siempre como datos", cómo correr pruebas).
- Exportar una versión Web vacía para comprobar que el flujo de compilar y probar funciona.
- **Listo cuando:** abres el juego en el navegador y en tu móvil mostrando una pantalla en blanco con un botón.

### Etapa 1: Prototipo gris, "¿es agradable colocar piezas?" (1 semana)
- Cuadrícula hexagonal infinita (se crea al ir colocando).
- Mazo infinito: sale una pieza aleatoria (bosque, agua, prado) como hexágono de color plano.
- Colocar, girar y confirmar. Cámara con arrastrar y zoom (toque y mouse).
- **Listo cuando:** 10 minutos de juego se sienten bien aunque sea feo. Si no, se ajusta aquí antes de seguir.

### Etapa 2: Reglas y recompensa (1 semana)
- Reglas de encaje entre vecinas (el río continúa, el bosque se agrupa).
- Retroalimentación al encajar bien: animación, sonido suave, partículas simples.
- Guardado automático y carga.
- Pruebas automáticas de la lógica (encaje, guardado).
- **Listo cuando:** colocar bien se siente premiado y cerrar/abrir el juego conserva tu mundo.

### Etapa 3: Que el mundo viva (1 a 2 semanas)
- Criaturas que llegan según lo que construyes (5 al inicio).
- Ciclo día/noche lento y clima ligero.
- Música y sonido ambiente que reaccionan al mundo (por capas).
- **Listo cuando:** dejar el juego abierto un rato y mirarlo ya resulta relajante.

### Etapa 4: Corte vertical y primeras pruebas (1 semana)
- Un bioma completo y pulido a nivel de funcionamiento, con menú, pausa y ajustes.
- Prueba de arte: hacer 3 piezas en 2 o 3 estilos distintos (2D pintado, 2.5D isométrico, low-poly) y elegir uno.
- Dar el juego a 5 a 10 personas y observar sin explicar.
- **Listo cuando:** tienes decisión de estilo y una lista de lo que confunde o aburre.

### Etapa 5: Arte acogedor definitivo (2 a 4 semanas, depende del arte)
- Sustituir el arte provisional por el definitivo (propio, de un artista o paquetes con licencia).
- Paleta cálida, sombras suaves, interfaz redondeada, animaciones con "rebote" suave.
- **Listo cuando:** una captura de pantalla cualquiera ya parece un juego que querrías comprar.

### Etapa 6: Móvil y pulido (2 semanas)
- Rendimiento y batería en móviles modestos, interfaz según tamaño de pantalla, orientación.
- Accesibilidad (tamaño de texto, daltonismo, volumen por separado), idiomas (español e inglés al menos).
- Pago único integrado (Google Play, App Store, Steam), página de tienda, tráiler corto.
- **Listo cuando:** corre fluido en un móvil de gama baja y la compra funciona de punta a punta.

### Etapa 7: Lanzamiento y expansiones
- Lanzar la versión base. Recoger opiniones.
- Biomas nuevos como paquetes o actualizaciones (Otoño, Nieve, Costa, Noche...), cada uno con su estética, piezas y criaturas propias.

## Cómo trabajar cada etapa con Claude Code
1. Una rama de git por etapa; commits pequeños.
2. Pedirle a Claude Code una tarea concreta a la vez (no "haz la etapa 1" entera).
3. Pedir pruebas automáticas para la lógica (reglas, guardado), y probar a mano lo que es "sensación".
4. Al terminar cada etapa, actualizar `CLAUDE.md` con lo aprendido.

### Primer prompt sugerido para la Etapa 0
> Crea un proyecto Godot 4 para un juego cozy llamado "Brote" (terrario infinito de piezas hexagonales, para móvil y PC). Configura la estructura de carpetas (`scenes/`, `scripts/`, `data/`, `art/`, `tests/`), un `CLAUDE.md` con la regla de que el arte siempre es un recurso de datos y no está en el código, y una escena inicial con un botón. Deja listo el export a Web.

## Riesgos a vigilar
- **Descubrimiento:** un juego de pago único necesita comunidad y tráiler antes del lanzamiento. Empezar a mostrar capturas desde la etapa 4.
- **Alcance:** resistir añadir sistemas antes de validar la etapa 1.
- **Arte:** es el mayor costo de tiempo y dinero; decidir presupuesto antes de la etapa 5.
