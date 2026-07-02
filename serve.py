"""
Servidor HTTP local para probar builds web de Godot.

Godot con thread_support=true (WASM multi-threaded) necesita los headers
Cross-Origin-Opener-Policy y Cross-Origin-Embedder-Policy para activar
SharedArrayBuffer en el navegador. Sin esto el juego no arranca.

Uso:
    python serve.py                    # sirve la carpeta actual en :8000
    python serve.py 8080               # puerto custom
    python serve.py 8000 otra/carpeta  # puerto + carpeta custom

Luego abre http://localhost:8000/ en el navegador.
"""

import http.server
import socketserver
import sys
import os


class GodotHandler(http.server.SimpleHTTPRequestHandler):
    """Sirve ficheros estáticos con los headers que necesita Godot web."""

    def end_headers(self):
        # Necesarios para SharedArrayBuffer (Godot con threads).
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        # Permite cargar recursos cross-origin si los necesitas.
        self.send_header("Cross-Origin-Resource-Policy", "cross-origin")
        # Cache control decente para dev local.
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def log_message(self, fmt, *args):
        # Log más limpio: timestamp + línea.
        sys.stderr.write(f"[serve] {self.address_string()} - {fmt % args}\n")


def main():
    port = 8000
    directory = os.getcwd()

    if len(sys.argv) >= 2:
        try:
            port = int(sys.argv[1])
        except ValueError:
            directory = os.path.abspath(sys.argv[1])
    if len(sys.argv) >= 3:
        directory = os.path.abspath(sys.argv[2])

    os.chdir(directory)

    # Reuse address para no esperar el TIME_WAIT al reiniciar.
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("", port), GodotHandler) as httpd:
        print(f"[serve] Sirviendo {directory}")
        print(f"[serve] Abre http://localhost:{port}/ en el navegador")
        print("[serve] Ctrl+C para parar")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n[serve] Apagado.")


if __name__ == "__main__":
    main()