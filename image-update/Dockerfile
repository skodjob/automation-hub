FROM fedora:latest

RUN sudo dnf -y install skopeo git

COPY ${PWD}/image-update.sh /tmp/image-update.sh

CMD ["/bin/bash", "/tmp/image-update.sh"]