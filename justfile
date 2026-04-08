set export := true
set dotenv-load := true

CONTAINER_NAME := "hylozoa-engine-jenkins_jenkins_1"
IMAGE_NAME := "hylozoa-engine-jenkins_jenkins"

help:
    just --list

up:
    mkdir -p ./jenkins_home ".${HOST_DOCS_FOLDER}" ".${HOST_BMS_FOLDER}" \
        && podman unshare chown -R 1000:1000 jenkins_home \
        && podman unshare chown -R 1000:1000 ".${HOST_DOCS_FOLDER}" \
        && podman unshare chown -R 1000:1000 ".${HOST_BMS_FOLDER}"
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


# DOCS EXTRACTER
DOC_EXTRACTER_NAME := "doc_extracter"
DOC_EXTRACTER_PROCESS_FILE := "${PROCESS_FOLDER}/${DOC_EXTRACTER_NAME}.pid"
DOC_EXTRACTER_LOGS := "${LOGS_FOLDER}/${DOC_EXTRACTER_NAME}.log"

doc-extracter-up:
    if [ ! -d ".${HOST_DOCS_FOLDER}" ]; then \
        echo "Host docs folder .${HOST_DOCS_FOLDER} does not exist. Let docker-compose create it."; \
        exit 84 \
    ; fi; 
    if [ -f {{DOC_EXTRACTER_PROCESS_FILE}} ]; then just doc-extracter-down; fi
    inotifywait ".${HOST_DOCS_FOLDER}" -e CREATE -e MOVED_TO --format '%f' -m | while read line; do \
        TARGET_FOLDER="${HTTP_EXPOSE_FOLDER}/$line"; \
        echo "[$line] Update detected on .${HOST_DOCS_FOLDER}/$line" >> {{DOC_EXTRACTER_LOGS}}; \
        mkdir -p "${TARGET_FOLDER}" && tar -xzf ".${HOST_DOCS_FOLDER}/$line" -C "${TARGET_FOLDER}"; \
        echo "[$line] Extracted documentation at ${TARGET_FOLDER}" >> {{DOC_EXTRACTER_LOGS}}; \
    done & \
    PID=$!; \
    echo "Monitoring .${HOST_DOCS_FOLDER} using PID $PID" > {{DOC_EXTRACTER_LOGS}}; \
    echo $PID > {{DOC_EXTRACTER_PROCESS_FILE}}

doc-extracter-down:
    if [ -f {{DOC_EXTRACTER_PROCESS_FILE}} ]; then \
        PID=$(cat {{DOC_EXTRACTER_PROCESS_FILE}}); \
        kill $PID; \
        rm {{DOC_EXTRACTER_PROCESS_FILE}} {{DOC_EXTRACTER_LOGS}} ; \
        echo "Documentation extracter process ($PID) stopped."; \
    else \
        echo "No documentation extracter process found."; \
    fi

# BENCHMARK
BENCHMARK_EXPOSER_NAME := "benchmark_exposer"
BENCHMARK_EXPOSER_PROCESS_FILE := "${PROCESS_FOLDER}/${BENCHMARK_EXPOSER_NAME}.pid"
BENCHMARK_EXPOSER_LOGS := "${LOGS_FOLDER}/${BENCHMARK_EXPOSER_NAME}.log"

benchmark-exposer-up:
    if [ ! -d ".${HOST_BMS_FOLDER}" ]; then \
        echo "Host benchmarks folder .${HOST_BMS_FOLDER} does not exist. Let docker-compose create it."; \
        exit 84 \
    ; fi;
    if [ -f {{BENCHMARK_EXPOSER_PROCESS_FILE}} ]; then just benchmark-exposer-down; fi
    inotifywait ".${HOST_BMS_FOLDER}" -e CREATE -e MOVED_TO --format '%f' -m | while read line; do \
        TARGET_FOLDER="${BM_EXPOSE_FOLDER}/$line"; \
        echo "[$line] Update detected on .${HOST_BMS_FOLDER}/$line" >> {{BENCHMARK_EXPOSER_LOGS}}; \
        mv ".${HOST_BMS_FOLDER}/$line" "${TARGET_FOLDER}"; \
        echo "[$line] Moved benchmark results to ${TARGET_FOLDER}" >> {{BENCHMARK_EXPOSER_LOGS}}; \
    done & \
    PID=$!; \
    echo "Monitoring .${HOST_BMS_FOLDER} using PID $PID" > {{BENCHMARK_EXPOSER_LOGS}}; \
    echo $PID > {{BENCHMARK_EXPOSER_PROCESS_FILE}}

benchmark-exposer-down:
    if [ -f {{BENCHMARK_EXPOSER_PROCESS_FILE}} ]; then \
        PID=$(cat {{BENCHMARK_EXPOSER_PROCESS_FILE}}); \
        kill $PID; \
        rm {{BENCHMARK_EXPOSER_PROCESS_FILE}} {{BENCHMARK_EXPOSER_LOGS}} ; \
        echo "Benchmark exposer process ($PID) stopped."; \
    else \
        echo "No benchmark exposer process found."; \
    fi

# Processes utilities
activeProcesses:
    # Parse .process for active processes and display them
    if [ -d ${PROCESS_FOLDER} ]; then \
        echo "Active processes:"; \
        for file in ${PROCESS_FOLDER}/*.pid; do \
            if [ -f "$file" ]; then \
                PROCESS_NAME=$(basename "$file" .pid); \
                PID=$(cat "$file"); \
                if ps -p $PID > /dev/null 2>&1; then \
                    echo "- $PROCESS_NAME (PID: $PID)"; \
                else \
                    echo "- $PROCESS_NAME (PID: $PID) [Not Running]"; \
                fi; \
            fi; \
        done; \
    fi

runProcesses:
    # Run both doc-extracter-up and benchmark-exposer-up in parallel
    just doc-extracter-up
    just benchmark-exposer-up

stopProcesses:
    # Stop all processes listed in .process
    if [ -d ${PROCESS_FOLDER} ]; then \
        for file in ${PROCESS_FOLDER}/*.pid; do \
            if [ -f "$file" ]; then \
                PROCESS_NAME=$(basename "$file" .pid); \
                PID=$(cat "$file"); \
                if ps -p $PID > /dev/null 2>&1; then \
                    kill $PID && echo "Stopped $PROCESS_NAME (PID: $PID)"; \
                else \
                    echo "$PROCESS_NAME (PID: $PID) is not running."; \
                fi; \
                rm "$file"; \
            fi; \
        done; \
    fi