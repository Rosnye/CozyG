"""Genera el arte low-poly de Brote por código (solo biblioteca estándar de Python).

Uso, desde la raíz del proyecto:
    python herramientas/generar_arte_lowpoly.py

Lee los datos (`data/piezas`, `data/construcciones`, `data/criaturas`, `data/terrenos.tres`),
escribe un SVG por elemento en `art/piezas`, `art/construcciones`, `art/criaturas` y `art/recursos`,
y enlaza cada uno en su `.tres` (campo `arte`, o `icono` en los recursos) si aún no lo tiene. Es determinista: la misma pieza
sale siempre igual. Cuando llegue arte definitivo basta con cambiar el campo `arte`.
"""
import glob
import math
import os
import random
import re

RAIZ_PROYECTO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
R = 100.0  # radio del hexágono en el SVG
ANCHO_HEX = math.sqrt(3) * R
CONTORNO = "#4d4233"


# --- Color ----------------------------------------------------------------

def a_hex(r, g, b):
    return "#%02x%02x%02x" % (round(r * 255), round(g * 255), round(b * 255))


def mezcla(c1, c2, t):
    a = [int(c1[i:i + 2], 16) for i in (1, 3, 5)]
    b = [int(c2[i:i + 2], 16) for i in (1, 3, 5)]
    return "#" + "".join("%02x" % round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def paleta(base):
    return {"base": base, "claro": mezcla(base, "#ffffff", 0.32), "oscuro": mezcla(base, "#1b2433", 0.32)}


def tono(pal, t):
    """t > 0 aclara, t < 0 oscurece."""
    return mezcla(pal["base"], pal["claro"], min(t, 1.0)) if t >= 0 else mezcla(pal["base"], pal["oscuro"], min(-t * 1.3, 1.0))


# --- Lectura de los .tres --------------------------------------------------

def leer(ruta):
    texto = open(ruta, encoding="utf-8").read()
    datos = {"ruta": ruta, "texto": texto}
    datos["id"] = re.search(r'^id = &"(\w+)"', texto, re.M).group(1)
    color = re.search(r"^color = Color\(([^)]*)\)", texto, re.M)
    if color:
        r, g, b = [float(v) for v in color.group(1).split(",")[:3]]
        datos["color"] = a_hex(r, g, b)
    bordes = re.search(r"bordes = Array\[StringName\]\(\[(.*?)\]\)", texto, re.S)
    datos["bordes"] = re.findall(r'&"(\w+)"', bordes.group(1)) if bordes else []
    datos["de_noche"] = bool(re.search(r"^solo_de_noche = true", texto, re.M))
    return datos


def leer_terrenos():
    texto = open(os.path.join(RAIZ_PROYECTO, "data", "terrenos.tres"), encoding="utf-8").read()
    terrenos = {}
    for nombre, valores in re.findall(r'&"(\w+)": Color\(([^)]*)\)', texto):
        r, g, b = [float(v) for v in valores.split(",")[:3]]
        terrenos[nombre] = a_hex(r, g, b)
    return terrenos


def enlazar_arte(datos, ruta_recurso, campo="arte"):
    """Añade `<campo> = ...` al .tres si todavía no lo tiene (idempotente)."""
    if re.search(rf"^{campo} = ", datos["texto"], re.M):
        return False
    texto = datos["texto"]
    texto = re.sub(r"load_steps=\d+", "load_steps=3", texto, count=1)
    ext = f'[ext_resource type="Texture2D" path="{ruta_recurso}" id="2"]\n'
    texto = texto.replace("\n[resource]", "\n" + ext + "\n[resource]", 1) if "[ext_resource" in texto else texto
    texto = texto.rstrip("\n") + f'\n{campo} = ExtResource("2")\n'
    with open(datos["ruta"], "w", encoding="utf-8", newline="\n") as f:
        f.write(texto)
    return True


# --- Geometría ------------------------------------------------------------

def pts(puntos):
    return " ".join(f"{x:.1f},{y:.1f}" for x, y in puntos)


def poligono(puntos, color, extra=""):
    return f'<polygon points="{pts(puntos)}" fill="{color}" stroke="{color}" stroke-width="0.7" stroke-linejoin="round"{extra}/>'


def semilla(texto):
    return sum(ord(c) * (i + 7) for i, c in enumerate(texto))


def esquinas():
    return [(R * math.cos(math.radians(60 * i - 30)), R * math.sin(math.radians(60 * i - 30))) for i in range(6)]


def luz(angulo):
    """Cuánto da la luz (de arriba a la izquierda) a una cara que mira hacia `angulo`."""
    return math.cos(angulo - math.radians(225))


# --- Detalles de las piezas (vistos desde arriba) --------------------------

def arbol(az, x, y, r, pal):
    n = 7
    angulos = [2 * math.pi * i / n + az.uniform(-0.15, 0.15) for i in range(n)]
    borde = [(x + r * az.uniform(0.85, 1.1) * math.cos(a), y + r * az.uniform(0.85, 1.1) * math.sin(a)) for a in angulos]
    cima = (x - r * 0.12, y - r * 0.18)
    partes = [poligono([(px + r * 0.28, py + r * 0.34) for px, py in borde], "#000000", ' opacity="0.18"')]
    for i in range(n):
        j = (i + 1) % n
        medio = (angulos[i] + angulos[j]) / 2
        partes.append(poligono([cima, borde[i], borde[j]], tono(pal, 0.45 * luz(medio) + az.uniform(-0.08, 0.08))))
    return partes


def roca(az, x, y, r, pal):
    n = 6
    angulos = [2 * math.pi * i / n + az.uniform(-0.25, 0.25) for i in range(n)]
    borde = [(x + r * az.uniform(0.7, 1.15) * math.cos(a), y + r * az.uniform(0.6, 1.0) * math.sin(a)) for a in angulos]
    cima = (x - r * 0.1, y - r * 0.2)
    partes = [poligono([(px + r * 0.25, py + r * 0.3) for px, py in borde], "#000000", ' opacity="0.2"')]
    for i in range(n):
        j = (i + 1) % n
        medio = (angulos[i] + angulos[j]) / 2
        partes.append(poligono([cima, borde[i], borde[j]], tono(pal, 0.5 * luz(medio) + az.uniform(-0.1, 0.1))))
    return partes


def cristal(az, x, y, r, pal):
    giro = az.uniform(-25, 25)
    cuerpo = [(0, -1.7 * r), (0.7 * r, -0.6 * r), (0.55 * r, r), (0, 1.25 * r), (-0.55 * r, r), (-0.7 * r, -0.6 * r)]
    izq = [cuerpo[0], cuerpo[5], cuerpo[4], cuerpo[3]]
    der = [cuerpo[0], cuerpo[1], cuerpo[2], cuerpo[3]]
    return [
        f'<g transform="translate({x:.1f},{y:.1f}) rotate({giro:.0f})">',
        poligono([(px + 3, py + 4) for px, py in cuerpo], "#000000", ' opacity="0.18"'),
        poligono(izq, mezcla(pal["claro"], "#ffffff", 0.35)),
        poligono(der, pal["base"]),
        poligono([cuerpo[0], cuerpo[1], (0, -0.2 * r)], mezcla(pal["claro"], "#ffffff", 0.6)),
        "</g>",
    ]


def mata(az, x, y, pal):
    return [
        poligono([(x - 6, y), (x - 4, y - 10), (x - 1, y)], pal["oscuro"]),
        poligono([(x - 2, y), (x + 1, y - 13), (x + 4, y)], pal["claro"]),
        poligono([(x + 2, y), (x + 6, y - 9), (x + 8, y)], pal["oscuro"]),
    ]


def flor(az, x, y):
    color = az.choice(["#fffaf0", "#f6d86b", "#f4b6c2"])
    return [poligono([(x, y - 3.5), (x + 3, y), (x, y + 3.5), (x - 3, y)], color)]


def reflejo(az, x, y):
    ancho = az.uniform(10, 17)
    return [poligono([(x - ancho, y), (x, y - 2.5), (x + ancho, y + 1), (x, y + 2.5)], "#ffffff", ' opacity="0.4"')]


def surcos(centro, c0, c1, pal):
    partes = []
    for f in (0.4, 0.58, 0.76):
        a = (centro[0] + (c0[0] - centro[0]) * f, centro[1] + (c0[1] - centro[1]) * f)
        b = (centro[0] + (c1[0] - centro[0]) * f, centro[1] + (c1[1] - centro[1]) * f)
        a2 = (a[0] + (centro[0] - a[0]) * 0.07, a[1] + (centro[1] - a[1]) * 0.07)
        b2 = (b[0] + (centro[0] - b[0]) * 0.07, b[1] + (centro[1] - b[1]) * 0.07)
        partes.append(poligono([a, b, b2, a2], pal["oscuro"], ' opacity="0.7"'))
    return partes


def punto_en_sector(az, centro, c0, c1):
    """Punto al azar dentro del sector (lejos del centro y del borde exterior)."""
    # Mezcla baricéntrica entre el centro y las dos esquinas del sector.
    a = az.uniform(0.0, 1.0)
    wc = 0.3 + 0.2 * az.random()
    w0, w1 = (1 - wc) * a, (1 - wc) * (1 - a)
    x = centro[0] * wc + c0[0] * w0 + c1[0] * w1
    y = centro[1] * wc + c0[1] * w0 + c1[1] * w1
    return (x * 0.92, y * 0.92)


def pieza_svg(datos, terrenos):
    id_ = datos["id"]
    az = random.Random(semilla(id_))
    bordes = datos["bordes"] or [id_] * 6
    cs = esquinas()
    medios = [((cs[d][0] + cs[(d + 1) % 6][0]) / 2, (cs[d][1] + cs[(d + 1) % 6][1]) / 2) for d in range(6)]
    centro = (az.uniform(-4, 4), az.uniform(-4, 4))
    interior = []
    for i in range(6):
        ang = math.radians(60 * i - 30)
        r = R * az.uniform(0.45, 0.58)
        interior.append((r * math.cos(ang), r * math.sin(ang)))
    salida = []
    detalles = []  # (y, [partes])
    usados = []
    for d in range(6):
        terreno = bordes[d]
        pal = paleta(terrenos.get(terreno, datos.get("color", "#cccccc")))
        c0, c1 = cs[d], cs[(d + 1) % 6]
        p0, p1 = interior[d], interior[(d + 1) % 6]
        for tri in ((centro, p0, p1), (p0, c0, medios[d]), (p0, medios[d], p1), (p1, medios[d], c1)):
            cx = sum(p[0] for p in tri) / 3
            cy = sum(p[1] for p in tri) / 3
            t = -0.2 * (cx + cy) / R + az.uniform(-0.22, 0.22)
            salida.append(poligono(tri, tono(pal, t)))
        # detalles propios del terreno de este sector
        cantidad = {"bosque": 2, "prado": 3, "agua": 2, "piedra": 2, "mineral": 2, "tierra": 0}.get(terreno, 0)
        for _ in range(cantidad):
            for _intento in range(12):
                x, y = punto_en_sector(az, centro, c0, c1)
                if all((x - ux) ** 2 + (y - uy) ** 2 > 24 ** 2 for ux, uy in usados):
                    break
            else:
                continue
            usados.append((x, y))
            if terreno == "bosque":
                detalles.append((y, arbol(az, x, y, az.uniform(11, 15), pal)))
            elif terreno == "piedra":
                detalles.append((y, roca(az, x, y, az.uniform(9, 13), pal)))
            elif terreno == "mineral":
                detalles.append((y, cristal(az, x, y, az.uniform(7, 10), pal)))
            elif terreno == "prado":
                detalles.append((y, mata(az, x, y, pal) if az.random() < 0.7 else flor(az, x, y)))
            elif terreno == "agua":
                detalles.append((y, reflejo(az, x, y)))
        if terreno == "tierra":
            detalles.append((-999, surcos(centro, c0, c1, pal)))
    for _y, partes in sorted(detalles, key=lambda e: e[0]):
        salida.extend(partes)
    contorno = pts(cs + [cs[0]])
    cuerpo = "\n".join(salida)
    ancho, alto = ANCHO_HEX, 2 * R
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{ancho * 1.5:.0f}" height="{alto * 1.5:.0f}" '
            f'viewBox="{-ancho / 2:.2f} {-R:.2f} {ancho:.2f} {alto:.2f}">\n'
            f'<clipPath id="h"><polygon points="{pts(cs)}"/></clipPath>\n<g clip-path="url(#h)">\n{cuerpo}\n</g>\n'
            f'<polyline points="{contorno}" fill="none" stroke="{CONTORNO}" stroke-opacity="0.45" stroke-width="2.5" '
            f'stroke-linejoin="round"/>\n</svg>\n')


