# Build and publish Docker images

You need a working Docker installation on your machine (on OS X don't forget to set the environment after running the docker-machine: `eval $(docker-machine env default)`)

## Build Docker images

Build application and docker images:

1. Build the Spring Boot application: `(cd application/spring-hateoas-sample; mvn clean package)`
2. Build Application docker image: `(cd application; docker build -t k8s-sample_application:0.1 .)`
3. Build H2 docker image: `(cd h2db; docker build -t k8s-sample_h2db:0.1 .)`

Alternatively, you may use the provided `build.sh` script.

## Push images to DockerHub

For using our Docker Images in the Kubernetes cluster, we will run on AWS we have to publish them to a Docker registry. We are going to use DockerHub public repositories.

Login Docker client (provide your DockerHub account credentials)
```
$ docker login
```

Tags images:

```
$ docker tag k8s-sample_application:0.1 docker.io/<dockehub-username>/k8s-sample_application:0.1
$ docker tag k8s-sample_h2db:0.1 docker.io/<dockehub-username>/k8s-sample_h2db:0.1
```

Push images to DockerHub:
```
$ docker push <dockehub-username>/k8s-sample_application:0.1
$ docker push <dockehub-username>/k8s-sample_h2db:0.1
```
