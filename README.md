# Docker in Production using AWS - Jenkins

This project provides a Docker Jenkins image designed to run Docker Workflows.

## Running Jenkins

The fastest way to get started is to run `make jenkins`, which will automatically build and start Jenkins.

An external Docker volume called `jenkins_home` will be automatically created.

> If `jenkins_home` already exists, then Jenkins will start with the existing configuration in `jenkins_home`

```
$ make jenkins
=> Creating volumes...
jenkins_home
=> Starting services...
Creating jenkins_jenkins_1
=> Jenkins is running at http://172.16.154.128:32876...
```

> `make jenkins` creates a dynamic port mapping on the Docker Host so if you kill and remove the jenkins container, it will likely start on a new dynamic port mapping as displayed on the `make jenkins` output

If you need to make any changes to the Jenkins images, ensure you run `make build` to rebuild the images.

## Running Jenkins Slaves

Once Jenkins is running, you can run one or more Jenkins slaves.

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

You can either update the Makefile with the correct group ID value for your environment, or override the `Makefile` default:

```
$ make jenkins DOCKER_GID=497
...
...
$ make slave DOCKER_GID=497
...
...
```

The [`entrypoint.sh`](src/entrypoint.sh) script adds the `jenkins` user to the specify Docker Group ID, ensuring Jenkins can access the underlying Docker engine.