# --- Construcciones ---------------------------------------------------------

def construccion_svg(datos):
    c = datos["color"]
    claro, medio, oscuro = mezcla(c, "#ffffff", 0.3), c, mezcla(c, "#1b2433", 0.22)
    techo_c, techo_o = mezcla(c, "#3a2418", 0.55), mezcla(c, "#2a1810", 0.7)
    id_ = datos["id"]
    p = [poligono([(64 + 50 * math.cos(a), 104 + 12 * math.sin(a)) for a in [i * math.pi / 4 for i in range(8)]], "#000000", ' opacity="0.2"')]
    p += [
        poligono([(30, 64), (64, 72), (64, 104), (30, 94)], claro),
        poligono([(64, 72), (98, 64), (98, 94), (64, 104)], oscuro),
        poligono([(20, 64), (64, 22), (64, 74)], techo_c),
        poligono([(64, 22), (108, 64), (64, 74)], techo_o),
        poligono([(52, 88), (62, 91), (62, 104), (52, 101)], "#3a2a1c", ' opacity="0.75"'),
        poligono([(72, 80), (88, 77), (88, 88), (72, 91)], "#f3e6b8", ' opacity="0.85"'),
    ]
    if id_ == "aserradero":
        p += [poligono([(96, 100), (108, 96), (112, 104), (100, 108)], "#8a5a30"), poligono([(98, 92), (110, 88), (112, 96), (100, 100)], "#a87040")]
    elif id_ == "pesqueria":
        p += [poligono([(104, 60), (104, 96), (122, 96)], "#f4f1e6"), poligono([(104, 60), (104, 96), (96, 96)], "#cfd8e3")]
    elif id_ == "corral":
        p += [poligono([(x, y), (x + 4, y), (x + 4, y + 18), (x, y + 18)], "#a07040") for x, y in [(6, 84), (16, 86), (26, 88)]]
    elif id_ == "granja_trigo":
        p += [poligono([(x, 100), (x + 4, 100), (x + 2, 82)], "#f0cf55") for x in (100, 107, 114)]
    elif id_ == "cantera":
        p += roca(random.Random(5), 108, 98, 11, paleta("#8a8a92"))
    elif id_ == "mina_plata":
        p += cristal(random.Random(9), 108, 92, 8, paleta("#c9d3e3"))
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">\n' + "\n".join(p) + "\n</svg>\n"


