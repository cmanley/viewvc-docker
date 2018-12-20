FROM debian:stretch-slim

LABEL Maintainer="Craig Manley https://github.com/cmanley" \
      Description="ViewVC 1.1.26-1 (CVS & SVN repository viewer) based on nginx and Debian stretch-slim"

RUN echo 'path-include /usr/share/doc/viewvc/examples/templates-contrib/newvc/*' >> /etc/dpkg/dpkg.cfg.d/docker \
	&& apt-get update && apt-get install -y \
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


### Configure mount points ####
RUN mkdir -p /opt/cvs /opt/svn && chgrp www-data /opt/cvs /opt/svn


### Configure viewvc ####
RUN mv /etc/viewvc/viewvc.conf /etc/viewvc/viewvc.conf.dist \
	#
	# Create theme subdirs (classic and default).
	&& mv /etc/viewvc/templates /etc/viewvc/templates-classic \
	&& mkdir -p /etc/viewvc/templates \
	&& mv /etc/viewvc/templates-classic /etc/viewvc/templates/classic \
	&& rm /etc/viewvc/templates/classic/docroot \
	&& mv /usr/share/viewvc/docroot /etc/viewvc/templates/classic/ \
	#&& ln -s /usr/share/doc/viewvc/examples/templates-contrib/newvc/templates /etc/viewvc/templates/default \
	&& mv /usr/share/doc/viewvc/examples/templates-contrib/newvc/templates /etc/viewvc/templates/default \
	#
	# Expand the "Powered by" signature in the template footers
	&& sed -Ei 's/(Powered by .+?<\/a>)/\1 in a Debian '$(cat /etc/debian_version)' based Docker container/' /etc/viewvc/templates/*/include/footer.ezt \
	#
	# Create a template subdir symlink "current" with target "default". The docker-entrypoint.sh can change it's target.
	&& $( cd /etc/viewvc/templates && ln -s default current ) \
	#
	# Add missing favicon to default (newvc) theme
	&& if [ ! -f /etc/viewvc/templates/default/docroot/images/favicon.ico ]; then \
		cp -l /etc/viewvc/templates/classic/docroot/images/favicon.ico /etc/viewvc/templates/default/docroot/images/favicon.ico \
		&& sed -i -- 's/<\/head>/  <link rel="shortcut icon" type="image\/x-icon" href="\[docroot\]\/images\/favicon.ico" \/>\n\0/' /etc/viewvc/templates/default/include/header.ezt \
		&& sed -i -- 's/<\/head>/  <link rel="shortcut icon" type="image\/x-icon" href="\/docroot\/images\/favicon.ico" \/>\n\0/' /etc/viewvc/templates/default/docroot/*.html; \
	fi


COPY copy /

EXPOSE 80
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["viewvc"]
