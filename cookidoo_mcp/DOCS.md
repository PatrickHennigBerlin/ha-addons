# Cookidoo MCP

Inoffizieller MCP-Server für Cookidoo, basierend auf [nodomain/mcp-cookidoo](https://github.com/nodomain/mcp-cookidoo) (MIT). Claude kann damit TM7-Rezepte als „Erstellte Rezepte“ in dein Cookidoo-Konto laden. Der Thermomix holt sie von dort.

Nicht von Vorwerk. Nutzt eine undokumentierte Cookidoo-Schnittstelle, die sich jederzeit ändern kann.

## Einrichtung

1. Konfiguration: Cookidoo-E-Mail und -Passwort eintragen. Land und Sprache stehen auf `de` / `de-DE`.
2. Add-on starten und das Protokoll öffnen.
3. Beim ersten Start steht im Protokoll ein Tailscale-Anmeldelink. Öffnen und den Knoten `cookidoo-mcp` in deinem Tailnet zulassen. Alternativ vorher einen Auth-Key unter `tailscale_authkey` eintragen.
4. Falls Funnel nicht erlaubt ist, steht ein Link im Protokoll. Im Tailscale-Admin müssen HTTPS-Zertifikate und Funnel für den Knoten aktiviert sein.
5. Im Protokoll erscheint die **Connector-URL**. Sie in Claude unter Einstellungen → Connectors → „Eigenen Connector hinzufügen“ eintragen.

## Sicherheit

- Die Connector-URL enthält einen zufälligen geheimen Pfad. Wer sie kennt, kann in dein Cookidoo-Konto schreiben. Behandle sie wie ein Passwort.
- Neue URL erzwingen: Add-on deinstallieren und neu installieren (das löscht den gespeicherten Pfad und die Tailscale-Anmeldung).
- Der Server lauscht nur auf `127.0.0.1` im Container. Erreichbar ist er ausschließlich über den Tailscale-Funnel dieses Add-ons.
