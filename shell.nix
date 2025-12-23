let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-24.05";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
pkgs.mkShellNoCC {
  packages = with pkgs; [
    just
    lolcat
    inotify-tools
    podman
    podman-compose
    # podman dependencies
    fuse-overlayfs
  ];

  # On shell startup
  shellHook = ''
    # Load environment variables from .env file
    set -a
    source .env
    set +a
  
    # Add environement variables specific to the shell
    export HTTP_EXPOSE_FOLDER=/tmp #/var/www/doxygen/
    export PROCESS_FOLDER=.process #Folder to monitor for process pids
    export LOGS_FOLDER=.logs #Folder to store logs from processes
    mdkir -p $PROCESS_FOLDER $LOGS_FOLDER

    echo "Welcome to the Hylozoa-Engine-Jenkins environment.
      Install the host dependencies for podmap: sudo apt-get install uidmap
      " | lolcat

    # Setup Podman config directory
    export PODMAN_CONFIG_DIR="$PWD/.config/podman"
    export CONTAINERS_CONF="$PODMAN_CONFIG_DIR/containers.conf"
    export CONTAINERS_STORAGE_CONF="$PODMAN_CONFIG_DIR/storage.conf"
    # Add symlinks to the project's config (podman has no env variable for them)
    sudo mkdir -p ~/.config/containers
    sudo ln "$PODMAN_CONFIG_DIR/policy.json" ~/.config/containers/policy.json
    sudo ln "$PODMAN_CONFIG_DIR/registries.conf" ~/.config/containers/registries.conf

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