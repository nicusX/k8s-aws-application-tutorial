# Scale up Minion (Node) Instance

Kubernetes does NOT autoscale Minion instances, but you may leverage AWS Autoscale Group to *manually* add more Nodes.

Check the number of Minions we have now:
```
$ kubectl get nodes
NAME                                         STATUS    AGE
ip-172-20-0-180.eu-west-1.compute.internal   Ready     38m
ip-172-20-0-181.eu-west-1.compute.internal   Ready     39m
ip-172-20-0-182.eu-west-1.compute.internal   Ready     39m
```


Edit the AWS Autoscaling Group to increase capacity (you may do the same using AWS console):
```
$ aws autoscaling update-auto-scaling-group --auto-scaling-group-name kubernetes-minion-group-eu-west-1c \
    --max-size 4 --desired-capacity 4
```

...after a while (minutes) a new Node will be available
```
$ kubectl get nodes
NAME                                         STATUS    AGE
ip-172-20-0-180.eu-west-1.compute.internal   Ready     38m
ip-172-20-0-181.eu-west-1.compute.internal   Ready     39m
ip-172-20-0-182.eu-west-1.compute.internal   Ready     39m
ip-172-20-0-72.eu-west-1.compute.internal    Ready     52s
```