# --- Criaturas --------------------------------------------------------------

def blob(az, cx, cy, rx, ry, pal, n=8):
    angulos = [2 * math.pi * i / n + az.uniform(-0.1, 0.1) for i in range(n)]
    borde = [(cx + rx * az.uniform(0.92, 1.05) * math.cos(a), cy + ry * az.uniform(0.92, 1.05) * math.sin(a)) for a in angulos]
    cima = (cx - rx * 0.15, cy - ry * 0.2)
    partes = []
    for i in range(n):
        j = (i + 1) % n
        partes.append(poligono([cima, borde[i], borde[j]], tono(pal, 0.4 * luz((angulos[i] + angulos[j]) / 2) + az.uniform(-0.06, 0.06))))
    return partes


def criatura_svg(datos):
    id_ = datos["id"]
    az = random.Random(semilla(id_))
    pal = paleta(datos["color"])
    p = [poligono([(64 + 40 * math.cos(a), 108 + 8 * math.sin(a)) for a in [i * math.pi / 4 for i in range(8)]], "#000000", ' opacity="0.2"')]
    if id_ == "luciernaga":
        p += [poligono([(60, 70), (34, 40), (62, 56)], "#ffffff", ' opacity="0.45"'), poligono([(68, 70), (94, 40), (66, 56)], "#ffffff", ' opacity="0.45"')]
        p += blob(az, 64, 76, 14, 18, pal, 6)
        p += [poligono([(58, 88), (70, 88), (64, 100)], "#fff6a8")]
        return svg128(p)
    if id_ == "garza":
        p += [poligono([(52, 70), (66, 70), (96, 34), (88, 28)], mezcla("#ffffff", pal["oscuro"], 0.15)),
              poligono([(46, 108), (50, 70), (54, 70), (52, 108)], "#e8a35a"), poligono([(62, 108), (62, 70), (66, 70), (68, 108)], "#e8a35a")]
    cuerpo_rx, cuerpo_ry = (36, 26) if id_ != "rana" else (38, 24)
    p += blob(az, 60, 76, cuerpo_rx, cuerpo_ry, pal)
    cabeza = (92, 54) if id_ != "garza" else (98, 30)
    r = 19 if id_ != "garza" else 12
    if id_ == "conejo":
        p += [poligono([(84, 40), (80, 8), (92, 38)], pal["claro"]), poligono([(94, 40), (98, 10), (104, 42)], pal["base"]),
              poligono([(85, 38), (82, 16), (90, 38)], "#f4b6c2")]
        p += blob(az, 30, 78, 11, 11, paleta("#ffffff"), 6)
    if id_ == "ciervo":
        marron = "#7a4a28"
        p += [poligono([(88, 38), (80, 4), (84, 4), (92, 38)], marron), poligono([(98, 38), (106, 4), (110, 4), (102, 38)], marron),
              poligono([(82, 18), (70, 14), (82, 24)], marron), poligono([(104, 18), (116, 14), (104, 24)], marron)]
        p += [poligono([(40, 96), (46, 96), (46, 110), (40, 110)], pal["oscuro"]), poligono([(70, 96), (76, 96), (76, 110), (70, 110)], pal["oscuro"])]
    p += blob(az, cabeza[0], cabeza[1], r, r, pal, 7)
    if id_ == "rana":
        p += blob(az, 84, 38, 8, 8, pal, 6) + blob(az, 102, 38, 8, 8, pal, 6)
        p += [poligono([(80, 62), (108, 62), (104, 68), (84, 68)], pal["oscuro"])]
    if id_ == "garza":
        p += [poligono([(108, 28), (126, 34), (108, 36)], "#f0a030")]
    ojo = (cabeza[0] + r * 0.35, cabeza[1] - r * 0.15)
    p += [poligono([(ojo[0] - 2.6, ojo[1]), (ojo[0], ojo[1] - 2.6), (ojo[0] + 2.6, ojo[1]), (ojo[0], ojo[1] + 2.6)], "#2a211a")]
    return svg128(p)


