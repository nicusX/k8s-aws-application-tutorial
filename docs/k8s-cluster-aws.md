# Create Kubernetes Cluster on AWS

Provisioning the cluster is not the main goal of this tutorial. So, we will use `kube-up` and `kube-down` script, provided by Kubernetes, to set up the cluster on AWS (see http://kubernetes.io/docs/getting-started-guides/aws/).

You need an AWS account for this. Your AWS user must have almost full permissions.

## Set up AWS authentication

Set the following environment variables, matching your AWS credentials:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_DEFAULT_REGION` AWS Region (e.g. `eu-west-1`)

## Setup Kube-Up

Set the following variables:

- `KUBERNETES_DIR` Kubernetes installation directory (e.g. `~/Applications/kubernetes`) and add Kubernetes Cluster commands to PATH: `export PATH=$PATH:$KUBERNETES_DIR/cluster`
- `KUBERNETES_PROVIDER=aws`
- `AWS_S3_REGION` AWS Region (e.g. `eu-west-1`). Must match `AWS_DEFAULT_REGION`
- `KUBE_AWS_ZONE` AWS Availability Zone (e.g. `eu-west-1c`). Must be in the Region you are using.

Optionally you may also specify:

- `INSTANCE_PREFIX` Prefix to Instance names
- `AWS_S3_BUCKET` S3 bucket name
- `PROJECT_ID` K8s Project ID
- `NUM_NODES` Number of nodes instances (e.g. `3`)

### Master Instances size

By default, K8s master node uses a `m3.medium`. It falls out of AWS free tier so it is going to cost you some money. You may force using `t2.micro` instances setting the environment variable `MASTER_SIZE` to `t2.micro`, but I experienced random problems when running a cluster with a *micro* master.

## Provision the cluster

Now we are ready to create the cluster. It will take a while.

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

The script also sets up your `kubectl` client.

Retrieve Cluster info:
```
$ kubectl cluster-info
```

To retrieve authentication info to access Kubernetes dashboard:
```
$ kubectl config view
...
- name: aws_kubernetes-basic-auth
  user:
    password: <password>
    username: admin
```
