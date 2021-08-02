FROM registry.fedoraproject.org/fedora-minimal:latest

RUN microdnf -y install skopeo git

COPY ${PWD}/image-update.sh /tmp/image-update.sh

CMD ["/bin/bash", "/tmp/image-update.sh"]