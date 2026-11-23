# NixOS auf `sun`

- [Hermes Agent HQ](docs/hermes.md) mit Webapp, SOPS, Profilen und VS Code.
- [Gameserver](docs/gameservers.md) mit dem Stand von Valheim und den Schritten zur Übernahme seiner Konfiguration.

## Konfiguration prüfen und aktivieren

Nimm alle neuen Dateien einschließlich `secrets/hermes.yaml` und der Skill-Registrierung in den Commit auf. Git-basierte Nix-Flakes sehen nur Dateien, die Git kennt. Die Dashboard-Zugangsdaten liegen in SOPS. Die [Hermes-Anleitung](docs/hermes.md) beschreibt den SSH-Tunnel und die erstmalige Anmeldung mit deinem ChatGPT-Konto.

Die folgenden Befehle führst du auf `sun` im bestehenden Checkout aus.

```bash
git pull --ff-only
git status --short
nix flake check --no-update-lock-file
nixos-rebuild build --flake .#sun
nix store diff-closures /run/current-system ./result
sudo nixos-rebuild dry-activate --flake .#sun
```

Prüfe die geplanten Dienständerungen und den [Valheim-Bestand](docs/gameservers.md), bevor du aktivierst. Falls du gerade noch einen laufenden Valheim-Dienst aus einer älteren Konfiguration findest, ermittle seine Quelle und sichere die Worlds und Volumes zuerst.

Mit deiner Freigabe kannst du die gebaute Konfiguration aktivieren und den Hermes-Dienst prüfen.

```bash
sudo nixos-rebuild switch --flake .#sun
systemctl status hermes-agent.service
sudo journalctl -u hermes-agent.service -b --no-pager -n 80
```

Richte anschließend [ChatGPT-OAuth](docs/hermes.md#chatgpt-oauth-über-ssh) ein, prüfe die [Webapp](docs/hermes.md#webapp-öffnen) und wiederhole die lesende [Valheim-Prüfung](docs/gameservers.md#valheim-bestand). Bei Bedarf kannst du die vorige NixOS-Generation mit `sudo nixos-rebuild switch --rollback` wieder aktivieren. Laufzeitdaten unter `/var/lib/hermes` bleiben beim Generationswechsel erhalten.
