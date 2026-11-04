"""Genera los sonidos provisionales de Brote (solo biblioteca estándar de Python).

Uso, desde la raíz del proyecto:
    python herramientas/generar_sonidos.py

Escribe en art/sonidos/ los efectos de encaje y colocación, y en art/sonidos/ambiente/
las seis capas de música y ambiente. Las capas duran 16 s y están hechas para repetirse
sin cortes. Cuando haya sonido definitivo, basta con reemplazar los .wav.
"""
import math
import os
import random
import struct
import wave

SR = 22050
DURACION_CAPA = 16  # segundos
N = SR * DURACION_CAPA
RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "art", "sonidos")


def guardar(ruta, muestras, pico=0.85):
    maximo = max(abs(v) for v in muestras) or 1.0
    escala = pico / maximo
    os.makedirs(os.path.dirname(ruta), exist_ok=True)
    with wave.open(ruta, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, v * escala)) * 32000)) for v in muestras))


def cruzar_extremos(muestras, cruce):
    """Hace que el final enlace con el principio fundiendo los últimos `cruce` muestras."""
    n = len(muestras) - cruce
    salida = muestras[:n]
    for i in range(cruce):
        t = i / cruce
        salida[i] = muestras[i] * t + muestras[n + i] * (1 - t)
    return salida


def ciclos_enteros(frecuencia):
    """Ajusta la frecuencia para que quepa un número entero de ciclos en la capa."""
    return round(frecuencia * DURACION_CAPA) / DURACION_CAPA


# --- Efectos --------------------------------------------------------------

def nota(frec, dur, vol, ataque=0.01, caida=6.0):
    salida = []
    for i in range(int(dur * SR)):
        t = i / SR
        env = min(1.0, t / ataque) * math.exp(-caida * t)
        salida.append(vol * env * (math.sin(2 * math.pi * frec * t) + 0.25 * math.sin(4 * math.pi * frec * t)) / 1.25)
    return salida


def mezclar(partes):
    total = max(int(ini * SR) + len(m) for ini, m in partes)
    buf = [0.0] * total
    for ini, m in partes:
        o = int(ini * SR)
        for i, v in enumerate(m):
            buf[o + i] += v
    return buf


# --- Capas de ambiente ----------------------------------------------------

def capa_base():
    """Colchón suave de acordes (La menor con novena), ciclos enteros."""
    notas = [(110.0, 0.5), (164.8, 0.35), (220.0, 0.3), (277.2, 0.18), (329.6, 0.15)]
    salida = [0.0] * N
    for k, (frec, amp) in enumerate(notas):
        f = ciclos_enteros(frec)
        f_lento = 1.0 / DURACION_CAPA * (k + 1)  # vaivén lento, también en ciclos enteros
        for i in range(N):
            t = i / SR
            salida[i] += amp * math.sin(2 * math.pi * f * t) * (0.7 + 0.3 * math.sin(2 * math.pi * f_lento * t + k))
    return salida


def capa_melodia():
    """Notas sueltas de campana en escala pentatónica; las colas dan la vuelta al principio."""
    azar = random.Random(11)
    escala = [440.0, 523.25, 587.33, 659.25, 783.99, 880.0]
    salida = [0.0] * N
    t_nota = 0.8
    while t_nota < DURACION_CAPA - 0.5:
        frec = azar.choice(escala)
        inicio = int(t_nota * SR)
        for i, v in enumerate(nota(frec, 3.0, 0.5, ataque=0.02, caida=1.8)):
            salida[(inicio + i) % N] += v
        t_nota += azar.uniform(1.6, 3.4)
    return salida


def ruido_filtrado(semilla, paso_pasa_bajos, pasa_altos=0.0):
    azar = random.Random(semilla)
    cruce = SR // 2
    bajo = 0.0
    alto_prev_in = 0.0
    alto = 0.0
    bruto = []
    for _ in range(N + cruce):
        x = azar.uniform(-1, 1)
        bajo += paso_pasa_bajos * (x - bajo)
        alto = pasa_altos * (alto + bajo - alto_prev_in) if pasa_altos else bajo
        alto_prev_in = bajo
        bruto.append(alto)
    return cruzar_extremos(bruto, cruce)


def capa_agua():
    """Arroyo: ruido grave con burbujeo lento."""
    base = ruido_filtrado(21, 0.12)
    f1, f2 = 3.0 / DURACION_CAPA, 5.0 / DURACION_CAPA
    return [v * (0.6 + 0.25 * math.sin(2 * math.pi * f1 * i / SR) + 0.15 * math.sin(2 * math.pi * f2 * i / SR + 1.3))
            for i, v in enumerate(base)]


def capa_lluvia():
    """Lluvia suave: ruido más agudo y constante."""
    base = ruido_filtrado(33, 0.6, pasa_altos=0.92)
    return [v * (0.85 + 0.15 * math.sin(2 * math.pi * 2.0 / DURACION_CAPA * i / SR)) for i, v in enumerate(base)]


def capa_aves():
    """Gorjeos cortos con barrido de frecuencia, en grupos."""
    azar = random.Random(5)
    salida = [0.0] * N
    t_grupo = 0.6
    while t_grupo < DURACION_CAPA - 1.5:
        base = azar.uniform(2600, 3800)
        for k in range(azar.randint(2, 4)):
            inicio = int((t_grupo + k * 0.17) * SR)
            dur = int(0.11 * SR)
            fase = 0.0
            for i in range(dur):
                u = i / dur
                frec = base + 900 * math.sin(math.pi * u) * (1 if k % 2 == 0 else -1)
                fase += 2 * math.pi * frec / SR
                salida[inicio + i] += math.sin(fase) * math.sin(math.pi * u) ** 2 * 0.6
        t_grupo += azar.uniform(2.2, 4.5)
    return salida


def capa_grillos():
    """Grillos: ráfagas de tres pulsos agudos cada 0,5 s (encaja en 16 s)."""
    salida = [0.0] * N
    f = 4300.0
    for i in range(N):
        t = i / SR
        en_rafaga = t % 0.5
        pulso = 0.0
        for k in range(3):
            d = en_rafaga - k * 0.07
            if 0 <= d < 0.04:
                pulso = math.sin(math.pi * d / 0.04)
        modulacion = 0.6 + 0.4 * math.sin(2 * math.pi * 2.0 / DURACION_CAPA * t)
        salida[i] = pulso * modulacion * math.sin(2 * math.pi * f * t)
    return salida


def main():
    guardar(os.path.join(RAIZ, "encaje.wav"), mezclar([(0.0, nota(659.25, 0.7, 0.5)), (0.11, nota(880.0, 0.8, 0.5))]))
    guardar(os.path.join(RAIZ, "colocar.wav"), nota(261.63, 0.25, 0.5, caida=14))
    capas = {
        "base": capa_base, "melodia": capa_melodia, "agua": capa_agua,
        "aves": capa_aves, "grillos": capa_grillos, "lluvia": capa_lluvia,
    }
    for nombre, generar in capas.items():
        ruta = os.path.join(RAIZ, "ambiente", nombre + ".wav")
        guardar(ruta, generar())
        print("escrito", os.path.normpath(ruta))


if __name__ == "__main__":
    main()
