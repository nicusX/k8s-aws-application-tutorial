# Kubernetes application sample


## Start Docker machine (OS X only)

```
$ docker-machine start default
$ eval $(docker-machine env default)
```


## Build images


Build docker images: `build.sh` or...
1. Build the Spring Boot application: `(cd application/spring-hateoas-sample; mvn clean package)`
2. Build Application docker image: `(cd application; docker build -t k8s-sample:sample-app .)`
3. Build H2 docker image: `(cd h2db; docker build -t k8s-sample:h2db .)`

TODO publish to a public registry

Note the images are named (labels should be used for versioning, but this allows us to use a single Docker Registry repository):
* k8s-sample:application
* k8s-sample:h2db



## Run Docker locally

Run both containers locally. Define a docker network to connect them. Mount the Spring Boot configuration file as a volume.

```
$ docker network create --driver bridge sample_net
$ docker volume create --name h2data --driver local --opt type=ext4
$ docker run -d -p 8081:81 -p 1521:1521 --net=sample_net -v h2data:/var/h2-data \
    --name h2server k8s-sample:h2db
$ docker run -d -p 8080:8080 --net=sample_net --volume=`pwd`/etc/sample-app/:/etc/spring:ro \
    --name sample-app k8s-sample:sample-app
```

To check if the application is responding:
```
$ curl http://<docker-machine-ip>:8080/books
```

H2 UI is on `http://<docker-machine-ip>:8081`. Use JDBC URL: `jdbc:h2:/var/h2-data/hateoas-sample`, User: `sa`, no password

Cleanup
```
$ docker stop sample-app h2server
$ docker rm sample-app h2server
$ docker volume rm h2data
$ docker network rm sample_net
```

## Useful snippets

Delete all local Docker containers: `docker rm $(docker ps -a -q)`

Delete all local Docker images `docker rmi $(docker images -q)`
