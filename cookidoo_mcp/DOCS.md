# Cookidoo MCP

Inoffizieller MCP-Server für Cookidoo, basierend auf [nodomain/mcp-cookidoo](https://github.com/nodomain/mcp-cookidoo) (MIT). Claude kann damit TM7-Rezepte als „Erstellte Rezepte“ in dein Cookidoo-Konto laden. Der Thermomix holt sie von dort.

Nicht von Vorwerk. Nutzt eine undokumentierte Cookidoo-Schnittstelle, die sich jederzeit ändern kann.

## Einrichtung

1. Konfiguration: Cookidoo-E-Mail und -Passwort eintragen. Land und Sprache stehen auf `de` / `de-DE`.
2. Add-on starten und das Protokoll öffnen.
3. Beim ersten Start steht im Protokoll ein Tailscale-Anmeldelink. Öffnen und den Knoten `cookidoo-mcp` in deinem Tailnet zulassen. Alternativ vorher einen Auth-Key unter `tailscale_authkey` eintragen.
4. Falls Funnel nicht erlaubt ist, steht ein Link im Protokoll. Im Tailscale-Admin müssen HTTPS-Zertifikate und Funnel für den Knoten aktiviert sein.
5. GitHub-Login (Standard, `auth: github`): Auf github.com unter Settings → Developer settings → OAuth Apps eine App anlegen. Homepage-URL `https://<tailscale-name>`, Callback-URL `https://<tailscale-name>/auth/callback` (beides steht im Protokoll). Client-ID und Secret eintragen, unter `allowed_github_users` die erlaubten GitHub-Konten (kommagetrennt).
6. Im Protokoll erscheint die **Connector-URL** (`https://<tailscale-name>/mcp`). Sie in Claude unter Einstellungen → Connectors → „Eigenen Connector hinzufügen“ eintragen. Beim Verbinden meldest du dich mit GitHub an.

## Sicherheit

- Mit `auth: github` kommt nur durch, wer sich mit einem erlaubten GitHub-Konto anmeldet. Die URL selbst ist dann kein Geheimnis.
- Mit `auth: none` enthält die URL einen zufälligen geheimen Pfad. Wer sie kennt, kann in dein Cookidoo-Konto schreiben.
- Neue URL erzwingen: Add-on deinstallieren und neu installieren (das löscht den gespeicherten Pfad und die Tailscale-Anmeldung).
- Der Server lauscht nur auf `127.0.0.1` im Container. Erreichbar ist er ausschließlich über den Tailscale-Funnel dieses Add-ons.

## TM7-Leitfaden

Der Server bringt den TM7-Masterprompt mit (`rootfs/guide/tm7_guide.md`). Jeder Claude-Chat mit diesem Connector bekommt beim Verbinden den Hinweis, zuerst das Tool `get_tm7_guide` aufzurufen, und holt sich den Leitfaden damit selbst. Ein geteiltes Claude-Projekt ist dafür nicht nötig. Änderungen am Leitfaden: Datei im Repo anpassen, Version erhöhen, Add-on aktualisieren.

Die Vorwerk-Gebrauchsanleitung liegt bewusst nicht bei (Urheberrecht, das Repo ist öffentlich). Die nötigen Gerätefakten stehen in eigenen Worten im Leitfaden.
