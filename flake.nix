{
  description = "Reproducible Nix package and overlay for agent-device";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }: let
    supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-darwin"];
    packageManifest = builtins.fromJSON (builtins.readFile ./package.json);
    version = packageManifest.dependencies.agent-device;

    mkAgentDevice = pkgs:
      assert pkgs.lib.versionAtLeast pkgs.nodejs_22.version "22.12";
        pkgs.buildNpmPackage {
          pname = "agent-device";
          inherit version;

          src = pkgs.lib.cleanSourceWith {
            src = ./.;
            filter = path: type:
              type == "directory"
              || builtins.elem (builtins.baseNameOf path) [
                "package.json"
                "package-lock.json"
              ];
          };

          npmDepsHash = "sha256-pzyLhC7kAlOuF2drOGsf7iHTnxwPvbY9V/pgzjo768A=";
          nodejs = pkgs.nodejs_22;
          dontNpmBuild = true;
          nativeBuildInputs = [pkgs.makeWrapper];

          installPhase = ''
            runHook preInstall

            mkdir -p "$out/bin" "$out/lib"
            cp -R node_modules "$out/lib/node_modules"
            makeWrapper ${pkgs.lib.getExe pkgs.nodejs_22} "$out/bin/agent-device" \
              --add-flags "$out/lib/node_modules/agent-device/bin/agent-device.mjs"

            runHook postInstall
          '';

          doInstallCheck = true;
          installCheckPhase = ''
            runHook preInstallCheck

            test "$("$out/bin/agent-device" --version)" = "${version}"
            "$out/bin/agent-device" help workflow >/dev/null

            runHook postInstallCheck
          '';

          meta = {
            description = packageManifest.description or "Mobile app automation for AI coding agents";
            homepage = "https://agent-device.dev/";
            license = pkgs.lib.licenses.mit;
            mainProgram = "agent-device";
            platforms = supportedSystems;
          };
        };
  in
    flake-utils.lib.eachSystem supportedSystems (
      system: let
        agentDevice = mkAgentDevice nixpkgs.legacyPackages.${system};
        overlayPackages = import nixpkgs {
          inherit system;
          overlays = [self.overlays.default];
        };
      in {
        packages.agent-device = agentDevice;
        packages.default = agentDevice;
        checks.agent-device = agentDevice;
        checks.overlay = overlayPackages.agent-device;
      }
    )
    // {
      overlays.default = final: _: {
        agent-device = mkAgentDevice final;
      };
    };
}
