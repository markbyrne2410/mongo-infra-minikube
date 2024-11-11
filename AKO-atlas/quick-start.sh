#!/bin/bash
export AKO_namespace=mongodb-atlas-system

if [[ -z ${AKO_ORGID+x} ]]; then
  read -r -p "Please provide your Atlas Organization ID: " AKO_ORGID
fi

if [[ -z ${AKO_PROJID+x} ]]; then
  read -r -p "Please provide your Atlas Project ID: " AKO_PROJID
fi

if [[ -z ${AKO_PUBKEY+x} ]]; then
  read -r -p "Please provide your API Public Key: " AKO_PUBKEY
fi

if [[ -z ${AKO_PRIKEY+x} ]]; then
  read -r -p "Please provide your API Private Key: " AKO_PRIKEY
fi

if [[ -z ${AKO_PROJNAME+x} ]]; then
  read -r -p "Please provide your existing Project Name: " AKO_PROJNAME
fi

### Prompt for version

version_options=("v2.3.1" "v2.4.0" "v2.5.0" "custom" "Quit")
select opt in "${version_options[@]}"
do
  case $opt in
      v2.3.1)
      export AKO_version=v2.3.1
      break
      ;;
      v2.4.0)
      export AKO_version=v2.4.1
      break
      ;;
      v2.5.0)
      export AKO_version=v2.5.0
      break
      ;;
      custom)
      read -r AKO_version
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

### Setup Kubernetes Cluster

if ! minikube &> /dev/null
then 
  echo "Minikube could not be found, please install."
  exit 1
else
  minikube start --cpus=2 --memory=2G --disk-size=5000mb -p atlas --namespace $AKO_namespace
  echo "=== Kubernetes Setup ==="
  echo "- profile = atlas"
  echo "- CPUs = 2"
  echo "- Memory = 2G"
  echo "- Disk space= 5G" 
fi

### Setup Atlas CLI

if ! atlas &> /dev/null
then 
  echo "Atlas CLI not found attempting to download"
  echo Please choose a platform: 
  platform_options=("M1-Mac" "Intel-Mac" "Linux" "Linux-ARM" "Quit")
  select opt in "${platform_options[@]}"
  do
    case $opt in
        M1-Mac)
        echo "Downloading Atlas CLI for an M1/M2/Mxxx Mac"
        curl -L https://fastdl.mongodb.org/mongocli/mongodb-atlas-cli_1.23.0_macos_arm64.zip -o atlas-cli.zip
        mkdir atlas-cli
        unzip atlas-cli.zip -d atlas-cli
        break
        ;;
        Intel-Mac)
        echo "Downloading Atlas CLI for an Intel Mac"
        curl -L https://fastdl.mongodb.org/mongocli/mongodb-atlas-cli_1.23.0_macos_x86_64.zip -o atlas-cli.zip
        mkdir atlas-cli
        unzip atlas-cli.zip -d atlas-cli
        alias atlas=atlas-cli/bin/atlas
        break
        ;;
        Linux)
        echo "Downloading Atlas CLI for Linux"
        curl -L https://fastdl.mongodb.org/mongocli/mongodb-atlas-cli_1.23.0_linux_x86_64.tar.gz -o atlas-cli.tar.gz
        mkdir atlas-cli
        tar -xzf atlas-cli.tar.gz -C atlas-cli --strip-components=1
        alias atlas=atlas-cli/bin/atlas
        break
        ;;
        Linux-ARM)
        echo "Downloading Atlas CLI for Linux-ARM"
        curl -L https://fastdl.mongodb.org/mongocli/mongodb-atlas-cli_1.23.0_linux_arm64.rpm -o atlas-cli.tar.gz
        mkdir atlas-cli
        tar -xzf atlas-cli.tar.gz -C atlas-cli --strip-components=1
        alias atlas=atlas-cli/bin/atlas
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
fi


### Install the operator with Atlas CLI

echo "=== Using Atlas CLI to setup kubernetes operator"
kubectl apply -f https://raw.githubusercontent.com/mongodb/mongodb-atlas-kubernetes/$AKO_version/deploy/all-in-one.yaml
echo "Operator is installed"
echo ""
kubectl get pods -n $AKO_namespace

if (date +%F -d "+1 days") &> /dev/null
then
  AKO_KEEPUNTIL=$(date +%F -d "+1 days")
else
  AKO_KEEPUNTIL=$(date -v +1d +%F)
fi

# Generate our deployment yaml file
export AKO_KEEPUNTIL
awk -v AKO_ORGID="$AKO_ORGID" \
    -v AKO_PROJID="$AKO_PROJID" \
    -v AKO_PUBKEY="$AKO_PUBKEY" \
    -v AKO_PRIKEY="$AKO_PRIKEY" \
    -v AKO_PROJNAME="$AKO_PROJNAME" \
    -v AKO_IPACCESS=$(curl ipinfo.io/ip) \
    -v AKO_KEEPUNTIL="$AKO_KEEPUNTIL" \
    -f setup.awk deploy-a-cluster-template.yaml > deploy-a-cluster.yaml

# Generate our clean up file
awk -v AKO_PROJID="$AKO_PROJID" \
    -v AKO_PUBKEY="$AKO_PUBKEY" \
    -v AKO_PRIKEY="$AKO_PRIKEY" \
    -f cleanup.awk clean-up.template > clean-up.sh

#kubectl apply -f deploy-a-cluster.yaml
echo
echo "Cluster can been deployed using the command:"
echo "$ kubectl apply -f deploy-a-cluster.yaml"
echo
echo "Please modify the above file to your requirments before running"

exit 0