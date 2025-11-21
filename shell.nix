let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-24.05";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
pkgs.mkShellNoCC {
  packages = with pkgs; [
    just
    lolcat
    podman
    podman-compose
    # podman dependencies
    fuse-overlayfs
  ];

  # On shell startup
  shellHook = ''
    echo "Welcome to the Hylozoa-Engine-Jenkins environment.
      Install the host dependencies for podmap: sudo apt-get install uidmap
      " | lolcat

    # Setup Podman config directory
    export PODMAN_CONFIG_DIR="$PWD/.config/podman"
    export CONTAINERS_CONF="$PODMAN_CONFIG_DIR/containers.conf"
    export CONTAINERS_STORAGE_CONF="$PODMAN_CONFIG_DIR/storage.conf"
    # Overwrite the current policy with a symlink to the project's (podman has no env variable for the policy config)
    sudo mkdir -p /etc/containers \
    && sudo ln "$PODMAN_CONFIG_DIR/policy.json" /etc/containers/policy.json

    echo -e "
      [storage]
      driver = \"overlay\"
      runroot = \"$PWD/.containers/run\"
      graphroot = \"$PWD/.containers/storage\"
      [storage.options]
      mount_program = \"$(which fuse-overlayfs)\"
    " > $CONTAINERS_STORAGE_CONF

  '';
}