set export := true
set dotenv-load := true

help:
    just --list

run:
    podman build -t he-jenkins .
    podman run he-jenkins