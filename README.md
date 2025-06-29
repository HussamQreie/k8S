# k8S
This Main repo for k8s.
---
vagrant up, ->(book) init, (fromHere-CommandFile) install cni on master node then (book) join workers. (goodluck)

---
##### Initlize Kubernetes using kubeadm

```sh
sudo kubeadm init --apiserver-advertise-address 10.0.0.10 --pod-network-cidr 192.168.0.1/16
```

##### Allow user interact with kubernetes cluster
```sh
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
##### Install CNI on master node
```sh
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
```




---

##### Get Token
```sh
kubeadm token -h
kubeadm token list
```

##### Get the CA cert hash
```sh
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'
```

##### Get the combination to join worker nodes into cluster
```sh
echo -e "\nkubeadm join $(hostname -I | awk '{print $1}'):6443 --token $(kubeadm token create) --discovery-token-ca-cert-hash sha256:$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')"
```

##### example (not working only for testing)
```sh
sudo kubeadm join 10.0.2.15:6443 --token wsq7c1.4gemi4h4hp4ao0yn --discovery-token-ca-cert-hash sha256:bb26c4093de064eecd322694979a3e0ca276f475c6dd156598cc02179ca34afb
```
##### example 2 (worked in that case)
```sh
sudo kubeadm join 10.0.0.10:6443 --token b0qfkj.q5um3b77qlebsvju \
	--discovery-token-ca-cert-hash sha256:66bcbd41bc075363f4833a3ab70785a4df814778c0e05d993033596a48f99e9f 
```
