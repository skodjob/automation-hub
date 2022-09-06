ENABLE_LOGGING ?= false

all: install_infra install_rp install_strimzi twitter_app test_suite

install_infra:
	ansible-playbook install/tealc-play.yaml --tags=infra --extra-vars log_sensitive_data=$(ENABLE_LOGGING)

install_strimzi:
	ansible-playbook install/tealc-play.yaml --tags=strimzi-infra --extra-vars log_sensitive_data=$(ENABLE_LOGGING)

twitter_app:
	ansible-playbook install/tealc-play.yaml --tags=twitter-app --extra-vars log_sensitive_data=$(ENABLE_LOGGING)

test_suite:
	ansible-playbook install/tealc-play.yaml --tags=test-suite --extra-vars log_sensitive_data=$(ENABLE_LOGGING)

remove_infra:
	ansible-playbook install/tealc-play.yaml --tags=teardown --extra-vars log_sensitive_data=$(ENABLE_LOGGING)

install_rp:
	ansible-playbook install/tealc-play.yaml --tags=rp --extra-vars log_sensitive_data=$(ENABLE_LOGGING)

remove_rp:
	ansible-playbook install/tealc-play.yaml --tags=teardown-rp --extra-vars log_sensitive_data=$(ENABLE_LOGGING)

.PHONY: install_infra install_strimzi twitter_app remove_infra