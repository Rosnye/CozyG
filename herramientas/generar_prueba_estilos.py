"""Genera la prueba de estilos de arte de la Etapa 4 (solo biblioteca estándar).

Uso, desde la raíz del proyecto:
    python herramientas/generar_prueba_estilos.py

Crea en art/pruebas_estilo/ tres piezas (prado, bosque, agua) en tres estilos
(pintado, isometrico, lowpoly), un grupo de 7 piezas por estilo y comparacion.html
para verlos juntos. Son bocetos para decidir el estilo, no arte definitivo.
"""
import math
import os
import random

R = 100.0
RAIZ3 = math.sqrt(3)
SALIDA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "art", "pruebas_estilo")

PALETA = {
    "prado": {"base": "#bcd16b", "oscuro": "#8fae4a", "claro": "#d9e89a"},
    "bosque": {"base": "#5c8c57", "oscuro": "#3f6b3e", "claro": "#83b574"},
    "agua": {"base": "#73aec7", "oscuro": "#4f8ea9", "claro": "#b4dcec"},
}
TIERRA = {"base": "#8a6a4a", "oscuro": "#6b4f36"}
TRONCO = "#6b4a2f"
CONTORNO = "#4d4233"


def hexagono(radio, k=1.0, cx=0.0, cy=0.0):
    return [(cx + radio * math.cos(math.radians(60 * i - 30)), cy + radio * k * math.sin(math.radians(60 * i - 30)))
            for i in range(6)]


def pts(puntos):
    return " ".join(f"{x:.1f},{y:.1f}" for x, y in puntos)


def azar_de(semilla):
    return random.Random(semilla)


def dentro(azar, margen=0.72):
    """Punto al azar dentro del hexágono (en unidades de radio)."""
    while True:
        x, y = azar.uniform(-1, 1), azar.uniform(-1, 1)
        if abs(y) <= margen and abs(x) * 0.866 + abs(y) * 0.5 <= margen * 0.95:
            return x * R * 0.85, y * R * 0.85


def mezcla(c1, c2, t):
    a = [int(c1[i:i + 2], 16) for i in (1, 3, 5)]
    b = [int(c2[i:i + 2], 16) for i in (1, 3, 5)]
    return "#" + "".join(f"{round(a[i] + (b[i] - a[i]) * t):02x}" for i in range(3))


# --------------------------------------------------------------------------
# Estilo 1: pintado 2D (formas suaves, degradados, trazos de pincel)
# --------------------------------------------------------------------------

