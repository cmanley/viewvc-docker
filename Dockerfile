FROM alpine:3.8

LABEL Maintainer="Craig Manley https://github.com/cmanley" \
      Description="ViewVC master (CVS & SVN repository viewer) based on nginx and Alpine 3.8"

RUN apk update && apk --no-cache add \
	cvs \
	fcgiwrap \
	nginx \
	python3 \
	py-subversion \
	py-chardet \
	py-pygments \
	shadow \
	spawn-fcgi \
	subversion \
	supervisor \
	tzdata \
	&& apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/ rcs
# Note: the last package (rcs) doesn't exist in 3.8 yet

# Use the same fcgiwrap path as in Debian so that the same supervisord.conf file can be used
RUN ln -s /usr/bin/fcgiwrap /usr/sbin/fcgiwrap

# Add the Debian default user required by nginx and fcgiwrap
RUN adduser -D -S -u 82 -h /var/www -G www-data www-data

# Add the repository mount points
RUN mkdir -p /opt/cvs /opt/svn && chgrp www-data /opt/cvs /opt/svn

### cvsgraph (optional) ###
ARG CVSGRAPH_VERSION=1.7.0
ARG CVSGRAPH_BASENAME=cvsgraph-$CVSGRAPH_VERSION
ARG CVSGRAPH_DOWNLOAD_FILE=$CVSGRAPH_BASENAME.tar.gz
#ARG CVSGRAPH_DOWNLOAD_URL=http://www.akhphd.au.dk/~bertho/cvsgraph/release/$CVSGRAPH_DOWNLOAD_FILE
ARG CVSGRAPH_DOWNLOAD_URL=https://github.com/cmanley/viewvc-docker/raw/alpine/$CVSGRAPH_DOWNLOAD_FILE
ARG CVSGRAPH_DOWNLOAD_SHA256=74438faaefd325c7a8ed289ea5d1657befe1d1859d55f8fbbcc7452f4efd435f
RUN printf "\n########## Building cvsgraph ##########\n" \
	&& cd /tmp \
	&& wget -q "$CVSGRAPH_DOWNLOAD_URL" -O "$CVSGRAPH_DOWNLOAD_FILE" \
	&& sha256sum "$CVSGRAPH_DOWNLOAD_FILE" \
	&& echo "$CVSGRAPH_DOWNLOAD_SHA256  $CVSGRAPH_DOWNLOAD_FILE" | sha256sum -c - \
	&& tar -xf "$CVSGRAPH_DOWNLOAD_FILE" \
	&& rm -fr "$CVSGRAPH_DOWNLOAD_FILE" \
	&& cd "$CVSGRAPH_BASENAME" \
	&& apk --no-cache add libgd \
	&& NEED='byacc flex gd-dev g++ make freetype-dev libjpeg-turbo-dev libpng-dev libwebp-dev' \
	&& DEL='' \
	&& for x in $NEED; do \
		apk list "$x"; \
		if [ $(apk list "$x" | grep -F [installed] | wc -l) -eq 0 ]; then \
			DEL="$DEL $x" \
			&& echo "Add temporary package $x" \
			&& apk --no-cache add $x; \
		fi; \
		echo $?; \
	done \
	&& ./configure --prefix=/usr sysconfdir=/etc/cvsgraph --disable-nls \
	&& make --quiet install \
	&& mkdir -p /etc/cvsgraph \
	&& cp cvsgraph.conf /etc/cvsgraph/ \
	&& cd - \
	&& rm -fr "$CVSGRAPH_BASENAME" \
	&& rm -fr /usr/share/man \
	&& if [ -n "$DEL" ]; then echo "Delete temporary package(s) $DEL" && apk del $DEL; fi


### viewvc master ###
# Warning: No sha256sum check is performed because the master branch is being used
ARG VIEWVC_DOWNLOAD_FILE=master.zip
#ARG VIEWVC_DOWNLOAD_URL=https://github.com/viewvc/viewvc/archive/$VIEWVC_DOWNLOAD_FILE
ARG VIEWVC_DOWNLOAD_URL=https://github.com/cmanley/viewvc/archive/$VIEWVC_DOWNLOAD_FILE
RUN printf "\n########## Installing viewvc ##########\n" \
	&& cd /tmp \
	&& wget -q "$VIEWVC_DOWNLOAD_URL" -O "$VIEWVC_DOWNLOAD_FILE" \
	\
	&& NEED='binutils zip' \
	&& DEL='' \
	&& for x in $NEED; do \
		if [ $(apk list "$x" | grep -F [installed] | wc -l) -eq 0 ]; then \
			DEL="$DEL $x" \
			&& echo "Add temporary package $x" \
			&& apk --no-cache add $x; \
		fi; \
	done \
	\
	&& mkdir -p /usr/lib/viewvc/cgi-bin \
	&& unzip -jo "$VIEWVC_DOWNLOAD_FILE" viewvc-master/bin/cgi/viewvc.cgi -d /usr/lib/viewvc/cgi-bin/ \
	&& chmod 755 /usr/lib/viewvc/cgi-bin/viewvc.cgi \
	&& sed -Ei 's/^(LIBRARY_DIR =).*/\1 r"\/usr\/lib\/viewvc\/lib"/'      /usr/lib/viewvc/cgi-bin/viewvc.cgi \
	&& sed -Ei 's/^(CONF_PATHNAME =).*/\1 r"\/etc\/viewvc\/viewvc.conf"/' /usr/lib/viewvc/cgi-bin/viewvc.cgi \
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
	&& sed -Ei 's/(Powered by .+?<\/a>)/\1 in an Alpine '$(cat /etc/alpine-release)' based Docker container/' /etc/viewvc/templates/*/include/footer.ezt \
	&& $( cd /etc/viewvc/templates && ln -s default current ) \
	\
	&& mkdir -p /usr/share/viewvc/ \
	&& ln -s /etc/viewvc/templates/current/docroot /usr/share/viewvc/ \
	\
	&& rm -fr viewvc-master "$VIEWVC_DOWNLOAD_FILE" \
	&& if [ -n "$DEL" ]; then echo "Delete temporary package(s) $DEL" && apk del $DEL; fi


COPY copy /

EXPOSE 80
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["viewvc"]
