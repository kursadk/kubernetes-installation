# Kubernetes Cluster Installation
* You can setup Kubernetes Cluster by running install_k8s.sh script which uses kubeadm
* You should run this script on the master node, and write connection information of nodes on servers.conf

#### Requirements
* Script must be run as root
* Connection must contain root user with password authentication  
* At least 2CPU per host
* At least 2GB RAM per host
* Hostnames of all hosts must be different from each other
