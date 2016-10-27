# kubeadm-gce-tf

This is a proof of concept (not supported for production deployments) that uses terraform to launch a set of machines on [GCE](https://cloud.google.com/compute/).  It then uses `kubeadm` to automatically boostrap a Kubernetes cluster.  Simple networking is provided via a combination of routing configuration on GCE and using [CNI](https://github.com/containernetworking/cni) to manage a bridge.

## Instructions

1. Download and install [Terraform](https://www.terraform.io/intro/getting-started/install.html)

1. Sign up for an account (project) on [Google Cloud Platform](https://cloud.google.com/free-trial/).  There is a free trial.

1. Install and initialize the `gcloud` CLI from the [Cloud SDK](https://cloud.google.com/sdk/)

1. Configure a service account for terraform to use.

  ```bash
  SA_EMAIL=$(gcloud iam service-accounts --format='value(email)' create k8s-terraform)
  gcloud iam service-accounts keys create account.json --iam-account=$SA_EMAIL
  ```

1. Configure terraform variables
  * Start with the provided template:

    ```bash
    cp terraform.tfvars.sample terraform.tfvars
    ```
  * Generate a token:

    ```bash
    python -c 'import random; print "%0x.%0x" % (random.SystemRandom().getrandbits(3*8), random.SystemRandom().getrandbits(8*8))'
    ```
  * Open `terraform.tfvars` in an editor and fill in the blanks

1. Run `terraform plan` to see what it is thinking of doing. By default it'll boot 4 `n1-standard-1` machines.  1 master and 3 nodes.

1. Run `terraform apply` to actually launch stuff.

1. Run `terraform destroy` to tear everything down.

## Using the cluster

The API server will be running an unsecured endpoint on port 8080 on the master node (only on localhost).

### SSH in to master

You can easily just ssh in to the cluster and run `kubectl` there.  That is probably easiest.

```
workstation$ gcloud ssh --zone=us-west1-a kube-master
kube-master$ kubectl get nodes
NAME          STATUS    AGE
kube-master   Ready     1h
kube-node-0   Ready     1h
kube-node-1   Ready     1h
kube-node-2   Ready     1h
```

### SSH tunnel to master

You can easily create an SSH tunnel to that machine and use your local kubectl.  `kubectl` should have been installed for you by the Google Cloud SDK.

```bash
# Launch the SSH tunnel in the background
gce ssh --zone=us-west1-a kube-master -- -L 8080:127.0.0.1:8080 -N &

# Set up and activate a "localhost" context for kubectl
kubectl config set-cluster localhost --server=127.0.0.1:8080 --insecure-skip-tls-verify
kubectl config set-context localhost --cluster=localhost
kubectl config use-context localhost
kubectl get nodes
```

### Authenticate to master over Internet

**TODO:** Document how to copy `/etc/kubernetes/admin.conf` down from `kube-master` and modify/merge it in to local kubectl config.  Also need to open up port in GCE firewall.
