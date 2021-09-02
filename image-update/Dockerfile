FROM registry.fedoraproject.org/fedora-minimal:latest

RUN microdnf -y install skopeo git wget

RUN wget https://github.com/mikefarah/yq/releases/download/v4.11.2/yq_linux_amd64 -O /usr/bin/yq &&\
    chmod +x /usr/bin/yq
    
RUN mkdir -p /home/apophisuser/tealc/apophis

COPY ${PWD}/image-update.sh /home/apophisuser/tealc/apophis/image-update.sh

CMD ["/bin/bash", "/home/apophisuser/tealc/apophis/image-update.sh"]