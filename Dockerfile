FROM alpine:3.6

ARG SIAB_VERSION=2.20
ARG SIAB_DOWNLOAD_URL=https://github.com/shellinabox/shellinabox/archive/v2.20.tar.gz
# unstable version has no stable SHA256 ID
ARG SIAB_DOWNLOAD_SHA=27a5ec6c3439f87aee238c47cc56e7357a6249e5ca9ed0f044f0057ef389d81e

# Build shellinabox
RUN set -ex; \
	\
	apk add --no-cache --virtual .build-deps \
                autoconf automake m4 libtool libressl-dev zlib-dev \
		coreutils \
		gcc \
		make \
		musl-dev \
                openssl \
	; \
	\
	wget -O shellinabox.tar.gz "$SIAB_DOWNLOAD_URL"; \
	if [ -n "$SIAB_DOWNLOAD_SHA" ]; then echo "$SIAB_DOWNLOAD_SHA *shellinabox.tar.gz" | sha256sum -c -; fi; \
	mkdir -p /usr/src/shellinabox; \
	tar -xzf shellinabox.tar.gz -C /usr/src/shellinabox --strip-components=1; \
	rm shellinabox.tar.gz; \
        \
        cd /usr/src/shellinabox; \
        autoreconf -i; \
        export CPPFLAGS="${CPPFLAGS/-D_FORTIFY_SOURCE=2/}"; \
        ./configure \
		--prefix=/usr \
		--disable-static \
		--disable-utmp; \
        make; \
        make install; \
	\
	rm -r /usr/src/shellinabox; \
	\
	apk del .build-deps

ENV SIAB_USERCSS="Normal:+/etc/shellinabox/options-enabled/00+Black-on-White.css,Reverse:-/etc/shellinabox/options-enabled/00_White-On-Black.css;Colors:+/etc/shellinabox/options-enabled/01+Color-Terminal.css,Monochrome:-/etc/shellinabox/options-enabled/01_Monochrome.css" \
  SIAB_PORT=4200 \
  SIAB_ADDUSER=true \
  SIAB_DEBUG=false \
  SIAB_USER=siab \
  SIAB_USERID=1001 \
  SIAB_GROUP=siab \
  SIAB_GROUPID=1001 \
  SIAB_PASSWORD=putsafepasswordhere \
  SIAB_SHELL=/bin/bash \
  SIAB_HOME=/home/siab \
  SIAB_SUDO=false \
  SIAB_SSL=true \
  SIAB_SERVICE=/:LOGIN \
  SIAB_PKGS=none \
  SIAB_SCRIPT="" \
  SIAB_RUN=""

ADD user-css.tar.gz /

RUN apk add --no-cache bash openssl curl openssh-client sudo su-exec python && \
    rm -rf /var/cache/apk/* && \
    adduser -D -H -h /home/shellinabox shellinabox && \
    mkdir /var/lib/shellinabox

EXPOSE 4200

VOLUME /etc/shellinabox /home

COPY entrypoint.sh /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["shellinabox"]
