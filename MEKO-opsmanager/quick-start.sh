#!/bin/bash

export MEKO_namespace=mongodb

### Prompt for memory
echo "How much memory have you given to docker (ignore on linux)"
memory_options=("8GB" "16GB" "32GB" "64GB")
select opt in "${memory_options[@]}"
do
  case $opt in
      8GB)
      export minikube_memory=7900mb
      # 7900MB = 7534Mi
      export om_om_memory="4500Mi"
      export om_appdb_memory="700Mi"
      export deploy_mem="700Mi"
      break
      ;;
      16GB)
      export minikube_memory=15800mb
      export om_om_memory="5500Mi"
      export om_appdb_memory="900Mi"
      export deploy_mem="900Mi"
      break
      ;;
      32GB)
      export minikube_memory=31900mb
      export om_om_memory="6000Mi"
      export om_appdb_memory="1200Mi"
      export deploy_mem="1200Mi"
      break
      ;;
      64GB)
      export minikube_memory=63800mb
      export om_om_mem="6000GM"
      export om_appdb_mem="12000Mi"
      export deploy_mem="1200Mi"
      break
      ;;
      *)
      echo "Invalid option"
      ;;
  esac
done


### Prompt for operator version
echo "Select a version of the MEKO/MCK operator"
operator_options=("1.26.0" "1.25.0" "1.24.0" "custom" "Quit")
select opt in "${operator_options[@]}"
do
  case $opt in
      1.26.0)
      export MEKO_version=1.26.0
      break
      ;;
      1.25.0)
      export MEKO_version=1.25.0
      break
      ;;
      1.24.0)
      export MEKO_version=1.24.0
      break
      ;;
      custom)
      read -r MEKO_version
      break
      ;;
      Quit)
      echo "Bye."
      break
      ;;
      *)
      echo "Invalid option"
      ;;
  esac
done

# --- Operator Version MEKO/MCK check logic ---
# --- If a user enters a version between 1.20.0 - 1.33.0, they want MEKO, otherwise assume its a MCK version. ---
lower="1.20.0"
upper="1.33.0"

version_between() {
    local version="$1"
    local lower="$2"
    local upper="$3"
    [[ "$(printf '%s\n' "$lower" "$version" | sort -V | head -n1)" == "$lower" ]] &&
    [[ "$(printf '%s\n' "$version" "$upper" | sort -V | head -n1)" == "$version" ]]
}

if version_between "$MEKO_version" "$lower" "$upper"; then
    export MEKO=true
else
    export MEKO=false
fi

if [ "$MEKO" = true ]; then
    URL_PATH="mongodb-enterprise-kubernetes"
else
    URL_PATH="mongodb-kubernetes"
fi

# --- Version check logic ---

echo "Which version of Ops Manager would you like to install"
opsman_options=("7.0.8" "6.0.24" "custom" "Quit")
select opt in "${opsman_options[@]}"
do
  case $opt in
      7.0.8)
      export OM_VERSION=7.0.8
      break
      ;;
      6.0.24)
      export OM_VERSION=6.0.24
      break
      ;;
      custom)
      read -r OM_VERSION
      break
      ;;
      Quit)
      echo "Bye."
      exit
      ;;
      *)
      echo "Invalid option"
      exit
      ;;
  esac
done

# check if the minikube command is available and setup our cluser/profile
if ! minikube &> /dev/null
then 
  echo "Minikube could not be found, please install."
  exit 1
else
  minikube start --cpus=4 --memory="$minikube_memory" --disk-size=60000mb -p opsmanager --namespace $MEKO_namespace
fi

# check for kubectl
if ! kubectl &> /dev/null
then
  echo "kubectl not found, please install it, or alias kubectl='minikube kubectl' to use the one bundled with minikube"
  exit 1
else
  echo "Installing the operator into the mongodb namespace"
  kubectl create namespace mongodb
  if $MEKO == 1
  then
    kubectl apply -f https://raw.githubusercontent.com/mongodb/mongodb-enterprise-kubernetes/$MEKO_version/crds.yaml
    kubectl apply -f https://raw.githubusercontent.com/mongodb/mongodb-enterprise-kubernetes/$MEKO_version/mongodb-enterprise.yaml
    kubectl describe deployments mongodb-enterprise-operator -n $MEKO_namespace
  else
    kubectl apply -f https://raw.githubusercontent.com/mongodb/mongodb-kubernetes/$MEKO_version/public/mongodb-kubernetes.yaml
    kubectl apply -f https://raw.githubusercontent.com/mongodb/mongodb-kubernetes/$MEKO_version/public/crds.yaml
    kubectl describe deployments mongodb-kubernetes-operator -n $MEKO_namespace
  fi
fi

# Generate our deployment yaml file
awk -v OM_VERSION="$OM_VERSION" \
    -v om_om_memory="$om_om_memory" \
    -v om_appdb_memory="$om_appdb_memory" \
    -f scripts/options.awk templates/deploy-om.template > deploy-om.yaml

awk -v deploy_mem="$deploy_mem" \
    -f scripts/deployment.awk templates/deploy-mdb.template > deploy-mdb.yaml

export MONGO_INFRA_MINIKUBE_IP=127.0.0.1
MONGO_INFRA_MINIKUBE_IP=`minikube ip -p opsmanager`

kubectl apply -f deploy-om.yaml
echo
kubectl get om -w
