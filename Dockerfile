FROM debian:stretch-slim

LABEL Maintainer="Craig Manley https://github.com/cmanley" \
      Description="ViewVC 1.1.26-1 (CVS & SVN repository viewer) based on nginx and Debian stretch-slim"

RUN apt-get update && apt-get install -y \
	cvs \
	cvsgraph \
	fcgiwrap \
	mime-support \
	nginx-light \
	python-chardet \
	python-pygments \
	python-subversion \
	subversion \
	supervisor \
	viewvc \
	&& rm -rf /var/lib/apt/lists/*


### Configure viewvc ####
RUN mkdir -p /opt/cvs /opt/svn \
	&& chgrp www-data /opt/cvs /opt/svn \
	&& ln -s /usr/share/viewvc/docroot/images/favicon.ico /usr/share/viewvc/favicon.ico \
	&& mv /etc/viewvc/viewvc.conf /etc/viewvc/viewvc.conf.dist \
	&& DEBIAN_VERSION=$(cat /etc/debian_version) \
	&& sed -Ei 's/(<td>Powered by .+?<\/a>)/\1 in a Debian '$DEBIAN_VERSION' based Docker container/' /etc/viewvc/templates/include/footer.ezt


COPY copy /


EXPOSE 80
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["viewvc"]
