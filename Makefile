include Makefile.settings

.PHONY: init build clean publish log jenkins slave

# Jenkins settings
export DOCKER_GID ?= 0
export JENKINS_USERNAME ?= admin
export JENKINS_PASSWORD ?= password
export JENKINS_SLAVE_VERSION ?= 3.9
export JENKINS_SLAVE_LABELS ?= DOCKER

# AWS settings
# The role to assume to inject temporary credentials into your Jenkins container
AWS_ROLE ?= `aws configure get role_arn`
# KMS encrypted password - the temporary credentials must possess kms:decrypt permissions for the key used to encrypt the credentials
export KMS_JENKINS_PASSWORD ?=

init:
	${INFO} "Creating volumes..."
	@ docker volume create --name=jenkins_home

build:
	${INFO} "Building image..."
	@ docker-compose build --pull
	${INFO} "Build complete"

jenkins: init
	@ $(if $(and $(AWS_PROFILE),$(KMS_JENKINS_PASSWORD)),$(call assume_role,$(AWS_ROLE)),)
	${INFO} "Starting Jenkins..."
	${INFO} "This may take some time..."
	@ docker-compose up -d jenkins
	@ $(call check_service_health,$(RELEASE_ARGS),jenkins)
	${INFO} "Jenkins is running at http://$(DOCKER_HOST_IP):$(call get_port_mapping,jenkins,8080)..."

publish:
	${INFO} "Publishing images..."
	@ docker-compose push
	${INFO} "Publish complete"

slave:
	${INFO} "Checking Jenkins is healthy..."
	@ $(if $(and $(AWS_PROFILE),$(KMS_JENKINS_PASSWORD)),$(call assume_role,$(AWS_ROLE)),)
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
