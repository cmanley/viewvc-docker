FROM debian:stretch-slim

LABEL Maintainer="Craig Manley https://github.com/cmanley" \
      Description="ViewVC master (CVS & SVN repository viewer) based on nginx and Debian stretch-slim"

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
# Warning: No sha256sum check is performed because the master branch is being used
ARG VIEWVC_DOWNLOAD_FILE=master.zip
#ARG VIEWVC_DOWNLOAD_URL=https://github.com/viewvc/viewvc/archive/$VIEWVC_DOWNLOAD_FILE
ARG VIEWVC_DOWNLOAD_URL=https://github.com/cmanley/viewvc/archive/$VIEWVC_DOWNLOAD_FILE
RUN printf "\n########## Installing viewvc ##########\n" \
	&& mkdir -p /opt/cvs /opt/svn \
	&& chgrp www-data /opt/cvs /opt/svn \
	&& cd /tmp \
	&& wget -q "$VIEWVC_DOWNLOAD_URL" -O "$VIEWVC_DOWNLOAD_FILE" \
	\
	&& mkdir -p /usr/lib/viewvc/cgi-bin \
	&& unzip -jo "$VIEWVC_DOWNLOAD_FILE" viewvc-master/bin/cgi/viewvc.cgi -d /usr/lib/viewvc/cgi-bin/ \
	&& sed -Ei 's/^(LIBRARY_DIR =).*/\1 r"\/usr\/lib\/viewvc\/lib"/'      /usr/lib/viewvc/cgi-bin/viewvc.cgi \
	&& sed -Ei 's/^(CONF_PATHNAME =).*/\1 r"\/etc\/viewvc\/viewvc.conf"/' /usr/lib/viewvc/cgi-bin/viewvc.cgi \
	&& chmod 755 /usr/lib/viewvc/cgi-bin/viewvc.cgi \
	\
	&& unzip "$VIEWVC_DOWNLOAD_FILE" 'viewvc-master/lib/*' \
	&& mv viewvc-master/lib /usr/lib/viewvc/ \
	\
	&& mkdir -p /etc/viewvc \
	&& unzip -jo "$VIEWVC_DOWNLOAD_FILE" 'viewvc-master/conf/*' -d /etc/viewvc/ \
	&& mv /etc/viewvc/cvsgraph.conf.dist  /etc/viewvc/cvsgraph.conf \
	&& mv /etc/viewvc/mimetypes.conf.dist /etc/viewvc/mimetypes.conf \
	\
	&& unzip "$VIEWVC_DOWNLOAD_FILE" 'viewvc-master/templates/*' \
	&& mv viewvc-master/templates /etc/viewvc/ \
	&& sed -Ei 's/(Powered by .+?<\/a>)/\1 in a Debian '$(cat /etc/debian_version)' based Docker container/' /etc/viewvc/templates/*/include/footer.ezt \
	&& $( cd /etc/viewvc/templates && ln -s default current ) \
	\
	&& rm -fr viewvc-master "$VIEWVC_DOWNLOAD_FILE"


COPY copy /


EXPOSE 80
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["viewvc"]
