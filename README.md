# Kubernetes Cluster Installation
* Bu repoda bulunan install-k8s.sh dosyası, kubeadm aracılığıyla kubernetes clusterı kurulumu yapar.
* Script master node'da çalıştırılır. Kurulum yapılacak olan node'ların erişim bilgileri servers.conf adlı dosyada belirtilir.

#### Gereksinimler
* Script root olarak çalıştırılmalı
* Node'lara root üzerinden parola ile erişilmeli
* Tüm makinelerde en az 2 CPU (core) bulunmalı
* En az 2GB ram olmalı
* Tüm makinelerin hostname'leri birbirlerinden farklı olmalı
