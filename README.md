# TEALC CI/CD tooling
Collection of deployments and tools for continuous testing of applications

## Requirements
```
ansible
oc/kubectl
podman/docker #in case you want to use ansible navigator
```

### Install tealc
ansible-playbook
```
cd install
ansible-galaxy collection install -r collections/requirements.yml
ansible-playbook tealc-play.yaml --tags=infra,strimzi-infra,twitter-app
```

makefile
```
ansible-galaxy collection install -r install/collections/requirements.yml
make install_infra install_strimzi twitter_app
```

ansible-navigator
```
cd install
ansible-navigator #default all tags
ansible-navigator run tealc-play.yaml --tags infra
```


### Show sensitive data during debugging ansible locally
```
ansible-playbook install/tealc-play.yaml --tags=strimzi-infra
#or
cd install
ansible-navigator run tealc-play.yaml
```

### DevConf.cz 2022 presentation about TEALC in action
[![TEALC_ON_DEVCONF](https://img.youtube.com/vi/oLAYig0zQgw/0.jpg)](https://www.youtube.com/watch?v=oLAYig0zQgw)


[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
