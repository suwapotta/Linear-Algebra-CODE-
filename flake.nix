{
  description = "Python (Devshell)";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devshell.url = "github:numtide/devshell";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.devshell.flakeModule ];

      systems = [ "x86_64-linux" ];

      perSystem =
        { pkgs, ... }:

        {
          devshells.default = {
            name = "Python";

            packages = with pkgs; [
              pyright
              python314Packages.debugpy
              ruff
            ];

            env = [
              {
                name = "UV_PYTHON_DOWNLOADS";
                value = "never";
              }
              {
                name = "PATH";
                prefix = "$HOME/.local/bin";
              }
            ];

            devshell.motd = ''
               {45}Welcome to Python.{reset}
              Enter 'menu' for general commands.
            '';
          };
        };
    };
}
