# mongo-infra-minikube
Deploy MongoDB software and tools into a local minikube environment

## Features

| Feature | Supported | Notes |
| --- | --- | --- |
| Atlas Kubernetes Operator | :heavy_check_mark: | `cd AKO-atlas` [README.md](/AKO-atlas/README.md) |
| Enterprise Kubernetes Operator - Ops Manager | :heavy_check_mark: | `cd MEKO-opsmanager` [README.md](/MEKO-opsmanager/README.md) |
| Enterprise Kubernetes Operator - Cloud Manager | :heavy_check_mark: | `cd MEKO-cloudmanager` [README.md](/MEKO-cloudmanager/README.md) |


## Changelog
- 2024-07-23 AKO and MEKO/Ops-Manager now support powershell (tested on Windows 11 and Linux `pwsh`)
- 2024-06-12 deploy cluster into a cloud manager project
- 2024-06-05 created repo and added ako code from our sister project [mongo-infra-docker](https://github.com/karl-denby/mongo-infra-docker)
