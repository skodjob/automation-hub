# Automation Hub
Collection of deployments and tools for continuous testing of applications within Kubernetes

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

ansible-navigator
```
cd install
ansible-navigator #default all tags
ansible-navigator run automation-hub-play.yaml --senv ANSIBLE_RUN_TAGS=infra
```

### Kubernetes days Prague 2024
[![GITOPS_KUBECONF](https://img.youtube.com/vi/GUXq418JeBo/0.jpg)](https://youtu.be/GUXq418JeBo?si=l1ma0AQ5tbmYMKnP)

### Testing United 2023 slides
[Testing United 2023](https://docs.google.com/presentation/d/1E2mBTQfsJybLtWnGRRpw-Xw5dohwRjXtsXgPq0_wpwk/edit?usp=sharing)

### DevConf.cz 2022 presentation about automation-hub in action
[![AUTOMATION_HUB_ON_DEVCONF](https://img.youtube.com/vi/oLAYig0zQgw/0.jpg)](https://www.youtube.com/watch?v=oLAYig0zQgw)

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
