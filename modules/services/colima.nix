{
  pkgs,
  config,
  ...
}: let
  useVzRosetta = pkgs.stdenv.hostPlatform.isDarwin && pkgs.stdenv.hostPlatform.isAarch64;
  colimaVmType =
    if useVzRosetta
    then "vz"
    else "qemu";
in {
  services.colima = {
    enable = true;
    package = pkgs.colima;

    profiles = {
      default = {
        isService = true;
        isActive = true;
        setDockerHost = true;

        settings = {
          runtime = "docker";
          cpu = 12;
          disk = 40;
          memory = 8;
          arch = "host";
          vmType = colimaVmType;
          rosetta = useVzRosetta;
          network = {
            address = true;
          };

          mounts = [
            {
              location = config.home.homeDirectory;
              writable = true;
            }
          ];
        };
      };

      agent = {
        isService = true;

        # Important: leave both of these false.
        isActive = false;
        setDockerHost = false;

        settings = {
          runtime = "docker";

          cpu = 6;
          disk = 40;
          memory = 8;

          arch = "host";
          vmType = colimaVmType;
          rosetta = useVzRosetta;

          network = {
            address = true;
          };

          # Crucially, don't mount your complete home directory.
          mounts = [
            {
              location = "${config.home.homeDirectory}/Agents";
              writable = true;
            }
            {
              location = "${config.home.homeDirectory}/.herdr/worktrees";
              writable = true;
            }
            {
              location = "${config.home.homeDirectory}/Development/nvbf";
              writable = true;
            }
          ];
        };
      };
    };
  };
}
