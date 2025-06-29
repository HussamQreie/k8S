# k8S
This Main repo for k8s.
---
vagrant up, ->(book) init, (fromHere-CommandFile) install cni on master node then (book) join workers. (goodluck)

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

##### example
```sh
sudo kubeadm join 10.0.2.15:6443 --token wsq7c1.4gemi4h4hp4ao0yn --discovery-token-ca-cert-hash sha256:bb26c4093de064eecd322694979a3e0ca276f475c6dd156598cc02179ca34afb
```