def pintado(tipo, semilla=1):
    p = PALETA[tipo]
    azar = azar_de(semilla * 7 + len(tipo))
    id_ = f"g{tipo}{semilla}"
    cuerpo = hexagono(R * 0.97)
    salida = [
        f'<defs><radialGradient id="{id_}" cx="40%" cy="35%" r="80%"><stop offset="0" stop-color="{p["claro"]}"/>'
        f'<stop offset="1" stop-color="{p["base"]}"/></radialGradient>'
        f'<clipPath id="c{id_}"><polygon points="{pts(cuerpo)}"/></clipPath></defs>',
        f'<polygon points="{pts(hexagono(R))}" fill="{p["oscuro"]}" stroke="{p["oscuro"]}" stroke-width="8" stroke-linejoin="round"/>',
        f'<polygon points="{pts(cuerpo)}" fill="url(#{id_})" stroke="{p["base"]}" stroke-width="6" stroke-linejoin="round"/>',
        f'<g clip-path="url(#c{id_})">',
    ]
    for _ in range(9):  # manchas de pintura
        x, y = dentro(azar, 0.9)
        color = p["claro"] if azar.random() < 0.5 else p["oscuro"]
        salida.append(f'<ellipse cx="{x:.1f}" cy="{y:.1f}" rx="{azar.uniform(14, 30):.1f}" ry="{azar.uniform(8, 18):.1f}" '
                      f'fill="{color}" opacity="0.22" transform="rotate({azar.uniform(-30, 30):.0f} {x:.1f} {y:.1f})"/>')
    if tipo == "prado":
        for _ in range(26):
            x, y = dentro(azar)
            largo = azar.uniform(6, 11)
            salida.append(f'<path d="M{x - 3:.1f},{y:.1f} q2,-{largo:.1f} 3,-{largo + 2:.1f} M{x:.1f},{y:.1f} q0,-{largo:.1f} 1,-{largo + 4:.1f} '
                          f'M{x + 3:.1f},{y:.1f} q-1,-{largo:.1f} -3,-{largo + 1:.1f}" stroke="{p["oscuro"]}" stroke-width="2.2" '
                          f'stroke-linecap="round" fill="none" opacity="0.8"/>')
        for _ in range(6):
            x, y = dentro(azar)
            color = azar.choice(["#fffaf0", "#f6d86b", "#f4b6c2"])
            salida.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="3.4" fill="{color}"/>')
    elif tipo == "bosque":
        arboles = sorted((dentro(azar, 0.6) for _ in range(6)), key=lambda a: a[1])
        for x, y in arboles:
            r = azar.uniform(17, 24)
            salida.append(f'<ellipse cx="{x:.1f}" cy="{y + r * 0.9:.1f}" rx="{r * 0.9:.1f}" ry="{r * 0.35:.1f}" fill="#000" opacity="0.15"/>')
            salida.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r:.1f}" fill="{p["oscuro"]}"/>')
            salida.append(f'<circle cx="{x - r * 0.15:.1f}" cy="{y - r * 0.2:.1f}" r="{r * 0.78:.1f}" fill="{p["base"]}"/>')
            salida.append(f'<circle cx="{x - r * 0.3:.1f}" cy="{y - r * 0.4:.1f}" r="{r * 0.4:.1f}" fill="{p["claro"]}" opacity="0.85"/>')
    else:
        for i in range(4):
            y = -50 + i * 32 + azar.uniform(-6, 6)
            x0 = -60 + azar.uniform(-10, 10)
            d = f"M{x0:.1f},{y:.1f} " + " ".join(f"q10,-9 20,0 t20,0" for _ in range(1)) + " t20,0 t20,0"
            salida.append(f'<path d="{d}" stroke="{p["claro"]}" stroke-width="4" stroke-linecap="round" fill="none" opacity="0.85"/>')
        for _ in range(5):
            x, y = dentro(azar)
            salida.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{azar.uniform(2.5, 5):.1f}" fill="#fff" opacity="0.5"/>')
    salida.append("</g>")
    return "\n".join(salida)


# --------------------------------------------------------------------------
# Estilo 2: isométrico 2.5D (diorama con grosor)
# --------------------------------------------------------------------------
K = 0.56      # aplastamiento vertical de la vista isométrica
GROSOR = 26   # altura del bloque


def isometrico(tipo, semilla=1):
    p = PALETA[tipo]
    azar = azar_de(semilla * 11 + len(tipo))
    cima = hexagono(R, K, 0, -GROSOR / 2)
    lado_izq = [cima[3], cima[2], (cima[2][0], cima[2][1] + GROSOR), (cima[3][0], cima[3][1] + GROSOR)]
    lado_der = [cima[2], cima[1], (cima[1][0], cima[1][1] + GROSOR), (cima[2][0], cima[2][1] + GROSOR)]
    lado_claro, lado_oscuro = (TIERRA["base"], TIERRA["oscuro"]) if tipo != "agua" else (p["oscuro"], mezcla(p["oscuro"], "#000000", 0.25))
    id_ = f"i{tipo}{semilla}"
    salida = [
        f'<defs><linearGradient id="{id_}" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{p["claro"]}"/>'
        f'<stop offset="1" stop-color="{p["base"]}"/></linearGradient></defs>',
        f'<ellipse cx="0" cy="{GROSOR / 2 + R * K * 0.95:.1f}" rx="{R * 0.95:.1f}" ry="{R * K * 0.28:.1f}" fill="#000" opacity="0.14"/>',
        f'<polygon points="{pts(lado_izq)}" fill="{lado_claro}" stroke="{CONTORNO}" stroke-opacity="0.5" stroke-width="2" stroke-linejoin="round"/>',
        f'<polygon points="{pts(lado_der)}" fill="{lado_oscuro}" stroke="{CONTORNO}" stroke-opacity="0.5" stroke-width="2" stroke-linejoin="round"/>',
        f'<polygon points="{pts(cima)}" fill="url(#{id_})" stroke="{CONTORNO}" stroke-opacity="0.5" stroke-width="2" stroke-linejoin="round"/>',
    ]
    base_y = -GROSOR / 2

    def punto():
        x, y = dentro(azar, 0.7)
        return x, base_y + y * K

    if tipo == "prado":
        for _ in range(7):
            x, y = punto()
            salida.append(f'<ellipse cx="{x:.1f}" cy="{y + 3:.1f}" rx="9" ry="4" fill="#000" opacity="0.12"/>')
            salida.append(f'<ellipse cx="{x:.1f}" cy="{y - 2:.1f}" rx="9" ry="7" fill="{p["oscuro"]}"/>')
            salida.append(f'<ellipse cx="{x - 2:.1f}" cy="{y - 5:.1f}" rx="6" ry="4.5" fill="{p["claro"]}"/>')
        for _ in range(5):
            x, y = punto()
            salida.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="2.6" fill="{azar.choice(["#fffaf0", "#f6d86b"])}"/>')
    elif tipo == "bosque":
        for x, y in sorted((punto() for _ in range(5)), key=lambda a: a[1]):
            h = azar.uniform(34, 46)
            salida.append(f'<ellipse cx="{x:.1f}" cy="{y + 3:.1f}" rx="15" ry="6" fill="#000" opacity="0.18"/>')
            salida.append(f'<rect x="{x - 3:.1f}" y="{y - 12:.1f}" width="6" height="16" fill="{TRONCO}"/>')
            salida.append(f'<ellipse cx="{x:.1f}" cy="{y - h * 0.55:.1f}" rx="17" ry="{h * 0.5:.1f}" fill="{p["oscuro"]}"/>')
            salida.append(f'<ellipse cx="{x - 3:.1f}" cy="{y - h * 0.62:.1f}" rx="13" ry="{h * 0.4:.1f}" fill="{p["base"]}"/>')
            salida.append(f'<ellipse cx="{x - 6:.1f}" cy="{y - h * 0.75:.1f}" rx="6" ry="{h * 0.17:.1f}" fill="{p["claro"]}"/>')
    else:
        for _ in range(5):
            x, y = punto()
            for escala in (1.0, 0.62):
                salida.append(f'<ellipse cx="{x:.1f}" cy="{y:.1f}" rx="{19 * escala:.1f}" ry="{7 * escala:.1f}" fill="none" '
                              f'stroke="{p["claro"]}" stroke-width="2" opacity="0.8"/>')
    return "\n".join(salida)


