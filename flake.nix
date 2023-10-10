{
  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.533189.tar.gz";

  inputs.flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.0.1.tar.gz";

  outputs = { self, nixpkgs, ... }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      devShells.x86_64-linux.default = self.packages.x86_64-linux.default;

      packages.x86_64-linux = {
        default = pkgs.stdenv.mkDerivation {
          name = "hound";
          buildInputs = with pkgs; [
            flyctl
            skopeo
            (python3.withPackages (pp: [ pp.requests ]))
          ];
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
              ${pkgs.coreutils}/bin/ls -la / /data /tmp

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
