# A note about security

The goal of the tutorial is not to create a production ready environment. Nevertheless, I'd suggest a few security measures to avoid any problem.

The security of Kubernetes cluster provisioned by `kube-up` is a bit lax. Considering the sample application we are using is note meant to be used in production, so it might not be properly secured.

Also, if you want to use the H2 Web UI, consider it is not secured AT ALL.

I'd suggest securing AWS Security Groups limiting inbound traffic from your IP only. You may easily do it from AWS console or use AWS CLI.

I'd also suggest not to keep the cluster running for long without being secured.
