# Rolling update of application

Having used a Deployment, we may now [http://kubernetes.io/docs/user-guide/deployments/#updating-a-deployment](rollout an update of the Docker Image).

You may make some (not breaking) change to the application, rebuild it tagging the application image as version 0.2 and publish to public image registry.

When the new image is available in the public repo, you may update the application Deployment:
```
$ kubectl set image deployment/frontend application=<dockerhub-user>/k8s-sample_application:0.2
```

Watch the deployment being rolled out:
```
$ kubectl rollout status deployment/frontend
...
$ kubectl get pods -o wide
```