def svg128(partes):
    return '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">\n' + "\n".join(partes) + "\n</svg>\n"


# --- Iconos de recursos -----------------------------------------------------

def icono_svg(datos):
    id_ = datos["id"]
    az = random.Random(semilla(id_))
    pal = paleta(datos["color"])
    p = []
    if id_ == "madera":
        for y, dx in ((40, 0), (58, 10)):
            p += [poligono([(10 + dx, y), (46 + dx, y - 4), (46 + dx, y + 12), (10 + dx, y + 16)], mezcla("#8a5a30", "#000000", 0.1)),
                  poligono([(10 + dx, y), (46 + dx, y - 4), (46 + dx, y + 2), (10 + dx, y + 6)], "#a87040")]
            p += blob(az, 46 + dx, y + 4, 8, 10, paleta("#d9b27a"), 6)
    elif id_ == "trigo":
        for x, h in ((20, 46), (32, 54), (44, 44)):
            p += [poligono([(x - 1.5, 58), (x + 1.5, 58), (x + 1.5, 58 - h * 0.6), (x - 1.5, 58 - h * 0.6)], "#b5a04a")]
            for k in range(4):
                y = 58 - h * 0.55 - k * 7
                p += [poligono([(x, y), (x - 8, y - 6), (x - 2, y - 9)], pal["claro"]), poligono([(x, y), (x + 8, y - 6), (x + 2, y - 9)], pal["base"])]
    elif id_ == "pescado":
        p += blob(az, 30, 34, 22, 13, pal, 8)
        p += [poligono([(48, 34), (62, 22), (62, 46)], pal["oscuro"]), poligono([(26, 22), (34, 12), (38, 24)], pal["oscuro"]),
              poligono([(14, 31), (18, 28), (18, 34)], "#2a211a")]
    elif id_ == "carne":
        p += blob(az, 28, 30, 18, 15, pal, 8)
        p += [poligono([(40, 40), (56, 54), (52, 58), (36, 46)], "#f2ebd8"), poligono([(52, 54), (60, 52), (58, 60), (52, 62)], "#f2ebd8")]
    elif id_ == "piedra":
        p += roca(az, 26, 38, 18, pal) + roca(az, 44, 44, 13, paleta("#6f6f78"))
    elif id_ == "mineral":
        p += cristal(az, 24, 38, 11, paleta("#9fb2d8")) + cristal(az, 44, 36, 14, pal) + cristal(az, 34, 46, 8, paleta("#e6edf8"))
    return '<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">\n' + "\n".join(p) + "\n</svg>\n"


