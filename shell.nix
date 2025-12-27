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

  HTTP_EXPOSE_FOLDER = "/var/www/html/doxygen/";
  PROCESS_FOLDER = ".process"; #Folder to monitor for process pids
  LOGS_FOLDER = ".logs"; #Folder to store logs from processes
  DOC_EXTRACTER_GROUP = "hej_doc_extractor"; #Group allowed to access ${HTTP_EXPOSE_FOLDER}

  # On shell startup
  shellHook = ''
    # Load environment variables from .env file
    set -a
    source .env
    set +a
  
    # Add environement variables specific to the shell

    mkdir -p $PROCESS_FOLDER $LOGS_FOLDER

    echo "Welcome to the Hylozoa-Engine-Jenkins environment.
      Install the host dependencies for podmap: sudo apt-get install uidmap
      Make sure nginx is configured to serve the folder: $HTTP_EXPOSE_FOLDER
      " | lolcat

    # Setup Podman config directory
    export PODMAN_CONFIG_DIR="$PWD/.config/podman"
    export CONTAINERS_CONF="$PODMAN_CONFIG_DIR/containers.conf"
    export CONTAINERS_STORAGE_CONF="$PODMAN_CONFIG_DIR/storage.conf"
    # Add symlinks to the project's config (podman has no env variable for them)
    echo "Running checks for podman config..." | lolcat
    if [ ! -d "$PODMAN_CONFIG_DIR" ]; then
      echo "Creating podman config directory at $PODMAN_CONFIG_DIR"
      sudo mkdir --verbose -p "$PODMAN_CONFIG_DIR";
    fi
    if [ ! -f ~/.config/containers/policy.json ]; then
      echo "Linking podman policy.json configuration at ~/.config/containers/policy.json"
      sudo ln --verbose "$PODMAN_CONFIG_DIR/policy.json" ~/.config/containers/policy.json
    else
      echo "Warning: ~/.config/containers/policy.json already exists, not overwriting it. Run 'sudo ln "$PODMAN_CONFIG_DIR/policy.json" ~/.config/containers/policy.json' yourself"
    fi
    if [ ! -f ~/.config/containers/registries.conf ]; then
      echo "Linking podman registries.conf configuration at ~/.config/containers/registries.conf"
      sudo ln --verbose "$PODMAN_CONFIG_DIR/registries.conf" ~/.config/containers/registries.conf
    else
      echo "Warning: ~/.config/containers/registries.conf already exists, not overwriting it. Run 'sudo ln "$PODMAN_CONFIG_DIR/registries.conf" ~/.config/containers/registries.conf' yourself"
    fi

    echo -e "
      [storage]
      driver = \"overlay\"
      runroot = \"$PWD/.containers/run\"
      graphroot = \"$PWD/.containers/storage\"
      [storage.options]
      mount_program = \"$(which fuse-overlayfs)\"
    " > $CONTAINERS_STORAGE_CONF

    echo "Running checks for access to \$HTTP_EXPOSE_FOLDER $HTTP_EXPOSE_FOLDER..." | lolcat
    if [ ! -d "$HTTP_EXPOSE_FOLDER" ]; then
      echo "Creating HTTP expose folder at $HTTP_EXPOSE_FOLDER"
      sudo mkdir --verbose -p $HTTP_EXPOSE_FOLDER;
    fi
    # Check for group access to HTTP_EXPOSE_FOLDER
    if ! getent group "$DOC_EXTRACTER_GROUP" > /dev/null; then
      echo "Creating group $DOC_EXTRACTER_GROUP"
      sudo groupadd "$DOC_EXTRACTER_GROUP"
    fi
    if [ -z "$(stat -c %G "$HTTP_EXPOSE_FOLDER" | grep "$DOC_EXTRACTER_GROUP")" ]; then
      echo "Changing group ownership of $HTTP_EXPOSE_FOLDER to $USER:$DOC_EXTRACTER_GROUP"
      sudo chown --verbose $USER:"$DOC_EXTRACTER_GROUP" "$HTTP_EXPOSE_FOLDER"
    fi
    if [ ! -w "$HTTP_EXPOSE_FOLDER" ]; then
      echo "Warning: Adding $USER to $DOC_EXTRACTER_GROUP group"
      sudo usermod -a -G "$DOC_EXTRACTER_GROUP" "$USER"
    fi

  '';
}