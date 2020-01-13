Setup instructions
===========

# How it works
 
The application is deployed on kubernetes (GKE) using helm, and kubernetes is spawned using terraform.

A `Makefile` is provided for convenience (see below), but ideally those would be run in CI for
normal operation.

The helm chart has an additional backendConfig object that is GKE-specific, and allows 
configuring the GCP LB created by the ingress to use sticky sessions and change the
timeout duration. This is necessary for this app as it uses instance-local storage
for sessions and needs >30s timeout for the websocket connections.

As this is GKE-specific, Makefile variables are provided for minikube install
that deactivate this resource.

Finally, `search.js` and `search-simplified.js` still need to be modified, the image rebuilt
and redeployed in order to deploy the application under a new account. This is because
all other technical solutions (templating in helm, using something like envsubst, etc)
would only marginally improve deployment experience, while everything else would be much worse
because of code duplication, loss of ability to simply run `npm start` locally, etc.


# Cluster setup

Requirements :

- terraform >= 0.12.10
- gcloud
- kubectl
- helm v3.0.2
- minikube for local testing

## GKE

Need an account/project with permissions to create GKE clusters, LBs, NEGs, docker images.

The cluster will be created with Terraform. To configure credentials do:

```
gcloud auth login
gcloud auth application-default login
gcloud config set project MY_PROJECT
```

Spawn the cluster :
```
cd terraform/
terraform init
terraform apply -var project=$(gcloud config get-value project)
```

This will spawn a cluster named `kubernetest` with one private preemptible node in
it in the zone europe-west1-d, which should be sufficient for the demo.

Get the credentials for the cluster:
```
gcloud container clusters get-credentials --zone europe-west1-d kubernetest
```

## Minikube (local test)

Assuming minikube is correctly installed :

```
minikube start --memory=4gb
minikube addons enable ingress
```

Then, minikube needs to be able to access the docker registry on gcr. This is done with temporary credentials
generated at install/upgrade.

On minikube, all make commands must be prepended with `MINIKUBE=true`, e.g. `MINIKUBE=true make install`. 
This sets some chart options and creates the imagePullSecret to access the registry.

Once installed, the url of the services can be obtained with : `minikube service --url instant-search-demo`

# App setup

The commands to install/update the app are included in the Makefile with the
following commands available :


| `make` command | function                                                     |
|----------------|--------------------------------------------------------------|
| `build`        | builds the docker image, tagged with commit hash             |
| `push`         | push the image to te repository                              |
| `install`      | install the application in the cluster (calls build, push)   |
| `upgrade`      | upgrade the application (calls build, push)                  |
| `uninstall`    | uninstall the application from the cluster                   |

The variables can be used to modify the behavior of the commands:

| variable name        | purpose                                                | default                                                 |
|----------------------|--------------------------------------------------------|---------------------------------------------------------|
| `GOOGLE_PROJECT`     | used for the GCR repository url                        | $(shell gcloud config get-value project)                |
| `REPOSITORY`         | the repository used to tag/push/download docker images | eu.gcr.io/$(GOOGLE_PROJECT)/algolia-instant-search-demo |
| `DOCKER_TAG`         | the tag of the docker image to build/push/deploy       | $(shell git log --pretty=format:'%H' -n 1)              |
| `MINIKUBE`           | deploying in minikube or not                           | false                                                   |


# Teardown
## GKE

First uninstall the application with `make uninstall`, and allow gcp time to garbage-collect
all resources.

Then, delete the cluster:
```
cd terraform/
terraform destroy
```

## minikube

```
minikube delete
```