# --- Principal --------------------------------------------------------------

def escribir(ruta, contenido):
    os.makedirs(os.path.dirname(ruta), exist_ok=True)
    with open(ruta, "w", encoding="utf-8", newline="\n") as f:
        f.write(contenido)


def main():
    terrenos = leer_terrenos()
    grupos = [
        ("piezas", "data/piezas", lambda d: pieza_svg(d, terrenos), "arte"),
        ("construcciones", "data/construcciones", construccion_svg, "arte"),
        ("criaturas", "data/criaturas", criatura_svg, "arte"),
        ("recursos", "data/recursos", icono_svg, "icono"),
    ]
    for carpeta_arte, carpeta_datos, generar, campo in grupos:
        for ruta in sorted(glob.glob(os.path.join(RAIZ_PROYECTO, carpeta_datos, "*.tres"))):
            datos = leer(ruta)
            ruta_svg = os.path.join(RAIZ_PROYECTO, "art", carpeta_arte, datos["id"] + ".svg")
            escribir(ruta_svg, generar(datos))
            nuevo = enlazar_arte(datos, f"res://art/{carpeta_arte}/{datos['id']}.svg", campo)
            print(("enlazado " if nuevo else "regenerado ") + f"{carpeta_arte}/{datos['id']}")


if __name__ == "__main__":
    main()
