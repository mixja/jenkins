include Makefile.settings

.PHONY: init build clean publish log jenkins slave

DOCKER_REGISTRY ?= docker.io
ORG_NAME ?= dpaws
REPO_NAME ?= jenkins

# AWS settings
AWS_ROLE ?= 
KMS_KEY_ID ?= 
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN

# Jenkins settings
export DOCKER_GID ?= 100
export JENKINS_USERNAME ?= admin
export JENKINS_PASSWORD ?= password
export KMS_JENKINS_PASSWORD
export JENKINS_SLAVE_VERSION ?= 2.2
export JENKINS_SLAVE_LABELS ?= DOCKER

init:
	${INFO} "Creating volumes..."
	@ docker volume create --name=jenkins_home

build:
	${INFO} "Building image..."
	@ docker-compose build --pull
	${INFO} "Build complete"

secret:
	$(if $(ARGS),,$(error ERROR: You must specify a plaintext string to encrypt - e.g. make secret "Hello"))
	${INFO} "Encrypted ciphertext:"
	@ aws kms encrypt --key-id ${KMS_KEY_ID} --plaintext '$(ARGS)' | jq '.CiphertextBlob' -r

jenkins: init
	@ $(if $(AWS_ROLE),$(call assume_role,$(AWS_ROLE)),)
	${INFO} "Starting Jenkins..."
	${INFO} "This may take some time..."
	@ docker-compose up -d jenkins
	@ $(call check_service_health,$(RELEASE_ARGS),jenkins)
	${INFO} "Jenkins is running at http://$(DOCKER_HOST_IP):$(call get_port_mapping,jenkins,8080)..."

jenkins-local: AWS_ROLE =
jenkins-local: KMS_JENKINS_PASSWORD =
jenkins-local: jenkins
publish:
	${INFO} "Publishing image..."
	@ docker tag $$(docker inspect -f '{{ .Image }}' $$(docker-compose ps -q jenkins)) $(DOCKER_REGISTRY)/$(ORG_NAME)/$(REPO_NAME)
	@ docker push $(DOCKER_REGISTRY)/$(ORG_NAME)/$(REPO_NAME)
	${INFO} "Publish complete"

slave:
	${INFO} "Checking Jenkins is healthy..."
	@ $(if $(AWS_ROLE),$(call assume_role,$(AWS_ROLE)),)
	@ $(call check_service_health,$(RELEASE_ARGS),jenkins)
	${INFO} "Starting $(SLAVE_COUNT) slave(s)..."
	@ docker-compose up -d --scale jenkins-slave=$(SLAVE_COUNT)
	${INFO} "$(SLAVE_COUNT) slave(s) running"

clean:
	${INFO} "Stopping services..."
	@ docker-compose down -v || true
	${INFO} "Services stopped"

destroy: clean
	${INFO} "Deleting jenkins home volume..."
	@ docker volume rm -f jenkins_home
	${INFO} "Deletion complete"

log:
	${INFO} "Streaming Jenkins logs - press CTRL+C to exit..."
	@ docker-compose logs -f jenkins

# IMPORTANT - ensures arguments are not interpreted as make targets
%:
	@:
