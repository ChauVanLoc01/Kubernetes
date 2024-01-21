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

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

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
sudo kubeadm init --apiserver-advertise-address=172.16.10.100 --pod-network-cidr=192.168.0.0/16 # --ignore-preflight-errors=all --v=5

#Sau đó thì thêm các worker node vào bằng câu lệnh được sinh ra từ việc khởi tạo control plane

#phải cài calico network thì mới xài được

#install calico network
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml
curl https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/custom-resources.yaml -O
kubectl create -f custom-resources.yaml

#Lỗi phổ biến
https://k21academy.com/docker-kubernetes/the-connection-to-the-server-localhost8080-was-refused/

cp /etc/kubernetes/admin.conf $HOME/
chown $(id -u):$(id -g) $HOME/admin.conf
export KUBECONFIG=$HOME/admin.conf

echo 'export KUBECONFIG=$HOME/admin.conf' >> $HOME/.bashrc

#######  SAU ĐÓ NẾU CÓ SAI SÓT GÌ THÌ CÁCH NHANH NHẤT (Tệ nhất) LÀ RESET LẠI TOÀN BỘ BẰNG CÂU LỆNH

## Reset kubeadm
kubeadm reset

## restart kubelet
systemctl restart kubelet



## sau thười gian lười gõ kubectl .... thì cài đặt sau để chỉ cần gõ k thì sẽ tự hiểu là kubectl
# Execute these commands
$ echo "source <(kubectl completion bash)" >> ~/.bashrc
$ echo "source <(kubeadm completion bash)" >> ~/.bashrc

# Reload bash without logging out
$ source ~/.bashrc 

kubeadm join 172.16.10.100:6443 --token 7iz72j.barnedx3f7231giv \
        --discovery-token-ca-cert-hash sha256:d5b3b1db715e6171ee7e3583e0a0b3896d5eb50abf79d37bea76edab5c607596



// Tren server

kubeadm join 10.148.0.4:6443 --token h58jcn.vfp9db75jwldciot \
        --discovery-token-ca-cert-hash sha256:a867e14ec0e7e2af29547c357bcf4d8390342c1ebf0bdaf188405873436d3519


kubeadm join 10.148.0.4:6443 --token ekvjdw.uvq8o923fqrdgg2x \
        --discovery-token-ca-cert-hash sha256:3d52bd357e0eb2e973e552cf83afcf2f8c9e12edd3e3f68011effaf323cbdf1c

sudo ufw allow 179/tcp
sudo ufw allow 4789/tcp
sudo ufw allow 5473/tcp
sudo ufw allow 443/tcp
sudo ufw allow 6443/tcp
sudo ufw allow 2379/tcp
sudo ufw allow 4149/tcp
sudo ufw allow 10250/tcp
sudo ufw allow 10255/tcp
sudo ufw allow 10256/tcp
sudo ufw allow 9099/tcp