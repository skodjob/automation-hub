# Automation Hub
Collection of deployments and tools for continuous testing of applications

## Requirements
```
ansible
oc
kubectl
jq
podman/docker #in case you want to use ansible navigator
```

### Install automation-hub
ansible-playbook
```
cd install
ansible-galaxy collection install -r collections/requirements.yml
ansible-playbook automation-hub-play.yaml --tags=infra,strimzi-infra
```

makefile
```
ansible-galaxy collection install -r install/collections/requirements.yml
make install_infra install_strimzi 
```

ansible-navigator
```
cd install
ansible-navigator #default all tags
ansible-navigator run automation-hub-play.yaml --senv ANSIBLE_RUN_TAGS=infra
```

### Testing United 2023 slides
[Testing United 2023](https://docs.google.com/presentation/d/1E2mBTQfsJybLtWnGRRpw-Xw5dohwRjXtsXgPq0_wpwk/edit?usp=sharing)

### DevConf.cz 2022 presentation about automation-hub in action
[![AUTOMATION_HUB_ON_DEVCONF](https://img.youtube.com/vi/oLAYig0zQgw/0.jpg)](https://www.youtube.com/watch?v=oLAYig0zQgw)

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
