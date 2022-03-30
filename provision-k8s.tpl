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
  - bash-completion
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
- kubeadm init --apiserver-cert-extra-sans=localhost --pod-network-cidr=10.244.0.0/16
- mkdir -p /home/ubuntu/.kube
- cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
- chown -R $(id -u ubuntu):$(id -g ubuntu) /home/ubuntu/.kube
- cp -p /home/ubuntu/.kube/config /home/ubuntu/.kube/config.localhost
- sed -i -E "s/https:\/\/(.*):6443/https:\/\/localhost:6443/g" ~/.kube/config.localhost
- su ubuntu -c "kubectl taint node k8s-0 node-role.kubernetes.io/master:NoSchedule-"
- kubectl --kubeconfig /etc/kubernetes/admin.conf apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
- curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
- chmod 700 get_helm.sh && ./get_helm.sh
- rm ./get_helm.sh
- ( set -x; cd "$(mktemp -d)" && OS="$(uname | tr '[:upper:]' '[:lower:]')" && ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" && KREW="krew-${OS}_${ARCH}" && curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" && tar zxvf "${KREW}.tar.gz" && ./"${KREW}" install krew )
- echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> /home/ubuntu/.bashrc
- echo 'alias k=kubectl'  >> /home/ubuntu/.bashrc
- su ubuntu -c "kubectl krew install ns ctx"
- su ubuntu -c "kubectl completion bash > /home/ubuntu/.kube/completion.bash.inc"
- su ubuntu -c "echo 'source /home/ubuntu/.kube/completion.bash.inc' >> /home/ubuntu/.bashrc"
write_files:
  - path: /etc/modules-load.d/k8s.conf
    content: |
      br_netfilter
  - path: /etc/sysctl.d/k8s.conf
    content: |
      net.bridge.bridge-nf-call-ip6tables = 1
      net.bridge.bridge-nf-call-iptables = 1