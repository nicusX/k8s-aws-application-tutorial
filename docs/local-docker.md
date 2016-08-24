# Run application component locally in Docker

This step is optional. To verify everything works before launching it on the remote K8s cluster, you may run the full stack locally, in Docker.

We are using a [Docker User Defined Network](https://docs.docker.com/engine/userguide/networking/#/user-defined-networks) to make the component communicate. We are also using a [Local Volume](https://docs.docker.com/engine/reference/commandline/volume_create/#volume-create) for storing persistent data.

## Create User-Defined Network and Local Volume

```
$ docker network create --driver bridge sample_net
$ docker volume create --name h2data --driver local --opt type=ext4
```

## Run Containers

```
$ docker run -d -p 8081:81 -p 1521:1521 --net=sample_net -v h2data:/var/h2-data \
    --name h2server k8s-sample_h2db:0.1
$ docker run -d -p 8080:8080 --net=sample_net --volume=`pwd`/etc/sample-app/:/etc/spring:ro \
    -e SAMPLE_DATA="true" \
    --name my-app k8s-sample_application:0.1
```

Remove `-e SAMPLE_DATA="true"` to skip loading sample data.


Verify the application is responding:
```
$ curl http://<docker-machine-ip>:8080/books
```

You may also access H2 Web UI on `http://<docker-machine-ip>:8081`.

Use JDBC URL: `jdbc:h2:/var/h2-data/hateoas-sample`, User: `sa`, no password

## Cleanup

```
$ docker stop my-app h2server
$ docker rm my-app h2server
$ docker volume rm h2data
$ docker network rm sample_net
```
