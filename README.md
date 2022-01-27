# TEALC CICD tooling
Collection of deployments and tools for continuous testing of applications

[![Verify](https://github.com/ExcelentProject/tealc/actions/workflows/verify.yaml/badge.svg)](https://github.com/ExcelentProject/tealc/actions/workflows/verify.yaml)

## Requirements
```
ansible
```

### Deploy infra
First step is to deploy tekton pipelines operator to cluster. You can achieve that by
```
ansible-playbook playbooks/tealc-play.yaml --tags=infra
ansible-playbook playbooks/tealc-play.yaml --tags=rp
```

### Deploy strimzi argo projects
```
ansible-playbook playbooks/tealc-play.yaml --tags=strimzi-infra
```

### Configuring scenario and test suite
```
ansible-playbook playbooks/tealc-play.yaml --tags=twitter-app
ansible-playbook playbooks/tealc-play.yaml --tags=test-suite
```


### Show sensitive data during debugging ansible locally
```
ansible-playbook playbooks/tealc-play.yaml --tags=strimzi-infra --extra-vars log_sensitive_data=true
```

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
