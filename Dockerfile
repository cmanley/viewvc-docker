FROM alpine:3.8

LABEL Maintainer="Craig Manley https://github.com/cmanley" \
      Description="ViewVC 1.1.26-1 (CVS & SVN repository viewer) based on nginx and Alpine 3.8"

RUN apk update && apk --no-cache add \
	cvs \
	fcgiwrap \
	nginx \
	python3 \
	py-subversion \
	py3-chardet \
	py3-pygments \
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


### cvsgraph (optional) ###
ARG CVSGRAPH_VERSION=1.7.0
ARG CVSGRAPH_BASENAME=cvsgraph-$CVSGRAPH_VERSION
ARG CVSGRAPH_DOWNLOAD_FILE=$CVSGRAPH_BASENAME.tar.gz
ARG CVSGRAPH_DOWNLOAD_URL=http://www.akhphd.au.dk/~bertho/cvsgraph/release/$CVSGRAPH_DOWNLOAD_FILE
ARG CVSGRAPH_DOWNLOAD_SHA256=74438faaefd325c7a8ed289ea5d1657befe1d1859d55f8fbbcc7452f4efd435f
RUN printf "\n########## Building cvsgraph ##########\n" \
	&& cd /tmp \
	&& apk --no-cache add libgd \
	&& NEED='byacc flex gd-dev g++ make freetype-dev libjpeg-turbo-dev libpng-dev libwebp-dev wget' \
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
	&& wget -q "$CVSGRAPH_DOWNLOAD_URL" -O "$CVSGRAPH_DOWNLOAD_FILE" \
	&& sha256sum "$CVSGRAPH_DOWNLOAD_FILE" \
	&& echo "$CVSGRAPH_DOWNLOAD_SHA256  $CVSGRAPH_DOWNLOAD_FILE" | sha256sum -c - \
	&& tar -xf "$CVSGRAPH_DOWNLOAD_FILE" \
	&& rm -fr "$CVSGRAPH_DOWNLOAD_FILE" \
	&& cd "$CVSGRAPH_BASENAME" \
	&& ./configure --prefix=/usr sysconfdir=/etc/cvsgraph --disable-nls \
	&& make --quiet install \
	&& mkdir -p /etc/cvsgraph \
	&& cp cvsgraph.conf /etc/cvsgraph/ \
	&& cd - \
	&& rm -fr "$CVSGRAPH_BASENAME" \
	&& rm -fr /usr/share/man \
	&& if [ -n "$DEL" ]; then echo "Delete temporary package(s) $DEL" && apk del $DEL; fi


### viewvc from Debian ###
ARG VIEWVC_DOWNLOAD_FILE=viewvc_1.1.26-1_all.deb
ARG VIEWVC_DOWNLOAD_URL=http://ftp.debian.org/debian/pool/main/v/viewvc/$VIEWVC_DOWNLOAD_FILE
ARG VIEWVC_DOWNLOAD_SHA256=bbe0567fb65c4a1e8c480f5638b7df2758821ba1467f64c6862fc8fad5375ba0
RUN printf "\n########## Installing viewvc ##########\n" \
	&& NEED='binutils wget' \
	&& DEL='' \
	&& for x in $NEED; do \
		if [ $(apk list "$x" | grep -F [installed] | wc -l) -eq 0 ]; then \
			DEL="$DEL $x" \
			&& echo "Add temporary package $x" \
			&& apk --no-cache add $x; \
		fi; \
	done \
	&& cd /tmp \
	&& wget -q "$VIEWVC_DOWNLOAD_URL" -O "$VIEWVC_DOWNLOAD_FILE" \
	&& sha256sum "$VIEWVC_DOWNLOAD_FILE" \
	&& echo "$VIEWVC_DOWNLOAD_SHA256  $VIEWVC_DOWNLOAD_FILE" | sha256sum -c - \
	&& ar x "$VIEWVC_DOWNLOAD_FILE" data.tar.xz && rm "$VIEWVC_DOWNLOAD_FILE" \
	&& tar -xf data.tar.xz -C / ./usr ./etc && rm data.tar.xz \
	&& if [ -n "$DEL" ]; then echo "Delete temporary package(s) $DEL" && apk del $DEL; fi \
	&& mkdir -p /opt/cvs /opt/svn \
	&& chgrp www-data /opt/cvs /opt/svn \
	&& ln -s /usr/share/viewvc/docroot/images/favicon.ico /usr/share/viewvc/favicon.ico \
	&& mv /etc/viewvc/viewvc.conf /etc/viewvc/viewvc.conf.dist


COPY copy /


EXPOSE 80
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["viewvc:alpine"]
