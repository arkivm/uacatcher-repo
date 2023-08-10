{
  description = "Build UACatcher";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, }: let
    supportedSystems = [ "x86_64-linux" ];
  in flake-utils.lib.eachSystem supportedSystems (system: let
    pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };
    PROJECT_ROOT = builtins.toString ./.;
    pymake = pkgs.python3Packages.buildPythonPackage rec {
      pname = "pymake";
      version = "1.0.0";
      src = pkgs.fetchFromGitHub {
        owner = "mozilla";
        repo = "pymake";
        rev = "034ae9ea5b726e03647d049147c5dbf688e94aaf";
        sha256 = "0a2f05lqcx972p1graywsim7zc922yygvclipp8jsq60w329rwcs";
      };
      patches = [
        ./patches/fix-imports-with-relative-imports.patch
      ];
      preBuild = "
      cat > setup.py << EOF
from distutils.core import setup
from setuptools import find_packages
setup(name='pymake',
      version='1.0',
      packages=find_packages(),
      )
EOF
      ";
      doCheck = false;
    };

  in rec {
    devShell = pkgs.mkShell {
      buildInputs = with pkgs; [
        # python deps
        python310
        python310Packages.networkx
        python310Packages.termcolor
        python310Packages.tqdm
        pymake

        # kernel deps
        gnumake
        bison
        flex
        libelf
        ncurses
        openssl
        binutils elfutils gettext

        # codeql-bin
        codeql
      ];
    };
  });
}
