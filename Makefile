ENABLE_LOGGING ?= false

all: install_infra twitter_app

install_infra:
	ansible-playbook playbooks/tealc-play.yaml --tags=strimzi-infra --extra-vars log_sensitive_data=$(ENABLE_LOGGING)

twitter_app:
	ansible-playbook playbooks/tealc-play.yaml --tags=twitter-app --extra-vars log_sensitive_data=$(ENABLE_LOGGING)

remove_infra:
	ansible-playbook playbooks/tealc-play.yaml --tags=teardown --extra-vars log_sensitive_data=$(ENABLE_LOGGING)

.PHONY: install_infra twitter_app remove_infra