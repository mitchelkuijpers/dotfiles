{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  home = config.home.homeDirectory;
  omp = inputs.omp-agents.packages.${pkgs.stdenv.hostPlatform.system}.omp;
  brokerUrl = "http://127.0.0.1:18765";
  serviceEnv = {
    HOME = home;
    # OMP resolves its database, config and token files beneath ~/.omp.
    # This affects only these launchd processes, never Pi's environment.
    PI_CONFIG_DIR = ".omp";
  };
  waitForBroker = pkgs.writeShellScript "omp-auth-gateway-start" ''
    set -eu
    attempt=0
    while [ "$attempt" -lt 30 ]; do
      attempt=$((attempt + 1))
      if /usr/bin/curl --silent --fail --max-time 2 ${brokerUrl}/v1/healthz >/dev/null; then
        exec ${omp}/bin/omp auth-gateway serve --bind=127.0.0.1:18766
      fi
      /bin/sleep 2
    done
    echo "OMP auth broker at ${brokerUrl} did not become healthy" >&2
    exit 1
  '';
in {
  launchd.agents = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    omp-auth-broker = {
      enable = true;
      config = {
        Label = "org.nix-community.home.omp-auth-broker";
        ProgramArguments = [
          "${omp}/bin/omp"
          "auth-broker"
          "serve"
          "--bind=127.0.0.1:18765"
        ];
        WorkingDirectory = home;
        EnvironmentVariables = serviceEnv;
        StandardOutPath = "${home}/Library/Logs/omp-auth-broker.log";
        StandardErrorPath = "${home}/Library/Logs/omp-auth-broker.error.log";
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 30;
      };
    };
    omp-auth-gateway = {
      enable = true;
      config = {
        Label = "org.nix-community.home.omp-auth-gateway";
        ProgramArguments = ["${waitForBroker}"];
        WorkingDirectory = home;
        EnvironmentVariables = serviceEnv // {OMP_AUTH_BROKER_URL = brokerUrl;};
        StandardOutPath = "${home}/Library/Logs/omp-auth-gateway.log";
        StandardErrorPath = "${home}/Library/Logs/omp-auth-gateway.error.log";
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 30;
      };
    };
  };
}