# --------------------------------------------------------------------------
# Estilo 3: low-poly (facetas triangulares)
# --------------------------------------------------------------------------

def lowpoly(tipo, semilla=1):
    p = PALETA[tipo]
    azar = azar_de(semilla * 13 + len(tipo))
    esquinas = hexagono(R)
    interior = []
    for i in range(6):
        ang = math.radians(60 * i - 30)
        r = R * azar.uniform(0.42, 0.58)
        interior.append((r * math.cos(ang), r * math.sin(ang)))
    triangulos = []
    for i in range(6):
        j = (i + 1) % 6
        triangulos.append(((0, 0), interior[i], interior[j]))
        triangulos.append((interior[i], esquinas[i], esquinas[j]))
        triangulos.append((interior[i], esquinas[j], interior[j]))
    salida = []
    for tri in triangulos:
        t = azar.uniform(-0.35, 0.45)
        color = mezcla(p["base"], p["claro"], t) if t >= 0 else mezcla(p["base"], p["oscuro"], -t * 1.6)
        salida.append(f'<polygon points="{pts(tri)}" fill="{color}" stroke="{color}" stroke-width="0.8" stroke-linejoin="round"/>')
    if tipo == "prado":
        for _ in range(6):
            x, y = dentro(azar, 0.65)
            salida.append(f'<polygon points="{pts([(x - 8, y), (x, y - 10), (x + 8, y)])}" fill="{p["oscuro"]}"/>')
            salida.append(f'<polygon points="{pts([(x, y - 10), (x + 8, y), (x + 1, y)])}" fill="{mezcla(p["oscuro"], "#000000", 0.2)}"/>')
    elif tipo == "bosque":
        for x, y in sorted((dentro(azar, 0.6) for _ in range(6)), key=lambda a: a[1]):
            salida.append(f'<rect x="{x - 2.5:.1f}" y="{y + 2:.1f}" width="5" height="9" fill="{TRONCO}"/>')
            for nivel, (ancho, alto, dy) in enumerate([(17, 20, 0), (13, 18, -13), (9, 16, -25)]):
                izq = [(x - ancho, y + dy), (x, y + dy - alto), (x, y + dy)]
                der = [(x, y + dy - alto), (x + ancho, y + dy), (x, y + dy)]
                salida.append(f'<polygon points="{pts(izq)}" fill="{p["base"]}"/>')
                salida.append(f'<polygon points="{pts(der)}" fill="{p["oscuro"]}"/>')
    else:
        for _ in range(4):
            x, y = dentro(azar, 0.7)
            salida.append(f'<polygon points="{pts([(x - 16, y), (x, y - 6), (x + 14, y + 2)])}" fill="#fff" opacity="0.45"/>')
    return "\n".join(salida)


