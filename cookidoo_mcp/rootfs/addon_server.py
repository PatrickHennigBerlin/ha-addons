"""Startet den Cookidoo-MCP-Server für das Home-Assistant-Add-on.

Zwei Zugangsarten:
- auth=github: Login mit GitHub (OAuth). Nur die eingetragenen GitHub-Konten
  kommen durch. MCP-Endpunkt ist /mcp.
- auth=none: kein Login, der Endpunkt liegt unter einem geheimen Pfad
  /<pfad-geheimnis>/mcp. Wer die URL kennt, hat Zugriff.
"""

import logging
import os
import sys

import uvicorn

sys.path.insert(0, "/opt/mcp-cookidoo")
os.environ.setdefault("COOKIDOO_MCP_MODE", "stdio")  # server.py soll keine eigene App bauen

import server  # noqa: E402

log = logging.getLogger("cookidoo_addon")

AUTH_MODE = os.environ.get("ADDON_AUTH", "github")
PORT = int(os.environ.get("ADDON_PORT", "8001"))


def build_github_auth():
    from fastmcp.server.auth.providers.github import GitHubProvider

    allowed = {
        u.strip().lower()
        for u in os.environ.get("ADDON_ALLOWED_GITHUB_USERS", "").split(",")
        if u.strip()
    }
    if not allowed:
        sys.exit("Keine erlaubten GitHub-Nutzer eingetragen (allowed_github_users).")

    class AllowlistGitHubProvider(GitHubProvider):
        """Lässt nur die eingetragenen GitHub-Konten durch, alle anderen werden abgewiesen."""

        async def load_access_token(self, token):
            access = await super().load_access_token(token)
            if access is None:
                return None
            claims = access.claims or {}
            login = str(claims.get("login") or "").lower()
            if login and login in allowed:
                return access
            log.warning(
                "Zugriff verweigert für GitHub-Konto %r (Claims: %s)",
                login or None,
                sorted(claims.keys()),
            )
            return None

    return AllowlistGitHubProvider(
        client_id=os.environ["ADDON_GITHUB_CLIENT_ID"],
        client_secret=os.environ["ADDON_GITHUB_CLIENT_SECRET"],
        base_url=os.environ["ADDON_PUBLIC_URL"],
        jwt_signing_key=os.environ["ADDON_JWT_KEY"],
    )


GUIDE_PATH = os.environ.get("ADDON_GUIDE_PATH", "/guide/tm7_guide.md")

server.mcp.instructions = (
    "Cookidoo-Connector für einen Thermomix TM7. Bevor du ein Rezept für den TM7 "
    "ausarbeitest, umwandelst oder hochlädst, rufe zuerst das Tool get_tm7_guide auf und "
    "befolge den Leitfaden darin vollständig. Er enthält die Gerätefakten des TM7, "
    "Sicherheitsregeln, das Ausgabeformat und das Schrittformat für den Cookidoo-Upload. "
    "Lade Rezepte erst nach ausdrücklicher Zustimmung des Nutzers hoch."
)


def _read_guide() -> str:
    with open(GUIDE_PATH, encoding="utf-8") as f:
        return f.read()


@server.mcp.tool()
def get_tm7_guide() -> str:
    """Leitfaden für TM7-Rezepte (Markdown). Vor jedem TM7-Rezept zuerst aufrufen und befolgen."""
    return _read_guide()


@server.mcp.resource("guide://tm7", name="TM7-Leitfaden", mime_type="text/markdown")
def tm7_guide_resource() -> str:
    """Gerätefakten, Regeln und Upload-Format für TM7-Rezepte."""
    return _read_guide()


if AUTH_MODE == "github":
    server.mcp.auth = build_github_auth()
    mcp_path = "/mcp"
else:
    mcp_path = f"/{os.environ['ADDON_PATH_SECRET']}/mcp"

app = server.mcp.http_app(
    path=mcp_path,
    transport="streamable-http",
    stateless_http=True,
    json_response=True,
    host_origin_protection=None,
)

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=PORT, proxy_headers=True, forwarded_allow_ips="127.0.0.1")
