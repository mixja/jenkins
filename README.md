# Docker in Production using AWS - Jenkins

This project provides a Docker Jenkins image.

## Quick Start

The Dockerfile is designed for minimum size and as such only installs Python packages as pre-built wheels.

To define Python packages that should be installed, edit the file `packages/requirements.txt`.

To build this image run `make build`.  

This will use the [docker-production-aws/wheel](http://github.com/docker-production-aws/wheel) image to first compile all packages and their dependencies and output wheels to the `packages` folder.  

## Running Jenkins for the First Time

First, ensure you have run `make build` before continuing.

Next, execute `make run`, which will start Jenkins.

An external Docker volume called `jenkins_home` will be automatically created.

> If `jenkins_home` already exists, then Jenkins will start with the existing configuration in `jenkins_home`

```
$ make run
=> Creating volumes...
jenkins_home
=> Starting services...
Creating jenkins_jenkins_1
=> Services running
```

On first run or if the `jenkins_home` volume is empty, Jenkins will create an admin user with an initial password.  This password is displayed on stdout, which you can view by running `make logs`.  

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

After obtaining the initial password, browse to http://docker-host-ip:8080 and enter the password at the Unlock Jenkins screen.