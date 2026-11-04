# Probar Brote en el móvil

Godot en el navegador exige un **contexto seguro** (HTTPS o `localhost`), así que desde el móvil hace falta HTTPS.

1. Exporta a Web (Godot: Proyecto → Exportar → Web, destino `build/web/index.html`), o por línea de comandos:
   `godot --headless --path . --export-release Web build/web/index.html`
2. Desde la raíz del proyecto (`D:\Documentos\CozyG`), arranca el servidor HTTPS:
   `python herramientas/servir_https.py`
3. Abre en el móvil (misma red Wi-Fi) la dirección que muestra, del estilo `https://192.168.1.25:8443/`.
   El navegador avisará del certificado (es el tuyo, en tu red): Avanzado → Continuar.
4. Para parar el servidor: Ctrl+C.

## Qué revisar
- Botones cómodos al dedo (mínimo ~48 px); textos legibles.
- Vertical y horizontal: la barra inferior se apila en vertical; el panel de construcción usa 1, 2 o 3 columnas según la pantalla.
- Arrastrar con un dedo, pellizcar para hacer zoom (el mapa debe quedar anclado bajo los dedos) y tocar piezas.
- Tutorial completo solo con toques. Sonido tras el primer toque.
- Fluidez y calentamiento tras unos minutos.

## Detalles técnicos
- La escala de la interfaz la calcula `Pantalla` (`scripts/pantalla.gd`): solo se amplía en pantallas táctiles cuyo lado corto mide menos de 700 px CSS; en escritorio no cambia nada. Se ajusta sola al girar el móvil.
- El zoom y el arrastre usan un ancla (`CamaraControl`): el punto del mundo bajo los dedos al empezar el gesto sigue bajo ellos.
