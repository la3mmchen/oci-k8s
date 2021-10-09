# oci-k8s
Simple K8S Infrastructure based on Oracle Cloud Free Tier offering.

Check combinations:

| Kube Version   | OS Version     |
| -------------- | -------------- |
| 1.22x          | Ubuntu 20.04   |

This terraform setup builds an always free instance and bootstraps there a single node kubernetes cluster (latest version).

At the time of writing this builds a single instance with 4 cores and 24 memory ram.

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
k8s-0   NotReady   control-plane,master   22s   v1.22.2

$ kubectl get pods --all-namespaces
NAMESPACE     NAME                            READY   STATUS    RESTARTS   AGE
kube-system   coredns-78fcd69978-sp8r6        0/1     Pending   0          3m1s
kube-system   coredns-78fcd69978-vbs6x        0/1     Pending   0          3m1s
kube-system   etcd-k8s-0                      1/1     Running   1          3m1s
kube-system   kube-apiserver-k8s-0            1/1     Running   1          3m
kube-system   kube-controller-manager-k8s-0   1/1     Running   1          3m
kube-system   kube-proxy-9dpcb                1/1     Running   0          3m1s
kube-system   kube-scheduler-k8s-0            1/1     Running   1          3m1s
```

## how to 

### ssh key 

this setup assumes your public ssh key is at `~/.ssh/id_rsa.pub`

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

### update

just build a new cluster wtih 

```bash
$ terraform taint oci_core_instance.instance
Resource instance oci_core_instance.instance has been marked as tainted.
$ terraform apply
(...)

Note: Objects have changed outside of Terraform

Terraform detected the following changes made outside of Terraform since the last "terraform apply":

  # oci_core_instance.instance has been changed
  ~ resource "oci_core_instance" "instance" {
      + extended_metadata   = {}
        id                  = "ocid1.instance.oc1.uk-london-1.(...)"
        # (19 unchanged attributes hidden)
        # (7 unchanged blocks hidden)
    }
  (...)
```
