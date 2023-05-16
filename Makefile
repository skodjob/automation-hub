all: install_infra install_strimzi twitter_app

install_infra:
	ansible-playbook install/tealc-play.yaml --tags=infra

install_strimzi:
	ansible-playbook install/tealc-play.yaml --tags=strimzi-infra

twitter_app:
	ansible-playbook install/tealc-play.yaml --tags=twitter-app

remove_infra:
	ansible-playbook install/tealc-play.yaml --tags=teardown

.PHONY: install_infra install_strimzi twitter_app remove_infra