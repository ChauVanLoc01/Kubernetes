#!/bin/bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay

sudo modprobe br_netfilter

lsmod | grep overlay

lsmod | grep br_netfilter

#  thiết lập các tham số sysctl, luôn tồn tại dù khởi động lại
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Áp dụng các tham số sysctl mà không cần khởi động lại
sudo sysctl --system

sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

sudo apt update -y && sudo apt upgrade -y

sudo apt-get install ca-certificates curl gnupg lsb-release

sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update

sudo apt-get install containerd.io

#config cgroup drivers
sudo vi /etc/containerd/config.toml

#after copy all content below into above file
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            SystemdCgroup = true
## nhớ là thay đổi toàn bộ nội dung file config.toml bằng nội dung trên

# restart to apply change
sudo systemctl restart containerd

#tắt swap
# Đầu tiên là tắt swap
sudo swapoff -a

# Sau đó tắt swap mỗi khi khởi động trong /etc/fstab
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

#Cập nhật apt package index và cài các package cần thiết để sử dụng trong Kubernetes apt repository
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

#Tải Google Cloud public signing key
sudo mkdir -m 0755 -p /etc/apt/keyrings
sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://dl.k8s.io/apt/doc/apt-key.gpg

#Thêm Kubernetes apt repository
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

#Cập nhật lại apt package index, cài đặt phiên bản mới nhất của kubelet, kubeadm và kubectl, ghim phiên bản hiện tại tránh việc tự động cập nhật
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

#Khởi tạo control plane
sudo kubeadm init --apiserver-advertise-address=your_ip_master --pod-network-cidr=192.168.0.0/16

#Sau đó thì thêm các worker node vào bằng câu lệnh được sinh ra từ việc khởi tạo control plane

#phải cài calico network thì mới xài được

#install calico network
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml
curl https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/custom-resources.yaml -O
kubectl create -f custom-resources.yaml