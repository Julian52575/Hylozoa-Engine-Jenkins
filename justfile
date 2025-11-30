set export := true
set dotenv-load := true

CONTAINER_NAME := "hylozoa-engine-jenkins_jenkins_1"
IMAGE_NAME := "hylozoa-engine-jenkins_jenkins"

help:
    just --list

up:
    mkdir -p ./jenkins_home && podman unshare chown -R 1000:1000 jenkins_home
    podman-compose up --build -d

down:
    podman stop {{CONTAINER_NAME}}
    podman rm {{CONTAINER_NAME}}

rm:
    podman stop {{CONTAINER_NAME}} || true
    podman rm {{CONTAINER_NAME}} || true
    podman image rm hylozoa-engine-jenkins_jenkins || true

reset: down rm clean-volumes up

logs:
    podman logs {{CONTAINER_NAME}}

exec CMD:
    podman exec -it {{CONTAINER_NAME}} {{CMD}}

clean-volumes:
    podman volume prune -f
    sudo rm -rf ./${DOCS_FOLDER} ./jenkins_home