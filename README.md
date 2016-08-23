# Deploying a multi component application in Kubernetes, on AWS

The goal of this tutorial project is deploying a sample application in Kubernetes on AWS.

The application is quite simple, but have some moving parts.
- A frontend component exposing an API. The application comes from an old post of mine: [Implementing HAL hypermedia REST API using Spring HATEOAS](https://opencredo.com/hal-hypermedia-api-spring-hateoas/). It will be deployed in multiple instances and exposed through a Load Balancer.
- A database. We are using H2 as standalone server.
- Frontend environment-specific configuration and secrets are published using a Secret
- The db server is using a separate persistent volume for data. Data won't be lost when the Pod restarts.

## Requirements

For running this tutorial you need:

- An AWS account (running the K8s cluster is going to cost few bucks).
- A DockerHub account (this is free)

You also need the following software on your machine:

- Docker (tested with v1.9.1)
- Kubernetes (tested with v1.3.5)
- AWS CLI (also requires Python)
- Maven (to compile the sample Spring Boot application)

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
    --name h2server k8s-sample_h2db:0.1
$ docker run -d -p 8080:8080 --net=sample_net --volume=`pwd`/etc/sample-app/:/etc/spring:ro \
    -e SAMPLE_DATA="true" \
    --name my-app k8s-sample_application:0.1
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

Retrieve Cluster info:
```
$ kubectl cluster-info
```

Get authentication info (e.g. for accessing Kubernetes dashboard)
```
$ kubectl config view
...
- name: aws_kubernetes-basic-auth
  user:
    password: <password>
    username: admin
```

## Deploying application on Kubernetes Cluster

Create a secret with Spring-Boot environment specific configuration file:
```
$ kubectl create secret generic sample-app-cfg \
    --from-file=./etc/sample-app/application-kubernetes.yaml
```


Create EBS volume for H2
```
$ aws ec2 create-volume --size 1 --availability-zone $KUBE_AWS_ZONE --volume-type standard
{
    "AvailabilityZone": "eu-west-1c",
    "Encrypted": false,
    "VolumeType": "standard",
    "VolumeId": "vol-901a5821",
    "State": "creating",
    "SnapshotId": "",
    "CreateTime": "2016-08-22T10:55:45.663Z",
    "Size": 1
}
```
Take note of `VolumeId`

### Create H2 db service

Edit `k8s/h2server-deployment.yaml` replacing:

- `<VOLUME-ID>` with the VolumeId you just created
- `<DOCKERHUB-ACCOUNT>` with the name of your DockerHub account

Create the Deployment:
```
$ kubectl create -f k8s/h2server-deployment.yaml
```

Create an internal (not exposed) H2 Service:
```
$ kubectl create -f k8s/h2server-svc.yaml
```

(Optional) Create an exposed service for H2 web UI
```
$ kubectl create -f k8s/h2server-webui-svc.yaml
service "h2server-ui" created

$ kubectl describe svc h2server-ui
Name:  			h2server-ui
Namespace:     		default
Labels:			<none>
Selector:      		name=h2server
Type:  			LoadBalancer
IP:    			10.0.13.182
LoadBalancer Ingress:  	a8263d986693011e6a24f0aa73e55bfa-1258493660.eu-west-1.elb.amazonaws.com
Port:  			<unset>	80/TCP
NodePort:      		<unset>	32413/TCP
Endpoints:     		10.244.0.3:81
Session Affinity:      	None
```

Take note of the Load Balancer DNS name (`a8263d986693011e6a24f0aa73e55bfa-1258493660.eu-west-1.elb.amazonaws.com` in the example).

To connect to the database from the UI use this JDBC URL: `jdbc:h2:tcp://h2server:1521/hateoas-sample`.
Note that schema and sample data are created by the application.

### Launch the Sample Application as Pod

Edit `k8s/sample-app-pod.yaml` replacing `<DOCKERHUB-ACCOUNT>` with the name of your DockerHub account

Launch Sample App as single Pod (to use your own image, change DockerHub username for `image` in `k8s/sample-app-pod.yaml`.
```
$ kubectl create -f k8s/sample-app-pod.yaml
```

The Pod spec configure the application to load sample data.

### Publish as Service with an external load balancer

Create FrontEnd Service and Load Balancer
```
$ kubectl create -f k8s/frontend-svc.yaml
```

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

Take note of Load Balancer Ingress DNS name and ELB Name (the trailing part of DNS name up to the first hyphen).

The Instances take a while to be attached to the ELB. You may monitor the ELB state until all Instances are *InService*:
```
$ aws elb describe-instance-health --load-balancer-name <elb-name>
```

### Verify the application is working

Access data through the API, exposed by the frontend ELB:
```
$ curl http://<frontend-load-balancer-dns-name>/books
```

### Redeploy the application with a Deployment

Delete Sample App Pod
```
$ kubectl delete pod sample-app
```

Edit `k8s/frontend-deployment.yaml` replacing `<DOCKERHUB-ACCOUNT>` with the name of your DockerHub account.

Create FrontEnd Deployment:
```
$ kubectl create -f k8s/frontend-deployment.yaml
deployment "frontend" created
```

The Deployment specs file DO NOT make the application loading sample data on start.

Monitor deployment rollout:
```
$ kubectl rollout status deployment/frontend
```

Monitor Pods coming up:
```
$ kubectl get pods
```

## More operations

### Kill the database Pod and verify data are not lost

Show Pod names
```
$ kubectl get pods
NAME                        READY     STATUS    RESTARTS   AGE
h2server-2210399524-29pfi   1/1       Running   0          5m
```

Kill the h2server Pod
```
$ kubectl delete pod h2server-2210399524-29pfi
```

... a new Pod will be automatically respawned by the ReplicaSet.
```
$ kubectl get pod
NAME                        READY     STATUS              RESTARTS   AGE
h2server-2210399524-kql7w   0/1       ContainerCreating   0          13s
...
$ kubectl get pod
NAME                        READY     STATUS    RESTARTS   AGE
h2server-2210399524-kql7w   1/1       Running   0          3m
```

Query the application API (no data loss):
```
$ curl http://<docker-machine-ip>:8080/books
```


### Update Deployment

Rebuild the sample application assigning a version tag `0.2`. Push the new version to DockerHub.

Update the image used by the Deployment:
```
$ kubectl set image deployment/frontend application=<dockerhub-user>/k8s-sample_application:0.2
....
$ kubectl rollout status deployment/frontend
```

### Add a Minion (Node) Instance

Check the number of Minions we have:
```
$ kubectl get nodes
NAME                                         STATUS    AGE
ip-172-20-0-180.eu-west-1.compute.internal   Ready     38m
ip-172-20-0-181.eu-west-1.compute.internal   Ready     39m
ip-172-20-0-182.eu-west-1.compute.internal   Ready     39m
```

To add a new Minion we have to leverage AWS Autoscaling.

Edit the autoscaling Group to increase capacity
```
$ aws autoscaling update-auto-scaling-group --auto-scaling-group-name kubernetes-minion-group-eu-west-1c \
    --max-size 4 --desired-capacity 4
```

...after a while (minutes)..
```
$ kubectl get nodes
NAME                                         STATUS    AGE
ip-172-20-0-180.eu-west-1.compute.internal   Ready     38m
ip-172-20-0-181.eu-west-1.compute.internal   Ready     39m
ip-172-20-0-182.eu-west-1.compute.internal   Ready     39m
ip-172-20-0-72.eu-west-1.compute.internal    Ready     52s
```

## Cleanup

Tear down Services, ReplicaSet and Pods
```
$ kubectl delete deployment frontend h2server
deployment "frontend" deleted
deployment "h2server" deleted

$ kubectl delete svc frontend h2server h2server-ui
service "frontend" deleted
service "h2server" deleted
service "h2server-ui" deleted

$ kubectl delete secret sample-app-cfg
secret "sample-app-cfg" deleted
```

Or, more quickly, shut down the cluster:
```
$ kube-down.sh
```

Remove the volume crated for H2 data
```
$ aws ec2 delete-volume --volume-id <volume-id>
```
