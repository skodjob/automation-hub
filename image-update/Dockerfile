FROM registry.fedoraproject.org/fedora-minimal:latest

RUN microdnf -y install skopeo git wget

RUN wget https://github.com/mikefarah/yq/releases/download/v4.11.2/yq_linux_amd64 -O /usr/bin/yq &&\
    chmod +x /usr/bin/yq

USER root