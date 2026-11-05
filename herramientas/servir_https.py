"""Sirve la versión web de Brote por HTTPS en tu red local, para probarla en el móvil.

Godot en el navegador exige un "contexto seguro" (HTTPS o localhost), así que el
`python -m http.server` normal no basta desde otro dispositivo.

Uso, desde la raíz del proyecto (después de exportar a build/web):
    python herramientas/servir_https.py

Crea un certificado autofirmado en build/certificado/ (necesita `openssl`, que viene con
Git para Windows) y escribe la dirección que debes abrir en el móvil. El navegador avisará
de que el certificado no es de confianza: es el tuyo, en tu red; pulsa "Avanzado" y
"Continuar". Para parar: Ctrl+C.
"""
import functools
import http.server
import os
import shutil
import socket
import ssl
import subprocess
import sys

RAIZ = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
CARPETA_WEB = os.path.join(RAIZ, "build", "web")
CARPETA_CERT = os.path.join(RAIZ, "build", "certificado")
CERT = os.path.join(CARPETA_CERT, "cert.pem")
CLAVE = os.path.join(CARPETA_CERT, "clave.pem")
PUERTO = int(sys.argv[1]) if len(sys.argv) > 1 else 8443


def ip_local():
    """La IP de este PC en la red local (la que usa para salir a internet)."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("10.255.255.255", 1))
        return s.getsockname()[0]
    except OSError:
        return "127.0.0.1"
    finally:
        s.close()


def buscar_openssl():
    encontrado = shutil.which("openssl")
    if encontrado:
        return encontrado
    for ruta in (r"C:\Program Files\Git\usr\bin\openssl.exe", r"C:\Program Files\Git\mingw64\bin\openssl.exe"):
        if os.path.exists(ruta):
            return ruta
    return None


def asegurar_certificado(ip):
    if os.path.exists(CERT) and os.path.exists(CLAVE):
        return
    openssl = buscar_openssl()
    if openssl is None:
        sys.exit("No encuentro `openssl`. Instala Git para Windows (incluye openssl) y vuelve a intentarlo.")
    os.makedirs(CARPETA_CERT, exist_ok=True)
    subprocess.run(
        [openssl, "req", "-x509", "-newkey", "rsa:2048", "-nodes", "-days", "60",
         "-keyout", CLAVE, "-out", CERT, "-subj", "/CN=brote-local",
         "-addext", f"subjectAltName=IP:{ip},IP:127.0.0.1,DNS:localhost"],
        check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )
    print("Certificado creado en", CARPETA_CERT)


def main():
    if not os.path.exists(os.path.join(CARPETA_WEB, "index.html")):
        sys.exit("No hay build/web/index.html. Exporta primero el juego a Web (Proyecto > Exportar > Web).")
    ip = ip_local()
    asegurar_certificado(ip)
    manejador = functools.partial(http.server.SimpleHTTPRequestHandler, directory=CARPETA_WEB)
    servidor = http.server.ThreadingHTTPServer(("0.0.0.0", PUERTO), manejador)
    contexto = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    contexto.load_cert_chain(CERT, CLAVE)
    servidor.socket = contexto.wrap_socket(servidor.socket, server_side=True)
    print(f"\nAbre en el móvil (misma red Wi-Fi):  https://{ip}:{PUERTO}/")
    print("El navegador avisará del certificado: pulsa Avanzado > Continuar.")
    print("Ctrl+C para parar.\n")
    try:
        servidor.serve_forever()
    except KeyboardInterrupt:
        print("\nServidor parado.")


if __name__ == "__main__":
    main()
