{
  description = "kuori, a Quickshell desktop shell for Hyprland";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAll = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAll (pkgs: rec {
        kuori = pkgs.callPackage ./nix/package.nix { };
        default = kuori;
      });

      overlays.default = final: _prev: {
        kuori = final.callPackage ./nix/package.nix { };
      };

      # builds the package from the importing system's own pkgs, not this flake's
      # nixpkgs -- see nix/package.nix for why that matters.
      nixosModules = rec {
        kuori = ./nix/module.nix;
        default = kuori;
      };

      devShells = forAll (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.quickshell

            # qmlls and qmllint
            pkgs.kdePackages.qtdeclarative
            (pkgs.python3.withPackages (ps: [ ps.jeepney ]))
            pkgs.imagemagick
            pkgs.wtype
          ];
        };
      });

      checks = forAll (pkgs: {
        package = self.packages.${pkgs.stdenv.hostPlatform.system}.kuori;

        # evaluates the module with every option on and builds what it writes,
        # without building a whole system.
        module =
          let
            system = nixpkgs.lib.nixosSystem {
              inherit (pkgs.stdenv.hostPlatform) system;
              modules = [
                self.nixosModules.default
                {
                  programs.kuori = {
                    enable = true;
                    calendar.enable = true;
                  };
                  programs.hyprland.enable = true;
                  boot.loader.grub.enable = false;
                  fileSystems."/" = {
                    device = "nodev";
                    fsType = "tmpfs";
                  };
                  system.stateVersion = "26.05";
                }
              ];
            };
          in
          pkgs.linkFarm "kuori-module-check" [
            {
              name = "kuori.service";
              path = system.config.systemd.user.units."kuori.service".unit;
            }
            {
              name = "kuori-calendar.service";
              path = system.config.systemd.user.units."kuori-calendar.service".unit;
            }
            {
              name = "pam.d-kuori";
              path = system.config.environment.etc."pam.d/kuori".source;
            }
          ];
      });

      formatter = forAll (pkgs: pkgs.nixfmt-tree);
    };
}
