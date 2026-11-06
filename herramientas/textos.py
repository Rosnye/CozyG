"""Mantiene al día los catálogos de traducción de Brote (solo biblioteca estándar de Python).

El español es el idioma de origen: los textos están escritos en español en las escenas, el
código (`tr("...")`) y los datos (`nombre = "..."`), y cada catálogo `data/idiomas/<idioma>.po`
los traduce. Esta herramienta busca todos esos textos y:

  * añade al catálogo los textos nuevos con la traducción vacía (hasta traducirse se ve el español),
  * conserva las traducciones que ya existen,
  * quita los textos que ya no se usan,
  * lista lo que falta por traducir.

Uso, desde la raíz del proyecto:
    python herramientas/textos.py              actualiza todos los catálogos y lista lo pendiente
    python herramientas/textos.py --comprobar  solo comprueba (código de salida 1 si falta algo)
    python herramientas/textos.py --nuevo fr   crea un catálogo vacío para un idioma nuevo
                                               (después hay que añadirlo a Idioma.SOPORTADOS y
                                               a project.godot, ver docs/idiomas.md)
"""
import glob
import os
import re
import sys

RAIZ = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
CARPETA_PO = os.path.join(RAIZ, "data", "idiomas")
CADENA = r'((?:[^"\\]|\\.)*)'  # contenido de una cadena entre comillas, con escapes
LETRAS = re.compile(r"[A-Za-zÁÉÍÓÚÜáéíóúüñÑ]")

BUSQUEDAS = [
    # (patrón de archivos, expresión regular, banderas)
    ("scenes/*.tscn", r'^(?:text|title|dialog_text|ok_button_text|cancel_button_text|tooltip_text|placeholder_text) = "' + CADENA + '"$', re.M),
    ("scripts/**/*.gd", r'\btr\("' + CADENA + r'"\)', 0),
    ("data/**/*.tres", r'^nombre = "' + CADENA + '"$', re.M),
    ("scripts/tutorial.gd", r'^\tPaso\.\w+: "' + CADENA + '",$', re.M),
    ("data/terrenos.tres", r'&"(\w+)": Color', 0),
]


def buscar_textos():
    """Devuelve { texto en español (con escapes de GDScript): [archivos donde aparece] }."""
    encontrados = {}
    for patron, expresion, banderas in BUSQUEDAS:
        for ruta in sorted(glob.glob(os.path.join(RAIZ, patron), recursive=True)):
            contenido = open(ruta, encoding="utf-8").read()
            relativa = os.path.relpath(ruta, RAIZ).replace("\\", "/")
            for texto in re.findall(expresion, contenido, banderas):
                if LETRAS.search(texto) and texto != "II":
                    encontrados.setdefault(texto, [])
                    if relativa not in encontrados[texto]:
                        encontrados[texto].append(relativa)
    return encontrados


def leer_po(ruta):
    """Devuelve (cabecera, { msgid: msgstr }) con los textos tal cual (escapados)."""
    entradas = {}
    cabecera = None
    msgid = msgstr = None
    destino = None
    for linea in open(ruta, encoding="utf-8").read().splitlines():
        linea = linea.strip()
        if linea.startswith("msgid "):
            if msgid is not None:
                entradas[msgid] = msgstr
            msgid = re.match(r'msgid "' + CADENA + '"', linea).group(1)
            msgstr = ""
            destino = "id"
        elif linea.startswith("msgstr "):
            msgstr = re.match(r'msgstr "' + CADENA + '"', linea).group(1)
            destino = "str"
        elif linea.startswith('"') and destino:
            trozo = re.match('"' + CADENA + '"', linea).group(1)
            if destino == "id":
                msgid += trozo
            else:
                msgstr += trozo
    if msgid is not None:
        entradas[msgid] = msgstr
    cabecera = entradas.pop("", None)
    return cabecera, entradas


def escribir_po(ruta, idioma, cabecera, entradas, referencias):
    lineas = [
        "# Traducciones de Brote. Se mantiene con `python herramientas/textos.py`.",
        "# El español es el idioma de origen: cada msgid es el texto original.",
        'msgid ""',
        'msgstr ""',
        '"Content-Type: text/plain; charset=UTF-8\\n"',
        f'"Language: {idioma}\\n"',
        "",
    ]
    if cabecera is not None and "Language:" in cabecera:
        pass  # la cabecera se regenera igual; no hay datos extra que conservar
    for msgid in sorted(entradas, key=lambda t: (referencias[t][0], t.lower())):
        lineas.append("#: " + ", ".join(referencias[msgid]))
        lineas.append(f'msgid "{msgid}"')
        lineas.append(f'msgstr "{entradas[msgid]}"')
        lineas.append("")
    with open(ruta, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lineas))


def main():
    comprobar = "--comprobar" in sys.argv
    if "--nuevo" in sys.argv:
        idioma = sys.argv[sys.argv.index("--nuevo") + 1]
        ruta = os.path.join(CARPETA_PO, idioma + ".po")
        if os.path.exists(ruta):
            sys.exit(f"Ya existe {ruta}")
        os.makedirs(CARPETA_PO, exist_ok=True)
        textos = buscar_textos()
        escribir_po(ruta, idioma, None, {t: "" for t in textos}, textos)
        print("Creado", os.path.relpath(ruta, RAIZ))

    textos = buscar_textos()
    pendientes_total = 0
    for ruta in sorted(glob.glob(os.path.join(CARPETA_PO, "*.po"))):
        idioma = os.path.splitext(os.path.basename(ruta))[0]
        cabecera, entradas = leer_po(ruta)
        nuevas = [t for t in textos if t not in entradas]
        sobran = [t for t in entradas if t not in textos]
        pendientes = [t for t in textos if not entradas.get(t, "")]
        print(f"[{idioma}] {len(textos)} textos | {len(nuevas)} nuevos | {len(sobran)} sin uso | {len(pendientes)} sin traducir")
        for t in pendientes:
            print(f"    sin traducir: {t}   ({', '.join(textos[t])})")
        pendientes_total += len(pendientes)
        if not comprobar:
            resultado = {t: entradas.get(t, "") for t in textos}
            escribir_po(ruta, idioma, cabecera, resultado, textos)
    if comprobar and pendientes_total:
        sys.exit(1)


if __name__ == "__main__":
    main()
