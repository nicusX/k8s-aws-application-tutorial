# Kubernetes application sample


## Build and publish Docker images

### Start Docker machine (OS X only)

```
$ docker-machine start default
$ eval $(docker-machine env default)
```

### Build Docker images

Build docker images: `build.sh` or...

1. Build the Spring Boot application: `(cd application/spring-hateoas-sample; mvn clean package)`
2. Build Application docker image: `(cd application; docker build -t k8s-sample_application:0.1 .)`
3. Build H2 docker image: `(cd h2db; docker build -t k8s-sample_h2db:0.1 .)`

Docker daemon (or docker-machine, on OSX) must be running to be able to build images.


### Push images to DockerHub

(You must have a DockeHub account)

Login Docker client
```
$ docker login
```

Tags images then push them to DockerHub:

```
$ docker tag k8s-sample_application:0.1 docker.io/<dockehub-username>/k8s-sample_application:0.1
$ docker push <dockehub-username>/k8s-sample_application:0.1
...
$ docker tag k8s-sample_h2db:0.1 docker.io/<dockehub-username>/k8s-sample_h2db:0.1
$ docker push <dockehub-username>/k8s-sample_h2db:0.1
...
```


### Run application component locally in Docker

Run both containers locally. Define a docker network to connect them. Mount the Spring Boot configuration file as a volume.

```
$ docker network create --driver bridge sample_net
$ docker volume create --name h2data --driver local --opt type=ext4
$ docker run -d -p 8081:81 -p 1521:1521 --net=sample_net -v h2data:/var/h2-data \
    --name h2server nicus/k8s-sample_h2db:0.1
$ docker run -d -p 8080:8080 --net=sample_net --volume=`pwd`/etc/sample-app/:/etc/spring:ro \
    -e SAMPLE_DATA="true" \
    --name my-app nicus/k8s-sample_application:0.1
```

Remove `-e SAMPLE_DATA="true"` to skip loading sample data.


To check if the application is responding:
```
$ curl http://<docker-machine-ip>:8080/books
```

H2 UI is on `http://<docker-machine-ip>:8081`. Use JDBC URL: `jdbc:h2:/var/h2-data/hateoas-sample`, User: `sa`, no password

Cleanup
```
$ docker stop my-app h2server
$ docker rm my-app h2server
$ docker volume rm h2data
$ docker network rm sample_net
```


## Create Kubernetes Cluster on AWS

### Setup working environment and AWS authentication

Defines the following environment variables.

AWS client:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_DEFAULT_REGION`

Kubernetes Cluster (see http://kubernetes.io/docs/getting-started-guides/aws/):

- `KUBERNETES_DIR` Kubernetes installation directory (e.g. `~/Applications/kubernetes`) and add Kubernetes Cluster commands to PATH: `export PATH=$PATH:$KUBERNETES_DIR/cluster`
- `KUBERNETES_PROVIDER=aws`
- `AWS_S3_REGION` AWS Region (e.g. `eu-west-1`)
- `KUBE_AWS_ZONE` AWS Availability Zone (e.g. `eu-west-1c`)

Optionally you may also specify:

- `INSTANCE_PREFIX` Prefix to Instance names
- `AWS_S3_BUCKET` S3 bucket name
- `PROJECT_ID` K8s Project ID
- `MASTER_SIZE` Master Instances size (e.g. `t2.micro`)
- `NUM_NODES` Number of nodes instances (e.g. `3`)

## Create Kubernetes cluster

```
$ kube-up.sh
... Starting cluster in eu-west-1c using provider aws
... calling verify-prereqs
... calling kube-up
[...]
Cluster validation succeeded
Done, listing cluster services:
[...]
```

To retrieve Cluster info:
```
$ kubectl cluster-info
```

To get authentication info (e.g. for accessing Kubernetes dashboard)
```
$ kubectl config view
...
- name: aws_kubernetes-basic-auth
  user:
    password: <password>
    username: admin
```

## Deploying application on Kubernetes Cluster

Create secret with Spring-Boot application configuration file:
```
$ kubectl create secret generic sample-app-cfg  --from-file=./etc/sample-app/application-kubernetes.yaml
```


Create EBS volume for H2
```
$ aws ec2 create-volume --size 1 --availability-zone $KUBE_AWS_ZONE --volume-type standard
{
    "AvailabilityZone": "eu-west-1c",
    "Encrypted": false,
    "VolumeType": "standard",
    "VolumeId": "vol-4f82c3fe",
    "State": "creating",
    "SnapshotId": "",
    "CreateTime": "2016-08-22T10:55:45.663Z",
    "Size": 1
}
```
Take note of `VolumeId`

Launch H2 Pod, passing the VolumeId
```
$ sed 's/VOLUME-ID/<volume-id>/' k8s/h2db-pod.yaml | kubectl create -f -
```

TODO Create H2 Service


TODO Launch Sample App Pod

TODO Create FrontEnd Service w/ Load Balancer

Describe Service to get external LB URL
```
$ kubectl describe svc frontend
Name:  			frontend
Namespace:  default
Labels:			<none>
Selector:   name=sample-app
Type:  			LoadBalancer
IP:    			10.0.200.84
LoadBalancer Ingress:  	aeb778c57687411e6b0e80a720f796de-1966482204.eu-west-1.elb.amazonaws.com
Port:  			<unset>	80/TCP
```

Take note of Load Balancer Ingress DNS name

Check if the application is running
```
$ curl http://<load-balancer-dns-name>/books
```


TODO Delete Sample App Pod

TODO Create FrontEnd ReplicaSet


## Cleanup

TODO Tear down Services, ReplicaSet and Pods

Remove the volume
```
$ aws ec2 delete-volume --volume-id <volume-id>
```

## Useful snippets

Stop and remove all local Docker containers, remove all volumes, remove custom network
```
$ docker stop $(docker ps -q); \
  docker rm $(docker ps -a -q); \
  docker volume rm $(docker volume ls -q); \
  docker network rm sample_net
```

Remove all local Docker images:
```
$ docker rmi $(docker images -q)
```
