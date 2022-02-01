FROM registry.fedoraproject.org/fedora-minimal:latest

RUN microdnf -y install skopeo git wget which maven ansible

RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" &&\
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

RUN wget https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz -O /tmp/oc.tar.gz &&\
    tar -xzf /tmp/oc.tar.gz -C /tmp &&\
    mv /tmp/oc /usr/bin/oc &&\
    chmod +x /usr/bin/oc

RUN wget https://github.com/mikefarah/yq/releases/download/v4.11.2/yq_linux_amd64 -O /usr/bin/yq &&\
    chmod +x /usr/bin/yq

RUN wget https://download-ib01.fedoraproject.org/pub/fedora/linux/releases/34/Everything/x86_64/os/Packages/g/git-crypt-0.6.0-10.fc34.x86_64.rpm -O /tmp/git-crypt.rpm &&\
    microdnf -y install /tmp/git-crypt.rpm

USER root