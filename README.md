# Docker in Production using AWS - Jenkins

This project provides a Docker Jenkins image designed to run Docker Workflows.

## Quick Start

The Dockerfile is designed for minimum size and as such only installs Python packages as pre-built Python wheels.

To define Python packages that should be installed, edit the file `packages/requirements.txt`.

To build the Python packages run `make wheel`.  

This will use the [dpaws/wheel](http://github.com/dpaws/wheel) image to first compile all packages and their dependencies and output wheels to the `packages` folder.

## Running Jenkins

First, ensure you have run `make wheel` at least once before continuing.  

> You don't need to run `make wheel` everytime you run Jenkins, only if you need to update the Jenkins Python binary packages

Next, execute `make jenkins`, which will start Jenkins.

An external Docker volume called `jenkins_home` will be automatically created.

> If `jenkins_home` already exists, then Jenkins will start with the existing configuration in `jenkins_home`

```
$ make jenkins
=> Creating volumes...
jenkins_home
=> Starting services...
Creating jenkins_jenkins_1
=> Jenkins is running at http://172.16.154.128:32876...
=> Run make logs to get the one-time admin password if running for the first time
```

On first run or if the `jenkins_home` volume is empty, Jenkins will create an admin user with an initial password.  

This password is displayed on stdout, which you can view by running `make logs`.  

> Note that Jenkins can take 1-2 minutes to display the password

```
$ make logs
...
...
jenkins_1  | Sep 09, 2016 8:46:08 PM org.springframework.beans.factory.support.DefaultListableBeanFactory preInstantiateSingletons
jenkins_1  | INFO: Pre-instantiating singletons in org.springframework.beans.factory.support.DefaultListableBeanFactory@613921fd: defining beans [filter,legacy]; root of factory hierarchy
jenkins_1  | Sep 09, 2016 8:46:08 PM jenkins.install.SetupWizard init
jenkins_1  | INFO:
jenkins_1  |
jenkins_1  | *************************************************************
jenkins_1  | *************************************************************
jenkins_1  | *************************************************************
jenkins_1  |
jenkins_1  | Jenkins initial setup is required. An admin user has been created and a password generated.
jenkins_1  | Please use the following password to proceed to installation:
jenkins_1  |
jenkins_1  | ddf5f802d6af489789c63871eab9694e
jenkins_1  |
jenkins_1  | This may also be found at: /var/jenkins_home/secrets/initialAdminPassword
jenkins_1  |
jenkins_1  | *************************************************************
jenkins_1  | *************************************************************
jenkins_1  | *************************************************************
...
...
```

After obtaining the initial password, browse to URL output from `make jenkins` and enter the password at the Unlock Jenkins screen.

> `make jenkins` creates a dynamic port mapping on the Docker Host so if you kill and remove the jenkins container, it will likely start on a new dynamic port mapping as displayed on the `make jenkins` output

## Running Jenkins Slaves

Once you have setup your initial username and password for Jenkins, you can run one or more Jenkins slaves.

By default, the Makefile assumes you are using a username of `admin` and password of `password`:

```
$ cat Makefile
include Makefile.settings

.PHONY: init build run clean publish logs

DOCKER_REGISTRY ?= docker.io
ORG_NAME ?= dpaws
REPO_NAME ?= jenkins
export DOCKER_GID ?= 100
export JENKINS_USERNAME ?= admin
export JENKINS_PASSWORD ?= password
...
...
```

If you configure a different username and password, you must configure the Jenkins username and password as environment variables:

```
$ export JENKINS_USERNAME=admin
$ export JENKINS_PASSWORD=some-other-password
```

With this in place, you can use `make slave [slave-count]` to fire up `slave-count` slaves:

```
# This will spin up 5 Jenkins slaves
$ make slave 5
=> Checking network...
=> Creating volumes...
jenkins_home
=> Running 5 slave(s)...
Creating and starting cajenkins_jenkins-slave_1 ... done
Creating and starting cajenkins_jenkins-slave_2 ... done
Creating and starting cajenkins_jenkins-slave_3 ... done
Creating and starting cajenkins_jenkins-slave_4 ... done
Creating and starting cajenkins_jenkins-slave_5 ... done
=> 5 slave(s) running
```

## Stopping Jenkins

You can use `make clean` to stop and remove the Jenkins container.  This operation will NOT destroy your Jenkins configuration, which is persisted in the external `jenkins_home` volume.  

If you want to remove your Jenkins configuration, use the `docker volume rm jenkins_home` command to remove this volume:

```
$ make clean
=> Stopping services...
Stopping jenkins_jenkins-slave_1 ... done
Stopping jenkins_jenkins_1 ... done
Removing jenkins_jenkins-slave_1 ... done
Removing jenkins_jenkins_1 ... done
Removing network jenkins_default
Volume jenkins_home is external, skipping
=> Services stopped
$ docker volume rm jenkins_home
```

## Docker Group ID

Because the Jenkins container runs as a non-root user, to get access to the underlying Docker Engine socket to run Docker workflows, you must set the correct group ID of the `docker` group (or group that has permissions to read/write to the Docker Engine socket) on the underlying Docker Engine. 

The Makefile defines this via the `DOCKER_GID` variable, which defaults to `100` (the group ID currently used in Docker Machine boot2docker engines):

```
$ cat Makefile
include Makefile.settings

.PHONY: init build run clean publish logs

DOCKER_REGISTRY ?= docker.io
ORG_NAME ?= dpaws
REPO_NAME ?= jenkins
export DOCKER_GID ?= 100
...
```

You can either update the Makefile with the correct group ID value for your environment, or override the `Makefile` default by setting an environment variable:

```
$ export DOCKER_GID=999
$ make jenkins
```

Note that the `DOCKER_GID` value must be baked into the Jenkins image, so if you need to change this value, you will need to rebuild your Jenkins and slave images by running `make build`:

```
$ make build
=> Building image...
...
...
Successfully built faa90e6cd51d
=> Build complete
```
