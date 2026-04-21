# Kubernetes TLS Setup for MongoDB Replica Set

## Prerequisites
- mdb-rs ReplicaSet and Search are already up and running which was performed using via the extras.sh script

---

## Setup Steps

### 1. Install cert-manager
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.19.1/cert-manager.yaml
```
Wait ~1 minute for the pods to be up and running.

---

### 2. Apply CA configuration
```bash
kubectl apply -f ca.yaml
```
- File location: `certs/ca.yaml`

---

### 3. Apply server certificate
```bash
kubectl apply -f server-cert.yaml
```
- File location: `certs/server-cert.yaml`

---

### 4. Extract CA certificate
```bash
kubectl get secrets -n mongodb mdb-mdb-rs-cert -o jsonpath="{.data['ca\.crt']}" | base64 -d > ca-pem
```

---

### 5. Create ConfigMap for CA
```bash
kubectl create configmap my-ca -n mongodb \
  --from-file=ca-pem=./ca-pem \
  --from-file=mms-ca.crt=./ca-pem
```

---

### 6. Apply agent certificate
```bash
kubectl apply -f agent-cert.yaml
```
- File location: `certs/agent-cert.yaml`

---

### 7. Apply TLS config for Replica Set
```bash
kubectl apply -f search_mdb_tls.yaml
```
- File location: `MEKO-OPSMANAGER/search_mdb_tls.yaml`

---

### 8. Apply TLS config for mongot
```bash
kubectl apply -f search_mongot_tls.yaml
```
- File location: `MEKO-OPSMANAGER/search_mongot_tls.yaml`

---

### 9. Deply the external service
```bash
kubectl apply -f external-svc.yaml
```
- File location: `MEKO-OPSMANAGER/external-svc.yaml`

---
### 10. Set up port forwarding (auto-restart on failure)

```bash
while true; do
  kubectl port-forward pod/mdb-rs-0 32017:27017
  echo "mdb-rs-0 crashed, restarting in 5 seconds..."
  sleep 5
done &

while true; do
  kubectl port-forward pod/mdb-rs-1 32018:27017
  echo "mdb-rs-1 crashed, restarting in 5 seconds..."
  sleep 5
done &

while true; do
  kubectl port-forward pod/mdb-rs-2 32019:27017
  echo "mdb-rs-2 crashed, restarting in 5 seconds..."
  sleep 5
done &

wait
```

---

### 11. Update `/etc/hosts`

Add the following entries to your local machine:

```
mdb-rs-0.localhost mdb-rs-1.localhost mdb-rs-2.localhost
```