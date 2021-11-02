# TEALC CICD tooling
Collection of deployments and tools for continuous testing of applications

[![Verify](https://github.com/ExcelentProject/tealc/actions/workflows/verify.yaml/badge.svg)](https://github.com/ExcelentProject/tealc/actions/workflows/verify.yaml)


## First start
First step is to deploy tekton pipelines operator to cluster. You can achieve that by
```
./scripts/install-cicd.sh
```

### Configuring deployment cluster
Down below you can see, that cluster secret is requirement for tealc projects to run. We highly reccomend you to create service account 
on deployment cluster so token never expires as standard oauth token which will expire in some time.
To be able to do that you can use our example service account configuration:
```
kubectl apply -f pipelines/cluster/cluster_sa.yaml -n kube-system
```
To dig token out for your deployemnt you should run:
```
name=$(kubectl get sa -n kube-system argocd-manager -o jsonpath='{.secrets[0].name}')
export TOKEN=$(kubectl get -n kube-system secret/$name -o jsonpath='{.data.token}' | base64 --decode)
```
Your token will be stored in `TOKEN` environment variable.

### Configuring TEALC-CI project
First step for TEALC-CI configuration should be create secret for your deployment cluster. In our example you can see we have created cluster secret
which can looks like:
```
apiVersion: v1
kind: Secret
metadata:
  name: tealc-aws
  labels:
    argocd.argoproj.io/secret-type: cluster
type: Opaque
stringData:
  name: tealc-aws
  server: SERVER-URI
  config: |
    {
      "bearerToken": "TOKEN",
      "tlsClientConfig": {
        "insecure": true
      }
    }
```
You can see that `tealc-aws` name corresponds with cluster names in `argo/projects/strimzi.yaml`. So whatever secret you create names must match.

With created cluster secret you can now deploy tealc-ci project by executing:
```
kubectl apply -f ./argo/projects/
```
With these config, all pipelines from `./pipelines` will be deployed. Be carefull to have all depending configurations in same file with correct sequence.

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
