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

    profiles.default = {
      isService = true;
      isActive = true;
      setDockerHost = true;

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

        mounts = [
          {
            location = config.home.homeDirectory;
            writable = true;
          }
        ];
      };
    };
  };
}
