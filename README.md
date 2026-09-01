# agent-device Nix overlay

This flake packages the published [agent-device](https://agent-device.dev/) npm artifact with
its locked dependency graph and supported Node runtime. It exports `packages.agent-device`,
`packages.default`, and an overlay that adds `pkgs.agent-device`.

Add the flake as an input that follows the consuming repository's `nixpkgs`, then include
`agent-device-overlay.overlays.default` when importing packages. The CLI can then be added to a
development shell as `pkgs.agent-device`.

The locked graph replaces the nested HTTP client inherited through `@limrun/api` with the
non-vulnerable release already used directly by agent-device. The agent-device package itself
remains unchanged.

The package build verifies the installed CLI version and the `help workflow` surface. Run
`nix flake check` to execute those checks.
