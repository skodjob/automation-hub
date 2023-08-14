all: install_infra install_strimzi

install_infra:
	ansible-playbook install/tealc-play.yaml --tags=infra

install_strimzi:
	ansible-playbook install/tealc-play.yaml --tags=strimzi-infra

remove_infra:
	ansible-playbook install/tealc-play.yaml --tags=teardown

.PHONY: install_infra install_strimzi remove_infra
