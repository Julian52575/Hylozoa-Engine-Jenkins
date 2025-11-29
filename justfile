set export := true
set dotenv-load := true

help:
    just --list

up:
    podman-compose up --build -d

down:
    podman stop hylozoa-engine-jenkins_jenkins_1
    podman rm hylozoa-engine-jenkins_jenkins_1