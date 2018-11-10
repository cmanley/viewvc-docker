FROM debian:stretch-slim

LABEL Maintainer="Craig Manley https://github.com/cmanley" \
      Description="ViewVC 1.1.26-1 (CVS repository viewer) using nginx, fcgiwrap, and Debian stretch-slim"

RUN apt-get update && apt-get install -y \
	cvs \
	cvsgraph \
	fcgiwrap \
	mime-support \
	nginx-light \
	python-chardet \
	python-pygments \
	subversion \
	supervisor \
	viewvc \
	&& rm -rf /var/lib/apt/lists/*


### Configure viewvc ####
RUN mkdir -p /opt/cvs /opt/svn \
	&& chgrp www-data /opt/cvs /opt/svn \
	#&& mkdir -p /var/www/viewvc/cgi-bin \
	#&& ln -s /usr/lib/viewvc/cgi-bin/viewvc.cgi /var/www/viewvc/cgi-bin/viewvc.cgi \
	#&& ln -s /usr/share/viewvc/docroot /var/www/viewvc/docroot \
	#&& ln -s /usr/share/viewvc/docroot/images/favicon.ico /var/www/viewvc/favicon.ico \
	&& ln -s /usr/share/viewvc/docroot/images/favicon.ico /usr/share/viewvc/favicon.ico \
	&& mv /etc/viewvc/viewvc.conf /etc/viewvc/viewvc.conf.dist


COPY copy /


EXPOSE 80
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["viewvc:debian"]
