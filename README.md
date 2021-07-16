# TEALC CICD tooling
Collection of deployments and tools for continuous testing of applications

[![Verify](https://github.com/ExcelentProject/tealc/actions/workflows/verify.yaml/badge.svg)](https://github.com/ExcelentProject/tealc/actions/workflows/verify.yaml)

## First start
First step is to deploy tekton pipelines operator to cluster. You can achieve that by
```
./scripts/install-tekton.sh
```
Second step is to deploy argoCD and configure project which will handle deployment of all tekton pipelines and tasks.

### Deploying argoCD
```
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -n argocd -f ./argo/argo-secret.yaml
```

### Configuring TEALC-CI project
```
kubectl apply -f ./argo/projects/tealc-ci.yaml
```
With these config, all pipelines from `./pipelines` will be deployed. Be carefull to have all depending configurations in same file with correct sequence.

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
