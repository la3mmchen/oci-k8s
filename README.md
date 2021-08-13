# oci-k8s
Simple K8S Infrastructure based on Oracle Cloud Free Tier offering.

This terraform setup builds an always free instance and bootstraps there a single node kubernetes cluster (latest version).

To simplify the setup and to mitigate security concerns there is no external traffic allowed to kubernetes. either work remote on the vm or use a ssh tunnel.


```bash
$ scp -rv ubuntu@<public ip>:~/.kube/config.localhost ~/.kube/config
$ ssh -NL 6443:127.0.0.1:6443 -l ubuntu <public ip>
$ kubectl cluster-info
Kubernetes control plane is running at https://localhost:6443
CoreDNS is running at https://localhost:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.

$ kubectl get nodes
NAME    STATUS     ROLES                  AGE   VERSION
k8s-0   NotReady   control-plane,master   3m    v1.22.0

$ kubectl get pods --all-namespaces
NAMESPACE     NAME                            READY   STATUS    RESTARTS   AGE
kube-system   coredns-78fcd69978-sp8r6        0/1     Pending   0          3m1s
kube-system   coredns-78fcd69978-vbs6x        0/1     Pending   0          3m1s
kube-system   etcd-k8s-0                      1/1     Running   1          3m1s
kube-system   kube-apiserver-k8s-0            1/1     Running   1          3m
kube-system   kube-controller-manager-k8s-0   1/1     Running   1          3m
kube-system   kube-proxy-9dpcb                1/1     Running   0          3m1s
kube-system   kube-scheduler-k8s-0            1/1     Running   1          3m1s

## how to 

### setup terraform with OCI
- Sign up at https://www.oracle.com/de/cloud/free/
- Create a gpg key:
  ```bash
  mkdir -p ~/.oci
  openssl rsa -pubout -in ~/.oci/${USER}.pem -out ~/.oci/${USER}_pub.pem
  ```
- Add the public key under Identity > Your User > Api Keys (https://cloud.oracle.com/identity/users/)
- Copy the credentials summary and create the provider config (e.g. `auth.tf`):
  
  ```hcl
  variable "tenancy_ocid" {
    default = "<user ocid>"
  }
  provider "oci" {
    tenancy_ocid     = "(..)"
    user_ocid        = "(..)"
    private_key_path = "(private key)"
    fingerprint      = "<..>"
    region           = "(..)"
  }
  ```

### provsion infra

- `terraform init`
- `terraform plan`
- `terraform apply`


### connect



```bash

```

