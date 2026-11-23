{ config, inputs, lib, pkgs, ... }:

let
  cfg = config.services.hermesHQ;
  hermes = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.minimal;
  stateDir = "/var/lib/hermes";
  hermesHome = "${stateDir}/.hermes";
  workspace = "${stateDir}/workspace";
  sharedSkills = "${../hermes/skills/global}";
  sharedSkillsPath = "/etc/hermes/shared-skills";
  skillConfigPython = pkgs.python3.withPackages (ps: [ ps.ruamel-yaml ]);
  sopsUnits = lib.optional config.sops.useSystemdActivation
    "sops-install-secrets.service";
  managedConfig = (pkgs.formats.yaml { }).generate "hermes-managed-config.yaml" {
    webapp = {
      enabled = true;
      host = "127.0.0.1";
      port = 9120;
      # Engage Hermes sign-in even though the listener is on loopback.
      public_url = "http://hermes.localhost:9120";
    };
    dashboard = {
      basic_auth.username = "hermes";
      session_token_auth.enabled = false;
    };
    terminal = {
      backend = "local";
      cwd = workspace;
    };
    # Project tools run on the developer workstation. Keep the server agent's
    # learning writes in the memory and skill tools with their approval gates.
    agent.disabled_toolsets = [
      "terminal"
      "file"
      "code_execution"
      "browser"
      "computer_use"
      "desktop_ui"
    ];
    delegation = {
      backend = "default";
      max_concurrent_children = 2;
      max_spawn_depth = 1;
      inherit_mcp_toolsets = false;
    };
    memory.write_approval = true;
    skills = {
      write_approval = true;
      inline_shell = false;
      guard_agent_created = true;
    };
    model = {
      provider = "openai-codex";
      openai_runtime = "auto";
    };
    fallback_providers = [ ];
    auth = {
      adopt_external_logins = false;
      codex_login_flow = "device_code";
    };
    security = {
      allow_lazy_installs = false;
      allow_private_urls = false;
    };
    cron.require_restart_safe_scope = true;
    kanban.dispatch_in_gateway = false;
  };
  authCommand = pkgs.writeShellScriptBin "hermes-hq-auth" ''
    set -eu
    umask 077
    if [ "$(${pkgs.coreutils}/bin/id -un)" != hermes ]; then
      echo 'Run this command as the hermes user with sudo -u hermes -H.' >&2
      exit 1
    fi
    export HERMES_HOME=${hermesHome}
    export HERMES_MANAGED_DIR=/etc/hermes/managed
    case "$*" in
      login) set -- auth add openai-codex --priority 0 ;;
      'login --browser') set -- auth add openai-codex --priority 0 --browser ;;
      status) set -- auth status openai-codex ;;
      *) echo 'Usage: hermes-hq-auth {login [--browser]|status}' >&2; exit 2 ;;
    esac
    exec ${lib.getExe hermes} -p default "$@"
  '';
in
{
  options.services.hermesHQ.enable = lib.mkEnableOption "the Hermes Agent gateway on sun";

  config = lib.mkIf cfg.enable {
    environment.etc."hermes/shared-skills".source = sharedSkills;
    environment.etc."hermes/managed/config.yaml".source = managedConfig;

    users.groups.hermes = { };
    users.users.hermes = {
      isSystemUser = true;
      group = "hermes";
      home = stateDir;
      packages = [ hermes authCommand ];
    };

    sops.secrets = lib.genAttrs [ "hermes-dashboard-password" "hermes-dashboard-session-secret" ] (_: {
      sopsFile = ../secrets/hermes.yaml;
      owner = "root";
      mode = "0400";
    });

    sops.templates."hermes-dashboard.env" = {
      owner = "root";
      mode = "0400";
      restartUnits = [ "hermes-agent.service" ];
      content = ''
        HERMES_DASHBOARD_BASIC_AUTH_USERNAME=hermes
        HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=${config.sops.placeholder.hermes-dashboard-password}
        HERMES_DASHBOARD_BASIC_AUTH_SECRET=${config.sops.placeholder.hermes-dashboard-session-secret}
      '';
    };

    systemd.services.hermes-agent = {
      description = "Hermes Agent gateway and Webapp";
      wantedBy = [ "multi-user.target" ];
      restartTriggers = [ managedConfig sharedSkills ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ] ++ sopsUnits;
      requires = sopsUnits;

      environment = {
        HOME = stateDir;
        HERMES_HOME = hermesHome;
        HERMES_MANAGED_DIR = "%d";
        SHELL = lib.getExe pkgs.bashInteractive;
      };
      path = [ hermes pkgs.bash pkgs.coreutils pkgs.git ];
      preStart = ''
        mkdir -p -- ${workspace}
        # v0.23.3 discovers external skills from the raw profile config.
        ${lib.getExe skillConfigPython} ${../hermes/register-shared-skills.py} "$HERMES_HOME" ${sharedSkillsPath}
      '';

      serviceConfig = {
        User = "hermes";
        Group = "hermes";
        StateDirectory = "hermes";
        StateDirectoryMode = "0700";
        WorkingDirectory = stateDir;
        UMask = "0077";
        LoadCredential = [
          "config.yaml:${managedConfig}"
          ".env:${config.sops.templates."hermes-dashboard.env".path}"
        ];
        ExecStart = "${lib.getExe hermes} gateway run";
        # Hermes treats SIGINT as a planned stop and saves resumable sessions.
        KillSignal = "SIGINT";
        Restart = "on-failure";
        RestartSec = "5s";

        NoNewPrivileges = true;
        CapabilityBoundingSet = "";
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectControlGroups = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectKernelLogs = true;
        ProtectProc = "invisible";
        RestrictNamespaces = true;
        RestrictSUIDSGID = true;
        InaccessiblePaths = [
          "-/data"
          "-/etc/nixos"
          "-/etc/ssh"
          "-/run/secrets"
          "-/run/secrets.d"
          "-/run/docker.sock"
          "-/run/podman"
          "-/run/tailscale"
          "-/nix/var/nix/daemon-socket"
          "-/var/lib/docker"
        ];
      };
    };
  };
}
