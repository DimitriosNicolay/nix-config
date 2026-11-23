# Gameserver auf `sun`

`machines/sun/configuration.nix` importiert `modules/gameservers/default.nix`. Der Sammelimport ist der Ort für vorhandene Gameserver-Module, sobald ihre Quellen im Checkout vorliegen.

## Valheim-Bestand

Der Ausgangsstand `62cc2e1` auf `main` enthält keinen Valheim-Dienst, Container, Firewall-Eintrag, Datenpfad oder SOPS-Schlüssel. Die Prüfung des aktuellen Checkouts, der lokalen Git-Historie und der GitHub-Refs fand auch keine Originalkonfiguration zum Übernehmen. Die evaluierte Konfiguration stellt keine Valheim-Instanz bereit. Ob beim alten Server die Datenaufbewahrung oder ein Mount an die Aktivierung gekoppelt ist, lässt sich erst an dessen tatsächlicher Startquelle auf `sun` prüfen. [Repository auf GitHub](https://github.com/DimitriosNicolay/nix-config)

Prüfe vor der Aktivierung auf `sun`, ob es einen Dienst, Container oder Listener gibt. Diese Befehle lesen den aktuellen Stand aus.

```bash
systemctl list-unit-files --type=service | grep -i valheim
systemctl list-units --all --type=service | grep -i valheim
sudo docker ps -a --format '{{.Names}} {{.Image}} {{.Ports}}'
sudo ss -lunp
```

Wenn du einen vorhandenen Container findest, zeigt `sudo docker inspect --format '{{json .Mounts}}' <Containername>` seine Daten-Mounts. Bei einem nativen Dienst prüfe den ursprünglichen `-savedir`, den Dienstbenutzer und sein Home. Der Linux-Standard von Valheim ist `~/.config/unity3d/IronGate/Valheim`, wobei `~` dem ausführenden Benutzer gehört. Für `sun` ist der tatsächliche Pfad offen. Die Änderung legt keine Valheim-Datenpfade an und enthält keine Löschregeln für Spielstände, Backups oder Volumes. [Valheim Dedicated Server Guide](https://www.valheimgame.com/support/a-guide-to-dedicated-servers/)

Sichere die ermittelten Datenpfade und prüfe bei einer alten NixOS-Unit in `nixos-rebuild dry-activate --flake .#sun`, ob sie zum Stoppen aufgeführt wird. Bei einer manuell eingerichteten Unit zeigt `systemctl show -p FragmentPath -p DropInPaths <Dienstname>` ihre Quelle. Bei einem eigenständig verwalteten Container zeigt `sudo docker inspect --format '{{.HostConfig.RestartPolicy.Name}} {{index .Config.Labels "com.docker.compose.project.config_files"}}' <Containername>` seine Neustartregel und gegebenenfalls die Compose-Datei. Stoppe eine solche Instanz nach der Sicherung und deaktiviere ihren Start an dieser Quelle. Lass Container und Volumes bestehen. Wiederhole die lesenden Prüfungen nach der Aktivierung, um den Dienst- und Listener-Status zu bestätigen.

## Vorhandenen Server übernehmen und reaktivieren

Übernimm die Originalkonfiguration als `modules/gameservers/valheim.nix` und ergänze sie im Sammelimport. Bewahre Datenpfade, World-Namen, Mounts, Secrets und den bestehenden Dienstbenutzer. Schalte die Unit oder Containerdefinition, ihre Startabhängigkeiten und ihre Firewall-Regeln über denselben `enable`-Schalter. Lass persistente Speichereinstellungen und bestehende Volumes auch im deaktivierten Zustand erhalten. Nach der Prüfung kannst du die Originalinstanz über diesen Schalter reaktivieren.

Leite die Firewall-Regeln aus dem Originalmodul ab. Im Steam-Standard nutzt Valheim UDP `2456` und `2457`. Bei abweichendem `-port` sind es der gewählte Port und der Folgeport. Crossplay nutzt einen Relay-Dienst und benötigt laut Hersteller keine Router-Portweiterleitung. Prüfe zusätzlich eventuelle alte Weiterleitungen im Router, da sie außerhalb der NixOS-Konfiguration liegen. [Valheim Dedicated Server Guide](https://www.valheimgame.com/support/a-guide-to-dedicated-servers/)
