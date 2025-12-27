# Hylozoa Engine Jenkins

This repo contains the dev envrionement for building and running the Jenkins instance of the Hylozoa Engine Project.    
The dev environement _(powered by nix-shell)_ allows the instance to easily be ran locally or on a VM/server.    

## Features

| Name | Purpose | Just recipe |
| ---- | ---- | ------------- |
| Jenkins docker image | Run the Jenkins instance | `just up` and `just down` |
| Doc extracter | Extract the compressed documentation into the http server folder | `just doc-extracter-up` and `just doc-extracter-down` |

## Noteworthy files

| Name | Purpose |
| ---- | ---- |
| jenkins.yaml | Configure the Jenkins instance |
| job_dsl.groovy | Define Jenkins jobs |
| .env | The environement variables **shared between the jenkins container AND the nix-shell**. By default, is a symlink to .env.example that should be overwritten in production |
| .env.exemple | Lists the environment variables used and assigns them with dummy values |

## Noteworthy environement variables

| Name | Purpose |
| ---- | ---- |
| `$PROCESS_FOLDER` | Stores background process' pids inside files |
| `$LOGS_FOLDER` | Stores the logs of processes |
| `$HTTP_EXPOSE_FOLDER` | The path to the folder where the http server looks for html files |
