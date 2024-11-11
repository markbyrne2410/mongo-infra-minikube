# Usage

## Example 1, Deploy OM and Replica Set

### 1. Setup Ops Manager

```
bash quick-start.sh # On Linux/Mac
powershell quick-start.ps1 # On Windows
```
- Notes: If you are on windows you might get an error if your not allowed to run scripts, you can allow them with this:
  - `Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser`

**Note:** This can take some time, maybe 6 or 7 minute (longer if your connection is slow). Wait for the output to show Ops Manager is running (like below). Then hit ctrl+c to get your prompt back. Maybe wait an additional minute or two.

```console
mongo-infra-minikube  1    7.0.8     Running    Running  Disabled    10m     
```

### 2. Validate that your Ops Manager is functioning

1. In a 2nd terminal `kubectl port-forward pod/mongo-infra-minikube-0 8080:8080`
2. Then visit http://localhost:8080 in your browser

#### Login to Ops Manager

- Username: admin
- Password: Passw0rd1!

### 3. Create an Organization, Project and Deployment

On Linux/Mac:
- `bash extras.sh`

On Windows:
- `powershell extras.ps1`

## Clean Up

This will remove the kubernetes cluster and with it Ops Manager and your database

On Linux/Mac:
`bash clean-up.sh`

On Windows:
- `powershell clean-up.ps1`

## Changelog
- 2024-07-22 Powershell is functionall equivalent to bash
- 2024-07-22 Start of windows/powershell support
- 2024-07-21 Support for machines with only 16GB of RAM
- 2024-07-19 Bring up any version of operator with Ops Manager 6.0.24
- 2024-06-14 Added zsh script, both bash|zsh prompt for missing values
