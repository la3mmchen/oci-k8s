#cloud-config
merge_how:
  - name: list
    settings: [append]
  - name: dict
    settings: [no_replace, recurse_list]


hostname: "${hostname}"
fqdn: "${hostname}.${domain}"

packages:
  - apt-transport-https
  - ca-certificates
  - curl
  - net-tools
  - containerd
package_update: true
manage_etc_hosts: true
output: 
  all: '| tee -a /var/log/cloud-init.log'
runcmd:
- mkdir -p /etc/kubeadm
- swapoff -a
- sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
- systemctl restart systemd-resolved
- curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
- echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
- apt-get update
- apt-get install -y kubelet kubeadm kubectl
- apt-mark hold kubelet kubeadm kubectl
- modprobe br_netfilter
- echo 1 > /proc/sys/net/ipv4/ip_forward
- sysctl --system
- kubeadm init --apiserver-cert-extra-sans=localhost
- mkdir -p /home/ubuntu/.kube
- cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
- chown -R $(id -u ubuntu):$(id -g ubuntu) /home/ubuntu/.kube
- cp -p /home/ubuntu/.kube/config /home/ubuntu/.kube/config.localhost
- sed -i -E "s/https:\/\/(.*):6443/https:\/\/localhost:6443/g" ~/.kube/config.localhost
- su ubuntu -c "kubectl taint node k8s-0 node-role.kubernetes.io/master:NoSchedule-"
write_files:
  - path: /etc/modules-load.d/k8s.conf
    content: |
      br_netfilter
  - path: /etc/sysctl.d/k8s.conf
    content: |
      net.bridge.bridge-nf-call-ip6tables = 1
      net.bridge.bridge-nf-call-iptables = 1