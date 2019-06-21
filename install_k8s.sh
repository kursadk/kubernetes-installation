#!/bin/bash

########################### Checking Requirements ###########################

# Warn user to check hostname of servers
while true; do
  echo    "********** Attention! **********"
  echo    "Hostname of All hosts must be different from each other."
  read -p "If it is, please press y: " yn

  case $yn in
    [Yy]* ) break;;
    [Nn]* ) exit;;
    *) echo;;
  esac
done

# Check Number of CPU

numberOfCpu=$(grep -c ^processor /proc/cpuinfo)

if [ "$numberOfCpu" -lt 2 ]
  then echo "Minimum number of CPU is 2"
  exit
fi

# Check Total Memory

totalMemory=$(free -m | awk '/^Mem:/{print $2}')
if [ "$totalMemory" -lt 2000 ]
  then echo "Memory must me greater than 2GB"
  exit
fi

# Check User

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

########################### Installing Docker ###########################
apt-get remove docker docker-engine docker.io containerd runc &&
apt-get update &&
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common &&

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &&

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable" &&

apt-get update &&
apt-get install -y docker-ce=18.06.2~ce~3-0~ubuntu &&

# Setup daemon.
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart docker.
systemctl daemon-reload
systemctl restart docker


########################### Installing Kubeadm Kubelet abd Kubectl ###########################

swapoff -a

apt-get update && apt-get install -y apt-transport-https curl &&
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - &&
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update &&
apt-get install -y kubelet kubeadm kubectl &&
apt-mark hold kubelet kubeadm kubectl &&


#Flannel will be used as network plugin

kubeadm init --pod-network-cidr=10.244.0.0/16 

JOIN_COMMAND=$(kubeadm token create --print-join-command)
echo "#################JOIN COMMAND##############"
echo $JOIN_COMMAND

export KUBECONFIG=/etc/kubernetes/admin.conf
sysctl net.bridge.bridge-nf-call-iptables=1
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml

#To enable scheduling pods on master, uncomment out the below line
#kubectl taint nodes --all node-role.kubernetes.io/master-


# Install sshpass to access nodes
apt-get -y install sshpass
# Read colon(:) seperated servers.conf
while IFS=: read xx yy zz tt;do
  # Skip commented lines
  case "$xx" in \#*) continue ;; esac
  echo $xx $yy $zz $tt
  sshpass -p $zz ssh -o StrictHostKeyChecking=no $yy@$xx << EOF
  apt-get remove docker docker-engine docker.io containerd runc;
  apt-get update;
  apt-get install -y apt-transport-https ca-certificates  curl  software-properties-common;
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -;
  add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable";
  apt-get update;
  apt-get install -y docker-ce=18.06.0~ce~3-0~ubuntu;
  
  # Setup daemon.
  cat > /etc/docker/daemon.json <<EOF
  {
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {
      "max-size": "100m"
    },
    "storage-driver": "overlay2"
  }
  EOF
  mkdir -p /etc/systemd/system/docker.service.d

  # Restart docker.
  systemctl daemon-reload
  systemctl restart docker
  
  swapoff -a

  apt-get update && apt-get install -y apt-transport-https curl;
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -;
  echo "deb https://apt.kubernetes.io/ kubernetes-xenial main"  >> /etc/apt/sources.list.d/kubernetes.list;

  apt-get update;
  apt-get install -y kubelet kubeadm kubectl;
  apt-mark hold kubelet kubeadm kubectl;
  $JOIN_COMMAND
EOF
done < ./servers.conf

