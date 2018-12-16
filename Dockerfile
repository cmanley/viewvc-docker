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
	rcs \
	subversion \
	supervisor \
	wget \
	zip \
	&& rm -rf /var/lib/apt/lists/*


### viewvc master ###
ARG VIEWVC_DOWNLOAD_FILE=master.zip
ARG VIEWVC_DOWNLOAD_URL=https://github.com/viewvc/viewvc/archive/$VIEWVC_DOWNLOAD_FILE
RUN printf "\n########## Installing viewvc ##########\n" \
	&& mkdir -p /opt/cvs /opt/svn \
	&& chgrp www-data /opt/cvs /opt/svn \
	&& cd /tmp \
	&& wget -q "$VIEWVC_DOWNLOAD_URL" -O "$VIEWVC_DOWNLOAD_FILE" \
	&& unzip "$VIEWVC_DOWNLOAD_FILE" 'viewvc-master/bin/*' 'viewvc-master/conf/*' 'viewvc-master/lib/*' 'viewvc-master/templates/*' \
	&& mkdir -p /usr/lib/viewvc/cgi-bin \
	&& mv viewvc-master/bin/cgi/viewvc.cgi /usr/lib/viewvc/cgi-bin/ \
	&& chmod 755 /usr/lib/viewvc/cgi-bin/viewvc.cgi \
	&& sed -Ei 's/^(LIBRARY_DIR =).*/\1 r"\/usr\/lib\/viewvc\/lib"/'      /usr/lib/viewvc/cgi-bin/viewvc.cgi \
	&& sed -Ei 's/^(CONF_PATHNAME =).*/\1 r"\/etc\/viewvc\/viewvc.conf"/' /usr/lib/viewvc/cgi-bin/viewvc.cgi \
	&& mkdir -p /etc/viewvc \
	&& mv viewvc-master/conf/cvsgraph.conf.dist /etc/viewvc/cvsgraph.conf \
	&& mv viewvc-master/conf/mimetypes.conf.dist /etc/viewvc/mimetypes.conf \
	#&& mv viewvc-master/conf/viewvc.conf.dist /etc/viewvc/ \
	&& mv viewvc-master/templates /etc/viewvc/ \
	&& mv viewvc-master/lib /usr/lib/viewvc/ \
	&& rm -fr viewvc-master "$VIEWVC_DOWNLOAD_FILE" \
	&& mkdir -p /usr/share/viewvc/ \
	&& ln -s /etc/viewvc/templates/default /etc/viewvc/templates/current \
	&& ln -s /etc/viewvc/templates/current/docroot /usr/share/viewvc/ \
	#&& ln -s /usr/share/viewvc/docroot/images/favicon.ico /usr/share/viewvc/favicon.ico \
	&& if ! [ -f /etc/viewvc/templates/default/docroot/images/favicon.ico ]; then cp /etc/viewvc/templates/classic/docroot/images/favicon.ico /etc/viewvc/templates/default/docroot/images/favicon.ico; fi \
	&& ln -s /usr/share/viewvc/docroot/images/favicon.ico /usr/share/viewvc/favicon.ico \
	&& sed -Ei 's/(Powered by .+?<\/a>)/\1 in a Debian '$(cat /etc/debian_version)' based Docker container/' /etc/viewvc/templates/*/include/footer.ezt


COPY copy /


EXPOSE 80
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["viewvc:debian"]
