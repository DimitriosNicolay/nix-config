# Hermes Agent HQ

## Installation und Betrieb

`sun` verwendet die Minimalvariante des offiziellen Hermes-Nix-Pakets aus dem in `flake.lock` fixierten Release `v0.23.3`. Sie enthält den Gateway-Dienst, die Webapp und ACP. Die optionale Anthropic-Abhängigkeit entfällt. Hermes und die übrige Host-Konfiguration verwenden ihre jeweils gepinnte `nixpkgs`-Revision. [Hermes-Release](https://github.com/NousResearch/hermes-agent/releases/tag/v0.23.3)

| Installation | Betrieb auf `sun` |
| --- | --- |
| Offizielles NixOS-Modul | Unterstützt den nativen Gateway-Dienst, persistente Profile und reproduzierbare Nix-Updates. OAuth und beschreibbare Skills verwenden den Hermes-Zustand wie bei der lokalen Unit. In der gepinnten Version bearbeitet das Root-Aktivierungsskript Dateien im durch Hermes beschreibbaren Zustand. Es installiert die `.env` dort und markiert die CLI als verwaltet. |
| Offizieller Container | OAuth, Memory und Profile bleiben über das Host-Volume `/opt/data` persistent. Das offizielle Image kann auch im Container Skills installieren und die offiziellen Weboberflächen bereitstellen. Reproduzierbare Updates erfordern einen fixierten Image-Digest. Containergrenzen helfen bei der Isolation, während Zustand, Ports, systemd-Lebenszyklus und OAuth-Aufruf für `sun` separat konfiguriert werden müssten. |
| Offizielles Nix-Paket mit lokaler Unit | Nix liefert eine feste Paketversion und systemd startet einen einzigen Prozess mit der eingebetteten Webapp. Initialisierung, OAuth-Zustand und beschreibbare Skills bleiben unter dem Dienstkonto. Nicht geheime Regeln und Git-Skills kommen aus Nix. SOPS liefert statische Credentials über die Unit. |

Die lokale Unit bleibt bei `v0.23.3` die passende Variante. Sie hält die Schreibvorgänge im Agentenzustand unprivilegiert und verwendet das offizielle Paket für OAuth, Profile, Delegation und Webapp. Bei einem Versionswechsel lässt sich das Upstream-Modul erneut auf diese Eigenschaften prüfen. [NixOS-Integration](https://hermes-agent.nousresearch.com/docs/getting-started/nix-setup) · [Upstream-Modul in v0.23.3](https://github.com/NousResearch/hermes-agent/blob/v0.23.3/nix/nixosModules.nix) · [Offizieller Container](https://hermes-agent.nousresearch.com/docs/user-guide/docker)

`hermes-agent.service` startet beim Boot als Systembenutzer `hermes`. systemd beschränkt den Dienst und seine Kindprozesse auf einen eigenen beschreibbaren Zustand und private temporäre Dateien. Home-Verzeichnisse, `/data`, `/etc/nixos`, fremde SOPS-Secrets und die lokalen Docker- und Nix-Daemon-Sockets sind aus der Unit heraus gesperrt. Der Dienst hat keine zusätzlichen Gruppen oder Linux-Capabilities. Hermes sperrt für Serveragenten Terminal-, Datei-, Codeausführungs-, Browser- und Computerwerkzeuge. Web-Tools dürfen keine privaten URLs abrufen. Ein angemeldeter Betreiber kann über die Webapp mit den Rechten des Dienstkontos arbeiten, daher bleibt dieser Zugang administrativ.

## ChatGPT-OAuth über SSH

Die Managed-Scope-Konfiguration setzt `openai-codex` als Provider. Hermes nutzt dafür die Anmeldung mit deinem ChatGPT-Account. Verfügbare Modelle und Nutzungslimits richten sich nach dem Account und den Workspace-Einstellungen. Der Pfad erfordert keinen OpenAI-API-Key. [Hermes-Provider](https://hermes-agent.nousresearch.com/docs/integrations/providers) · [OpenAI-Partnerverzeichnis](https://learn.chatgpt.com/docs/sign-in-with-chatgpt)

1. Aktiviere die Anmeldung per Gerätecode in den Sicherheitseinstellungen deines ChatGPT-Kontos. Bei einem verwalteten Workspace kann die Freigabe beim Administrator liegen.
2. Öffne nach der freigegebenen NixOS-Aktivierung vom Windows-PC eine interaktive SSH-Sitzung mit `ssh -t reavy@sun`. Führe auf `sun` den folgenden Befehl aus.

   ```bash
   sudo -u hermes -H -- /etc/profiles/per-user/hermes/bin/hermes-hq-auth login
   ```

3. Öffne die ausgegebene OpenAI-Adresse im Windows-Browser, melde dich an und gib den einmaligen Gerätecode ein. Lass die SSH-Sitzung offen, bis Hermes den erfolgreichen Login meldet. Für diesen Flow ist kein Callback-Tunnel nötig.
4. Prüfe auf `sun` den Status. Wähle anschließend in der Webapp ein verfügbares Codex-Modell und sende einen Testprompt.

   ```bash
   sudo -u hermes -H -- /etc/profiles/per-user/hermes/bin/hermes-hq-auth status
   ```

Der Helfer führt beim Login `hermes -p default auth add openai-codex --priority 0` aus. `auth add openai-codex` verwendet in dieser Version standardmäßig den Gerätecode-Flow. Für den optionalen Browser-Flow starte die SSH-Sitzung mit `ssh -t -L 127.0.0.1:1455:127.0.0.1:1455 reavy@sun`. Hänge im `sudo`-Befehl oben `--browser` an `login` an und öffne die ausgegebene Adresse im Windows-Browser. Hermes bindet den registrierten Callback an Port `1455`. Beide Wege benötigen eine im Konto erlaubte Anmeldung. [OAuth über SSH](https://hermes-agent.nousresearch.com/docs/guides/oauth-over-ssh) · [OpenAI-Anmeldung auf headless Geräten](https://developers.openai.com/codex/auth#login-on-headless-devices)

Dienst und Helfer verwenden `HOME=/var/lib/hermes` und `HERMES_HOME=/var/lib/hermes/.hermes`. Der Helfer läuft als `hermes` und übernimmt dieselben nicht geheimen Regeln wie der Dienst. Er bekommt die Dashboard-Credentials nicht. Das Dienstkonto behält seine gesperrte Login-Shell. Hermes speichert seine OAuth-Tokens in `auth.json` mit Modus `0600` und erneuert sie bei Bedarf selbst. Benannte Profile können den Login des Standardprofils verwenden, solange sie für diesen Provider keinen eigenen Eintrag haben. Kopiere die Tokens nicht zwischen Installationen. Nach einem widerrufenen Login oder beim Wiederherstellen einer älteren Kopie führe die Anmeldung erneut aus. [Hermes-Provider und Token-Erneuerung](https://hermes-agent.nousresearch.com/docs/integrations/providers)

## Statische Dashboard-Credentials

`secrets/hermes.yaml` enthält das Dashboard-Passwort `hermes-dashboard-password` und den separaten Signaturschlüssel `hermes-dashboard-session-secret`. Beide Werte sind mit den vorhandenen SOPS-age-Empfängern verschlüsselt. Für die erste Aktivierung muss `sun` mit seinem konfigurierten SSH-Hostschlüssel entschlüsseln können. sops-nix legt die beiden Secrets für root mit Modus `0400` ab und rendert die `.env`-Vorlage. systemd lädt diese Datei und die nicht geheime `config.yaml` über `LoadCredential`. Hermes findet beide über `HERMES_MANAGED_DIR=%d` im Credential-Verzeichnis der Unit. Ein geändertes Dashboard-Secret führt beim Anwenden der Konfiguration zu einem Dienstneustart.

Zum Wechsel der Dashboard-Zugangsdaten editiere `sops secrets/hermes.yaml` mit deinem berechtigten age-Schlüssel und ersetze den gewünschten Wert durch einen neuen unabhängigen Zufallswert. Die Änderung des Signaturschlüssels macht bestehende Dashboard-Anmeldungen ungültig. Weitere statische Zugangsdaten gehören bei Bedarf in SOPS. Der interaktive ChatGPT-Login und seine Token-Erneuerung bleiben davon getrennt.

Der VM-Test hat den Neustart bei einer Secret-Rotation bestätigt. Der aktuell gepinnte NixOS-Stand warnt vor der künftig entfallenden Neustart-Anforderung aus Aktivierungsskripten. Prüfe beim Wechsel auf NixOS 26.11 die systemd-Aktivierung von sops-nix und die Secret-Rotation erneut.

## Webapp öffnen

Lies das Dashboard-Passwort in einer privaten SSH-Sitzung auf `sun` mit `sudo cat /run/secrets/hermes-dashboard-password` aus. Alternativ kannst du es mit `sops decrypt --extract '["hermes-dashboard-password"]' secrets/hermes.yaml` aus deinem eigenen Checkout lesen, wenn dort dein age-Schlüssel verfügbar ist.

Nutze auf dem Entwicklungsrechner den bestehenden SSH-Zugang zu `sun`, vorzugsweise über Tailscale oder im LAN. Falls `sun` nicht auflösbar ist, verwende seine Tailscale-Adresse oder seinen SSH-Hostalias.

```bash
ssh -N -o ExitOnForwardFailure=yes -L 127.0.0.1:9120:127.0.0.1:9120 reavy@sun
```

Öffne `http://hermes.localhost:9120` und melde dich als `hermes` mit dem SOPS-Passwort an. `hermes.localhost` ist ein Loopback-Name auf dem Entwicklungsrechner. Die konfigurierte URL veranlasst Hermes, auch hinter dem Tunnel die Anmeldung zu verlangen. Verwende denselben Hostnamen und Port für den Browserzugriff. Falls die lokale Namensauflösung die `.localhost`-Subdomain nicht unterstützt, ordne `hermes.localhost` auf dem Entwicklungsrechner `127.0.0.1` zu. Caddy und die Firewall erhalten keine Hermes-Freigabe. [Offizielle Webapp-Dokumentation](https://hermes-agent.nousresearch.com/docs/user-guide/desktop) · [RFC 6761](https://www.rfc-editor.org/rfc/rfc6761.html#section-6.3)

Die folgenden Befehle prüfen auf `sun` den Dienst, den Listener und die Anmeldung.

```bash
systemctl status hermes-agent.service
sudo journalctl -u hermes-agent.service -b -n 80
sudo ss -ltnp 'sport = :9120'
curl --resolve hermes.localhost:9120:127.0.0.1 -sS -o /dev/null \
  -w '%{http_code}\n' http://hermes.localhost:9120/api/auth/me
```

Erwartet sind `127.0.0.1:9120` und ohne Browser-Anmeldung der HTTP-Status `401`. Prüfe im Browser die Anmeldung, einen Modellturn und das Wiederöffnen der Sitzung.

## Wissen, Identität und Profile

| Ebene | Ablage und Verwendung |
| --- | --- |
| Global | Allgemeine Konventionen als geprüfte Skills unter `hermes/skills/global`. Nix stellt sie unter `/etc/hermes/shared-skills` schreibgeschützt bereit. |
| Fachgebiet | Bei Bedarf weitere Git-versionierte Fachverzeichnisse ergänzen und sie per `skills.external_dirs` nur den dafür vorgesehenen Profilen zuweisen. |
| Projekt | Architektur und Entscheidungen bleiben in der `AGENTS.md` und der Projektdokumentation des jeweiligen Workspaces. Ein Serverprofil erhält gezielt freigegebenen Projektkontext und kann dafür ein eigenes `SOUL.md` und eigene Skills verwenden. |
| Individuell | Das Standardprofil und jedes benannte Profil speichern eigene Sitzungen, `memories/MEMORY.md`, `memories/USER.md`, Skills und Konfiguration in ihrem jeweiligen Hermes-Home. |

Beginne mit dem Standardprofil. Erstelle später beispielsweise `frontend` für fachlichen Austausch und `website-frontend` als eigenständiges Projektprofil. Verwende bei vertraulichen Vorlagen ein leeres Profil, weil Hermes' Klonfunktion unter anderem Memory, Skills und Zugangsdaten kopieren kann. Profile eignen sich zur Organisation für denselben Betreiber. Das gemeinsame Dienstkonto kann auf alle seine Profilverzeichnisse zugreifen. [Hermes-Profile](https://hermes-agent.nousresearch.com/docs/user-guide/profiles)

Hermes `v0.23.3` liest externe Skill-Verzeichnisse direkt aus der Profil-Konfiguration. Beim Dienststart trägt Hermes deshalb `/etc/hermes/shared-skills` im Standardprofil und den vorhandenen Profilen in `skills.external_dirs` ein. Eigene Einträge bleiben erhalten. Für ein danach neu angelegtes Profil kannst du den Pfad direkt ergänzen oder den Dienst bei Gelegenheit neu starten.

Hermes kann aus Sitzungen neue Skills vorschlagen und bestehende Skills verbessern. `memory.write_approval` und `skills.write_approval` lassen solche Änderungen über die jeweiligen Werkzeuge zur Freigabe vorlegen. Profile können danach in ihrem eigenen, beschreibbaren Skill-Verzeichnis weiterlernen. Prüfe einen übertragbaren Vorschlag mit `review-shared-knowledge`, übernimm den bereinigten `SKILL.md` nach `hermes/skills/global` und nimm ihn in Git auf. Neue Git-Skill-Stände lösen bei der Aktivierung einen Dienstneustart aus. Verwende eindeutige Namen, da ein gleichnamiger Profil-Skill den gemeinsamen Skill überdecken kann. Profil-Memory und Sitzungen bleiben in `/var/lib/hermes`. [Skills](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills) · [Memory](https://hermes-agent.nousresearch.com/docs/user-guide/features/memory)

`delegate_task` kann bis zu zwei Subagenten parallel auf einem Level einsetzen, etwa um einen freigegebenen Entwurf aus zwei Perspektiven prüfen zu lassen. Subagenten erhalten den vom Hauptagenten ausgewählten Kontext und erben dessen gesperrte Toolsets. Die Standardroute verwendet den Provider des Hauptagenten. Benannte Teamprofile und Bot-Chats können später ergänzt werden. Kanban führt hier keine Aufgaben automatisch aus. Für geplante Aufgaben bleibt eine restart-sichere systemd-User-Scope erforderlich. [Delegation](https://hermes-agent.nousresearch.com/docs/user-guide/features/delegation) · [Bot Mode](https://hermes-agent.nousresearch.com/docs/user-guide/bot-mode) · [Kanban](https://hermes-agent.nousresearch.com/docs/user-guide/features/kanban)

## VS Code und ACP

Das gepinnte Paket enthält `hermes acp` und `hermes-acp`. ACP spricht JSON-RPC über stdin/stdout. Die Unit bietet dafür keinen eigenen Listener an. Als Administrator kannst du die Adapter-Imports mit `sudo -u hermes /etc/profiles/per-user/hermes/bin/hermes acp --check` prüfen. [Hermes ACP](https://hermes-agent.nousresearch.com/docs/user-guide/features/acp)

Für lokale Arbeit installierst du auf Windows den ACP Client für VS Code und startest dort ein lokal installiertes `hermes acp` im Projekt-Workspace. Wählst du WSL, starte Editor-Erweiterung und Hermes im selben WSL-Kontext wie das Repository. Damit bleiben Projektdateien, Terminal, Tests und Git auf deinem Entwicklungsrechner. Verwende auf `sun` das passende Projektprofil im Browser für Planung, Review und langlebige Notizen. Übertrage gezielt freigegebene Ausschnitte oder Diffs und verwende geprüfte Git-Skills auf beiden Seiten. Die lokale ACP-Instanz hat ihr eigenes Hermes-Home.

Ein per SSH gestartetes ACP-Programm läuft auf `sun`. Ein vom Editor übermittelter Windows-Pfad vermittelt ihm keinen Dateizugriff. Hermes bindet sein Terminal und seine allgemeinen Dateitools im Adapter an den Workspace seines Ausführungs-Backends. Für eine spätere durchgängige Verbindung von Serverprofil und lokalem Workspace braucht es einen ausdrücklich freigegebenen Client-Adapter, der lokale ACP-Datei- und Terminaloperationen tatsächlich implementiert, sowie eine Prüfung des zusammengesetzten Systems. Der Paketbau bereitet die ACP-Binaries vor. Es gibt hier keine Bridge und keinen SSH-Login für `hermes`. [Hermes ACP-Interna](https://hermes-agent.nousresearch.com/docs/developer-guide/acp-internals) · [ACP-Dateizugriff](https://agentclientprotocol.com/protocol/v1/file-system) · [ACP-Terminals](https://agentclientprotocol.com/protocol/v1/terminals)

Für die NixOS-Konfiguration kann Hermes aus freigegebenem Kontext einen Patch im Chat vorschlagen. Wende ihn im eigenen Checkout an, führe den Build als Betreiber aus und entscheide anschließend über die Aktivierung.

## Persistenz, Backup und Updates

Sichere `/var/lib/hermes` als Ganzes. Darin liegen `.hermes` mit Profilen, Sitzungshistorie, SQLite-Daten, Memory, Skills und dem OAuth-Store sowie `workspace`. Schütze auch ältere verschlüsselte Backup-Stände wie aktuelle Zugangsdaten. Verwende für ein dateibasiertes Backup einen Wartungszeitpunkt mit gestopptem Dienst oder sichere den Zustand per konsistentem Dateisystem-Snapshot. Bewahre Backups verschlüsselt und getrennt vom Host auf. Für die Wiederherstellung benötigst du auch den Git-Stand und einen zur SOPS-Datei passenden age-Schlüssel. Stelle den ersten Test an einem separaten Pfad wieder her und bewahre Eigentümer und Dateirechte.

Für ein Update wählst du in `flake.nix` einen neuen Hermes-Release-Tag und aktualisierst die Eingabe mit `nix flake update hermes-agent`. Prüfe die Änderungen an `flake.lock`, sichere den Zustand vor möglichen Datenbankmigrationen und baue und prüfe `.#sun` nach dem [Ablauf im README](../README.md). Prüfe nach der Freigabe den SSH-Tunnel, den Login, eine bestehende Sitzung und den Zugriff auf den Provider. Hermes-Code und Webapp-Bundle kommen aus dem Nix Store. Skills im privaten Profil bleiben beschreibbar.