ESTILOS = {"pintado": pintado, "isometrico": isometrico, "lowpoly": lowpoly}
NOMBRES = {"pintado": "Pintado 2D", "isometrico": "Isométrico 2.5D", "lowpoly": "Low-poly"}
PIEZAS = ["prado", "bosque", "agua"]


def svg(ancho, alto, cuerpo, fondo=None):
    rect = f'<rect width="{ancho}" height="{alto}" fill="{fondo}"/>' if fondo else ""
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{ancho}" height="{alto}" viewBox="0 0 {ancho} {alto}">'
            f'{rect}{cuerpo}</svg>')


def pieza_suelta(estilo, tipo):
    return svg(256, 256, f'<g transform="translate(128,128)">{ESTILOS[estilo](tipo)}</g>')


def grupo(estilo):
    """Siete piezas juntas, para juzgar cómo se ven unidas."""
    k = K if estilo == "isometrico" else 1.0
    disposicion = [((0, 0), "prado"), ((1, 0), "bosque"), ((0, 1), "agua"), ((-1, 1), "prado"),
                   ((-1, 0), "bosque"), ((0, -1), "agua"), ((1, -1), "bosque")]
    elementos = []
    for (q, r), tipo in disposicion:
        x = R * RAIZ3 * (q + r / 2.0)
        y = R * 1.5 * r * k
        elementos.append((y, f'<g transform="translate({x:.1f},{y:.1f})">{ESTILOS[estilo](tipo, semilla=q * 5 + r * 3 + 9)}</g>'))
    elementos.sort(key=lambda e: e[0])
    return svg(640, 560, f'<g transform="translate(320,{280 if estilo != "isometrico" else 270})">{"".join(e[1] for e in elementos)}</g>', "#f4ead5")


def pagina():
    filas = []
    for estilo in ESTILOS:
        piezas = "".join(f'<figure><img src="{estilo}_{t}.svg" alt="{t}"><figcaption>{t}</figcaption></figure>' for t in PIEZAS)
        filas.append(f'<section><h2>{NOMBRES[estilo]}</h2><div class="fila">{piezas}'
                     f'<figure class="grupo"><img src="{estilo}_grupo.svg" alt="grupo"><figcaption>unidas</figcaption></figure></div></section>')
    return f"""<!doctype html>
<html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Brote: prueba de estilos</title>
<style>
body{{margin:0;padding:24px 16px;background:#f4ead5;color:#4d4233;font-family:system-ui,sans-serif}}
h1{{margin:0 0 4px}} p{{margin:0 0 24px;max-width:60ch}}
section{{margin-bottom:32px}} h2{{margin:0 0 8px}}
.fila{{display:flex;flex-wrap:wrap;gap:12px;align-items:flex-end}}
figure{{margin:0;text-align:center}} figure img{{width:180px;height:180px}} figure.grupo img{{width:330px;height:auto;border-radius:16px}}
figcaption{{font-size:14px;opacity:.7}}
</style></head><body>
<h1>Prueba de estilos de arte</h1>
<p>Las mismas tres piezas (prado, bosque, agua) en tres estilos. Bocetos generados por código para decidir la dirección; el arte definitivo es de la Etapa 5.</p>
{''.join(filas)}
</body></html>"""


def main():
    os.makedirs(SALIDA, exist_ok=True)
    for estilo in ESTILOS:
        for tipo in PIEZAS:
            with open(os.path.join(SALIDA, f"{estilo}_{tipo}.svg"), "w", encoding="utf-8") as f:
                f.write(pieza_suelta(estilo, tipo))
        with open(os.path.join(SALIDA, f"{estilo}_grupo.svg"), "w", encoding="utf-8") as f:
            f.write(grupo(estilo))
    with open(os.path.join(SALIDA, "comparacion.html"), "w", encoding="utf-8") as f:
        f.write(pagina())
    # Godot no debe importar estos bocetos como recursos del juego.
    open(os.path.join(SALIDA, ".gdignore"), "w").close()
    print("escrito en", os.path.normpath(SALIDA))


if __name__ == "__main__":
    main()
