{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";

  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };

  outputs = { self, nixpkgs, ... }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      devShells.x86_64-linux.default = self.packages.x86_64-linux.default;

      packages.x86_64-linux = {
        default = pkgs.stdenv.mkDerivation {
          name = "hound";
          buildInputs = with pkgs; [ flyctl skopeo ];
          src = self;
        };

        config = ./config-generator/hound.json;
      };

      dockerImages.x86_64-linux.default = pkgs.dockerTools.buildLayeredImage {
        name = "search.nix.gsc.io";
        maxLayers = 500;
        config = {
          ExposedPorts."8080/tcp" = { };
          Cmd = [
            (pkgs.writeScript "startup" ''
              #!${pkgs.bash}/bin/bash

              ${pkgs.git}/bin/git config --global --replace-all http.sslCAinfo ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt

              ${pkgs.coreutils}/bin/mkdir /tmp

              ${pkgs.hound}/bin/houndd "$@"
            '')
          ]
          ++ [ "--addr" "[::]:8080" ]
          ++ [ "--conf" "${self.packages.x86_64-linux.config}" ]
          ;
        };
      };
    };
}
