viewvc-docker
=============

A Docker image of ViewVC master ( a CVS and SVN repository viewer from http://www.viewvc.org )
based on nginx and Debian Stretch-slim, with configurable run-time options (theme, timezone, and group id).

You can use it to quickly and safely expose a web interface to the repositories directory on your host machine.

Installation
------------

### Option 1: Download image from hub.docker.com ###
You can simply pull this image from docker hub like this:

	docker pull cmanley/viewvc:debian-dev

### Option 2: Build the image yourself ###

	git clone <Link from "Clone or download" button>
	cd viewvc-docker
	docker build --rm -t cmanley/viewvc:debian-dev .

The docker build command must be run as root or as member of the docker group,
or else you'll get the error "permission denied while trying to connect to the Docker daemon socket".

Usage examples
--------------

Assuming that your cvs repository root directory on the host machine is `/var/lib/cvs`
and has the privileges 750 (user may read+write, group can only read, and others are denied),
and that you want viewvc be accessible on `127.0.0.1:8002`, then execute one of the commands below.
The available internal repository volume mount pounts are `/opt/cvs` and `/opt/svn`.
You may want to place your preferred command in an shell alias or script to not have to type it out each time.

Minimal:

	docker run --name viewvc -v /var/lib/cvs:/opt/cvs:ro -p 127.0.0.1:8002:80/tcp --rm -d cmanley/viewvc:debian-dev

Using both CVS and SVN repositories:

	docker run --name viewvc \
	-v /var/lib/cvs:/opt/cvs:ro \
	-v /var/lib/svn:/opt/svn:ro \
	-p 127.0.0.1:8002:80/tcp \
	--rm -d cmanley/viewvc:debian-dev

Recommended use (use the same time zone as the host):

	docker run --name viewvc \
	-v /var/lib/cvs:/opt/cvs:ro \
	-p 127.0.0.1:8002:80 \
	-e TZ=$(</etc/timezone) \
	--rm -d cmanley/viewvc:debian-dev

Explicitly specify which group id to use for reading the repository, and the timezone:

	docker run --name viewvc \
	-v /var/lib/cvs:/opt/cvs:ro \
	-p 127.0.0.1:8002:80/tcp \
	-e VIEWVC_GID=$(stat -c%g /var/lib/cvs) \
	-e TZ=$(</etc/timezone) \
	--rm -d cmanley/viewvc:debian-dev

Start container and a shell session within it (this does not start nginx):

	docker run --name viewvc \
	-v /var/lib/cvs:/opt/cvs:ro \
	-p 127.0.0.1:8002:80/tcp \
	--rm -it cmanley/viewvc:debian-dev shell

In case of problems, start the container without the --rm option, check your docker logs, and check that the container is running:

	docker logs viewvc
	docker ps

Stop the container using:

	docker stop viewvc

Remove the container (in case you didn't run it with the --rm option) using:

	docker rm viewvc

Runtime configuration
---------------------

### Using environment variables ###

You can configure how the container runs by passing some of the environment variables below using the --env or -e option to docker run.
Unless your host's repository is world-readable (which it shouldn't be), then you'll need to at least need to specify VIEWVC_GID.

| name             | description                                                                                                      |
|------------------|------------------------------------------------------------------------------------------------------------------|
| **VIEWVC_GID**   | The gid (group id) of the host repository directory. If not given, then the gid of the host volume will be used. |
| **VIEWVC_THEME** | Either "default" or "classic".                                                                                   |
| **TZ**           | Specify the time zone to use. Default is UTC. In most cases, use the value in the host's /etc/timezone file.     |

### Using override config files ###

Besides simply editing existing config files in the project and then rebuilding and running the project,
you can also create custom config files on you host machine and mount them into the container at run time.

#### Example: ####

If you want to use your own viewvc.conf file that exists on the host machine in path `/path/to/viewvc.conf`, then
simply mount it over the viewvc.conf file in the container (it's path is `/etc/viewvc/viewvc.conf`) at run time like this:
```shell
docker run --name viewvc \
-v /path/to/viewvc.conf:/etc/viewvc/viewvc.conf:ro \
-v /var/lib/cvs:/opt/cvs:ro \
-v /var/lib/svn:/opt/svn:ro \
-p 127.0.0.1:8002:80/tcp \
--rm -d cmanley/viewvc:debian-dev
```
Tip: Leave the -d (= detach = run in background) option off the first time you run your new command just to see if your change causes any errors.

Security information
--------------------

* nginx runs as www-data:www-data and forwards requests to fcgiwrap which executes the viewvc code.
* fcgiwrap runs with uid www-data and with the gid of the VIEWVC_GID environment variable if given, else with gid of the host volume.
* It's important to always protect your host's volume by adding the ":ro" attribute to the docker run -v option as in the examples above.
