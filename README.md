# TEALC CICD tooling
Collection of deployments and tools for continuous testing of applications

[![Verify](https://github.com/ExcelentProject/tealc/actions/workflows/verify.yaml/badge.svg)](https://github.com/ExcelentProject/tealc/actions/workflows/verify.yaml)

## First start
First step is to deploy tekton pipelines operator to cluster. You can achieve that by
```
ansible-playbook playbooks/tealc-play.yaml --tags=strimzi-infra
```


### Configuring scenario
```
ansible-playbook playbooks/tealc-play.yaml --tags=twitter-app
```


[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)


# TODO
- add example fo clusters and github secret