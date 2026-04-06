folder("/Tools") {
    description("Folder for miscellaneous tools.")
}

freeStyleJob('/doxygen-expose') {
    parameters {
        stringParam('GITHUB_NAME',
                    'Julian52575/Hylozoa-Engine-Engine',
                    'GitHub repository owner/repo_name (e.g.: "EpitechIT31000/chocolatine")')
        stringParam('GIT_BRANCH',
                    'dev',
                    'Git branch / tag of the repository to listen to')
    }

    wrappers {
        preBuildCleanup()
    }
    scm {
        git {
            remote {
                url('https://github.com/${GITHUB_NAME}.git')
            }
            branch('$GIT_BRANCH')
            extensions {
                submoduleOptions {
                    recursive(true)
                }
            }
        }
    }
    // Token to trigger the job remotely, e.g., from a GitHub webhook.
    authenticationToken(System.getenv("JOB_REMOTE_TOKEN"))

    steps {
        shell('''
            set -e

            echo "[INFO] Entering nix-shell and building docs"
            nix-shell -p doxygen graphviz just --run "just common-update && just doxygen"

            echo "[INFO] Packaging documentation"
            mkdir -p build-doc-tmp
            # Adjust path if your doxygen output differs
            cp -r doxygen/html/* build-doc-tmp/

            ARCHIVE=\"${GIT_BRANCH}\"
            tar -czf "$ARCHIVE" -C build-doc-tmp .

            echo "[INFO] Sending archive to incoming directory"
            # $HOST_DOCS_FOLDER must be host-mounted into the Jenkins container
            mv "$ARCHIVE" "$HOST_DOCS_FOLDER/"

            echo "[INFO] Done."
        ''')
    }
}

freeStyleJob('/benchmark-expose') {
    parameters {
        stringParam('GITHUB_NAME',
                    'Julian52575/Hylozoa-Engine-Engine',
                    'GitHub repository owner/repo_name (e.g.: "EpitechIT31000/chocolatine")')
        stringParam('GIT_BRANCH',
                    'dev',
                    'Git branch / tag of the repository to listen to')
    }

    wrappers {
        preBuildCleanup()
    }
    scm {
        git {
            remote {
                url('https://github.com/${GITHUB_NAME}.git')
            }
            branch('$GIT_BRANCH')
            extensions {
                submoduleOptions {
                    recursive(true)
                }
            }
        }
    }
    // Token to trigger the job remotely, e.g., from a GitHub webhook.
    authenticationToken(System.getenv("JOB_REMOTE_TOKEN"))

    steps {
        shell('''
            set -e

            echo "[INFO] Entering nix-shell and building benchmarks"

            # Write the Nix expression to a temp file to avoid quoting hell
            NIX_EXPR=$(mktemp /tmp/shell-XXXXXX.nix)
            trap "rm -f $NIX_EXPR" EXIT

            cat > "$NIX_EXPR" << 'NIXEOF'
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-24.05";
  pkgs = import nixpkgs {};

  sdlDeps = with pkgs; [
    # Audio
    alsa-lib pulseaudio jack2 sndio pipewire
    # X11 / display
    xorg.libX11 xorg.libXext xorg.libXrandr xorg.libXcursor
    xorg.libXfixes xorg.libXi xorg.libXScrnSaver xorg.libXtst
    libxkbcommon
    # DRM / GPU / GL
    libdrm mesa
    libGL
    libglvnd    
    # Wayland
    wayland libdecor
    # System / input
    udev dbus ibus libthai fribidi liburing
  ];

  buildTools = with pkgs; [
    clang-tools clang valgrind cmake just doxygen graphviz
    pkg-config ninja
  ];
in
pkgs.mkShellNoCC {
  packages = buildTools ++ sdlDeps;

  CXX = "clang++";

  shellHook = ''
    export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath sdlDeps}:$LD_LIBRARY_PATH

    export LIBGL_DRIVERS_PATH=${pkgs.mesa.drivers}/lib/dri

    export CMAKE_PREFIX_PATH=${pkgs.lib.makeSearchPathOutput "dev" "" sdlDeps}:$CMAKE_PREFIX_PATH

    export PKG_CONFIG_PATH=${pkgs.lib.makeSearchPathOutput "dev" "lib/pkgconfig" sdlDeps}:$PKG_CONFIG_PATH
  '';
}
NIXEOF
    COMMIT=$(git rev-parse HEAD);
    nix-shell "$NIX_EXPR" \
        --run "bash -c '
            mkdir -p buildRelease --verbose;
            cmake -S . -B buildRelease -DCMAKE_BUILD_TYPE=Release -DHE_ENGINE_BUILD_BENCHMARKS=ON \
                -DSDL_UNIX_CONSOLE_BUILD=ON \
                -DSDL_ALSA=OFF;
            cmake --build buildRelease --config Release --parallel 8;
            cp ./buildRelease/benchmarks/benchmarkSuite .;
            ./benchmarkSuite --benchmark_out="benchmarkresults_${COMMIT}_${GIT_BRANCH}.json" \
                --benchmark_out_format=json \
                --benchmark_repetitions=10 \
                --benchmark_report_aggregates_only=true;
            mv benchmarkresults*.json "$HOST_BMS_FOLDER/" --verbose;
        '"
        ''') // shell
    }
}