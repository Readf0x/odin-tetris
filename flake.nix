rec {
  description = "Description for the project";
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];
      perSystem = { system, pkgs, lib, ... }: let info = {
        projectName = "tetris";
        dependencies = with pkgs; [
          raylib
        ];
      }; in ({
        projectName,
        dependencies ? [],
        sourceDir ? ".",
        binaryName ? projectName
      }: rec {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            odin
            gnumake
          ] ++ dependencies;
        };
        packages = {
          ${projectName} = pkgs.stdenv.mkDerivation rec {
            pname = projectName;
            version = "0.1";
            src = ./.;

            nativeBuildInputs = with pkgs; [ odin raylib ];
            buildInputs = [];

            DESTDIR = placeholder "out";
            PREFIX = "";

            meta = {
              inherit description;
              homepage = "";
              license = lib.licenses.gpl3Only;
            };
          };
          default = packages.${projectName};
        };
      }) info;
    };
}
