include Makefile.settings

.PHONY: init build run clean publish logs

DOCKER_REGISTRY ?= docker.io
ORG_NAME ?= dpaws
REPO_NAME ?= jenkins
export DOCKER_GID ?= 100
export JENKINS_USERNAME ?= admin
export JENKINS_PASSWORD ?= password
export JENKINS_SLAVE_VERSION ?= 2.2
export JENKINS_SLAVE_LABELS ?= DOCKER

init:
	${INFO} "Creating volumes..."
	@ docker volume create --name=jenkins_home

wheel:
	${INFO} "Creating wheels..."
	@ docker-compose up wheel
	@ docker-compose rm -v -f wheel
	${INFO} "Wheels created"

build:
	${INFO} "Building image..."
	@ docker-compose build --pull
	${INFO} "Build complete"

jenkins: init
	${INFO} "Starting services..."
	@ docker-compose up -d jenkins
	${INFO} "Jenkins is running at http://$(DOCKER_HOST_IP):$(call get_port_mapping,jenkins,8080)..."

publish:
	${INFO} "Publishing image..."
	@ docker tag $$(docker inspect -f '{{ .Image }}' $$(docker-compose ps -q jenkins)) $(DOCKER_REGISTRY)/$(ORG_NAME)/$(REPO_NAME)
	@ docker push $(DOCKER_REGISTRY)/$(ORG_NAME)/$(REPO_NAME)
	${INFO} "Publish complete"

slave: jenkins
	${INFO} "Running $(SLAVE_COUNT) slave(s)..."
	@ docker-compose scale jenkins-slave=$(SLAVE_COUNT)
	${INFO} "$(SLAVE_COUNT) slave(s) running"

clean:
	${INFO} "Stopping services..."
	@ docker-compose down -v || true
	${INFO} "Services stopped"

logs:
	${INFO} "Streaming Jenkins logs - press CTRL+C to exit..."
	@ docker-compose logs -f jenkins

# IMPORTANT - ensures arguments are not interpreted as make targets
%:
	@:
