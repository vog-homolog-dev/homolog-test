#!/bin/bash
# Clone local do phishing gov.br
# Servidor com suporte SPA (todas rotas -> index.html)
PORT=${1:-8080}
echo "=== Phishing gov.br CLONE ==="
echo "Acesse: http://localhost:$PORT"
echo "Rotas: / , /verificacao , /pagamento , /pix/:token , /admin , /admin/painel"
echo ""
python3 -c "
import http.server
import os

class SPAHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        path = self.path.split('?')[0]
        file_path = '.' + path
        if os.path.isfile(file_path) and not path.endswith('/'):
            return super().do_GET()
        self.path = '/index.html'
        return super().do_GET()

http.server.HTTPServer(('0.0.0.0', $PORT), SPAHandler).serve_forever()
"
