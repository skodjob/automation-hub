# TEALC CICD tooling
Collection of deployments and tools for continuous testing of applications

[![Verify](https://github.com/ExcelentProject/tealc/actions/workflows/verify.yaml/badge.svg)](https://github.com/ExcelentProject/tealc/actions/workflows/verify.yaml)

## Requirements
```
ansible
```

### Deploy infra
First step is to deploy tekton pipelines operator to cluster. You can achieve that by

ansible
```
ansible-playbook install/ansible/tealc-play.yaml --tags=infra
ansible-playbook install/ansible/tealc-play.yaml --tags=rp
```

makefile
```
make install_infra install_rp
```

### Configuring scenario and test suite
ansible
```
ansible-playbook install/ansible/tealc-play.yaml --tags=strimzi-infra
ansible-playbook install/ansible/tealc-play.yaml --tags=twitter-app
ansible-playbook install/ansible/tealc-play.yaml --tags=test-suite
```

makefile
```
make install_strimzi twitter_app test_suite
```


### Show sensitive data during debugging ansible locally
```
ansible-playbook install/ansible/tealc-play.yaml --tags=strimzi-infra --extra-vars log_sensitive_data=true
```

### DevConf.cz 2022 presentation about TEALC in action
[![IMAGE ALT TEXT HERE](https://img.youtube.com/vi/oLAYig0zQgw/0.jpg)](https://www.youtube.com/watch?v=oLAYig0zQgw)


[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
