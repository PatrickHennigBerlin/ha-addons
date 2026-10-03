"""Startet den Cookidoo-MCP-Server für das Home-Assistant-Add-on.

Der MCP-Endpunkt liegt unter /<pfad-geheimnis>/mcp. Nur dieser Pfad wird
bedient, alles andere liefert 404. Das Geheimnis im Pfad ist der Zugangsschutz,
weil Claude-Connectors keinen festen Authorization-Header mitschicken können.
"""

import os
import sys

import uvicorn

sys.path.insert(0, "/opt/mcp-cookidoo")

os.environ.setdefault("COOKIDOO_MCP_MODE", "stdio")  # server.py soll keine eigene App bauen

import server  # noqa: E402  (aus /opt/mcp-cookidoo)

secret = os.environ["ADDON_PATH_SECRET"]
port = int(os.environ.get("ADDON_PORT", "8001"))

app = server.mcp.http_app(
    path=f"/{secret}/mcp",
    transport="streamable-http",
    stateless_http=True,
    json_response=True,
    host_origin_protection=None,
)

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=port, proxy_headers=True, forwarded_allow_ips="127.0.0.1")
