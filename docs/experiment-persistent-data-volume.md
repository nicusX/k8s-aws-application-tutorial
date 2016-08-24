# Kill the database Pod and verify no data is lost

As H2 Server Pod is using an external EBS volume for storing data, data are preserved if the H2 Pod restarts.

Show Pod names:
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

Query the application API:
```
$ curl http://<docker-machine-ip>:8080/books
```
