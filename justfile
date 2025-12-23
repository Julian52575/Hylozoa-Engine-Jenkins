set export := true
set dotenv-load := true

CONTAINER_NAME := "hylozoa-engine-jenkins_jenkins_1"
IMAGE_NAME := "hylozoa-engine-jenkins_jenkins"

help:
    just --list

up:
    mkdir -p ./jenkins_home && podman unshare chown -R 1000:1000 jenkins_home && podman unshare chown -R 1000:1000 ".${HOST_DOCS_FOLDER}"
    podman-compose up --build -d

down:
    podman stop {{CONTAINER_NAME}}
    podman rm {{CONTAINER_NAME}}

rm: down
    podman image rm hylozoa-engine-jenkins_jenkins || true

reset: 
    just down
    sudo rm -rf ./jenkins_home/
    just up

logs:
    podman logs {{CONTAINER_NAME}}

exec CMD:
    podman exec -it {{CONTAINER_NAME}} {{CMD}}

clean-volumes: down
    podman volume prune -f
    sudo rm -rf ./${HOST_DOCS_FOLDER} ./jenkins_home

DOC_EXPOSER_NAME := "doc_exposer"
DOC_EXPOSER_PROCESS_FILE := "${PROCESS_FOLDER}/${DOC_EXPOSER_NAME}.pid"
DOC_EXPOSER_LOGS := "${LOGS_FOLDER}/${DOC_EXPOSER_NAME}.log"
doc-exposer-run:
    if [ -f {{DOC_EXPOSER_PROCESS_FILE}} ]; then just doc-exposer-stop; fi
    inotifywait ".${HOST_DOCS_FOLDER}" -e CREATE -e MOVED_TO --format '%f' -m | while read line; do \
        TARGET_FOLDER="${HTTP_EXPOSE_FOLDER}/$line"; \
        echo "[$line] Update detected on .${HOST_DOCS_FOLDER}/$line" >> {{DOC_EXPOSER_LOGS}}; \
        mkdir -p "${TARGET_FOLDER}" && tar -xzf ".${HOST_DOCS_FOLDER}/$line" -C "${TARGET_FOLDER}"; \
        echo "[$line] Extracted documentation at ${TARGET_FOLDER}" >> {{DOC_EXPOSER_LOGS}}; \
    done & \
    PID=$!; \
    echo "Monitoring .${HOST_DOCS_FOLDER} using PID $PID" > {{DOC_EXPOSER_LOGS}}; \
    echo $PID > {{DOC_EXPOSER_PROCESS_FILE}}

doc-exposer-stop:
    if [ -f {{DOC_EXPOSER_PROCESS_FILE}} ]; then \
        PID=$(cat {{DOC_EXPOSER_PROCESS_FILE}}); \
        kill $PID; \
        rm {{DOC_EXPOSER_PROCESS_FILE}} {{DOC_EXPOSER_LOGS}} ; \
        echo "Documentation exposer process ($PID) stopped."; \
    else \
        echo "No documentation exposer process found."; \
    fi