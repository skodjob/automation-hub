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
cat << EOF | kubectl apply -n argocd -f -
apiVersion: v1
kind: Secret
metadata:
  labels:
    app.kubernetes.io/name: argocd-secret
    app.kubernetes.io/part-of: argocd
  name: argocd-secret
type: Opaque
stringData:
  admin.password: $(htpasswd -bnBC 10 "" password | tr -d ':\n')
  admin.passwordMtime: 2021-07-15T08:53:49CEST
EOF
```

### Configuring TEALC-CI project
```
kubectl apply -f ./argo/projects/
```
With these config, all pipelines from `./pipelines` will be deployed. Be carefull to have all depending configurations in same file with correct sequence.

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
