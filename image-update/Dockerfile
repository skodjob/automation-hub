FROM registry.fedoraproject.org/fedora-minimal:latest

RUN microdnf -y install skopeo git wget which maven ansible git-crypt python3 python3-pip jq

RUN pip install --upgrade openshift kubernetes

RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" &&\
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

RUN wget https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz -O /tmp/oc.tar.gz &&\
    tar -xzf /tmp/oc.tar.gz -C /tmp &&\
    mv /tmp/oc /usr/local/bin/oc &&\
    chmod +x /usr/local/bin/oc

RUN wget https://github.com/mikefarah/yq/releases/download/v4.23.1/yq_linux_amd64 -O /usr/local/bin/yq &&\
    chmod +x /usr/local/bin/yq

RUN curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash &&\
     mv kustomize /usr/local/bin/

USER root
