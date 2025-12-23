folder("/Tools") {
    description("Folder for miscellaneous tools.")
}

freeStyleJob('/Tools/doxygen-listen-branch') {
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

    steps {
        shell('''
            set -e

            ls common
            echo "[INFO] Entering nix-shell and building docs"
            nix-shell --run "just common-update"
            nix-shell --run "just doxygen"

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
