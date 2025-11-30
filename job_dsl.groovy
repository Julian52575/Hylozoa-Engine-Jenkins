folder("/Tools") {
    description("Folder for miscellaneous tools.")
}

freeStyleJob('/Tools/doxygen-listen-branch') {
    parameters {
        stringParam('GIT_REPOSITORY_URL',
                    'git@github.com:Julian52575/Hylozoa-Engine-Engine.git',
                    'Git URL of the repository to clone. IE: git@github.com:Julian52575/Hylozoa-Engine-Engine.git')
        stringParam('GIT_BRANCH',
                    'dev',
                    'Git branch / tag of the repository to listen to')
        credentialsParam('SSH_KEY') {
                description('SSH Key used to clone the repository') 
                required(true)
        }
    }

    wrappers {
        preBuildCleanup()
    }

    steps {
        shell('''
            set -e

			eval "$(ssh-agent -s)"
			echo "$SSH_KEY" > a.ssh
            chmod 600 a.ssh
			ssh-add a.ssh
			rm a.ssh

            REPO_NAME=$(basename "$GIT_REPOSITORY_URL" .git)
            echo "[INFO] Cloning $REPO_NAME from $GIT_REPOSITORY_URL"
            git clone "$GIT_REPOSITORY_URL"
            cd "$REPO_NAME"

            echo "[INFO] Checking out branch: $GIT_BRANCH"
            git checkout "$GIT_BRANCH"

            echo "[INFO] Entering nix-shell and building docs"
            nix-shell --run "just doxygen"

            echo "[INFO] Packaging documentation"
            mkdir -p build-doc-tmp
            # Adjust path if your doxygen output differs
            cp -r docs/html/* build-doc-tmp/

            ARCHIVE=\"${GIT_BRANCH}.tar.gz\"
            tar -czf "$ARCHIVE" -C build-doc-tmp .

            echo "[INFO] Sending archive to incoming directory"
            # /srv/docs_incoming must be host-mounted into the Jenkins container
            cp "$ARCHIVE" /srv/docs_incoming/

            echo "[INFO] Done."
        ''')
    }
}
