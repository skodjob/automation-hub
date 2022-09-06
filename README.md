# TEALC CICD tooling
Collection of deployments and tools for continuous testing of applications

[![Verify](https://github.com/ExcelentProject/tealc/actions/workflows/verify.yaml/badge.svg)](https://github.com/ExcelentProject/tealc/actions/workflows/verify.yaml)

## Requirements
```
ansible
podman/docker #in case you want to use ansible navigator
```

### Install tealc
ansible-playbook
```
cd install
ansible-galaxy collection install -r collections/requirements.yml
ansible-playbook tealc-play.yaml --tags=infra,rp,strimzi-infra,twitter-app,test-suite
```

makefile
```
ansible-galaxy collection install -r install/collections/requirements.yml
make install_infra install_rp install_strimzi twitter_app test_suite
```

ansible-navigator
```
cd install
ansible-navigator #default all tags
ansible-navigator --tags infra
```

By default, installation of operators on ifra cluster is disabled due to not sufficient rights.
If you have those rights, you can force operators installation by tag `admin-access`.


### Show sensitive data during debugging ansible locally
```
ansible-playbook install/ansible/tealc-play.yaml --tags=strimzi-infra --extra-vars log_sensitive_data=true
#or
ansible-navigator --extra-vars log_sensitive_data=true
```

### DevConf.cz 2022 presentation about TEALC in action
[![TEALC_ON_DEVCONF](https://img.youtube.com/vi/oLAYig0zQgw/0.jpg)](https://www.youtube.com/watch?v=oLAYig0zQgw)


[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
