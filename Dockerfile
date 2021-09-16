#
# This Dockerfile builds a recent curl with HTTP/2 client support, using
# a recent nghttp2 build.
#
# See the Makefile for how to tag it. If Docker and that image is found, the
# Go tests use this curl binary for integration tests.
#

FROM ubuntu:trusty

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y git-core build-essential wget

RUN apt-get install -y --no-install-recommends \
       autotools-dev libtool pkg-config zlib1g-dev \
       libcunit1-dev libssl-dev libxml2-dev libevent-dev \
       automake autoconf

# The list of packages nghttp2 recommends for h2load:
RUN apt-get install -y --no-install-recommends make binutils \
        autoconf automake autotools-dev \
        libtool pkg-config zlib1g-dev libcunit1-dev libssl-dev libxml2-dev \
        libev-dev libevent-dev libjansson-dev libjemalloc-dev \
        cython python3.4-dev python-setuptools

# Note: setting NGHTTP2_VER before the git clone, so an old git clone isn't cached:
ENV NGHTTP2_VER 895da9a
RUN cd /root && git clone https://github.com/tatsuhiro-t/nghttp2.git

WORKDIR /root/nghttp2
RUN git reset --hard $NGHTTP2_VER
RUN autoreconf -i
RUN automake
RUN autoconf
RUN ./configure
RUN make
RUN make install

WORKDIR /root
RUN wget http://curl.haxx.se/download/curl-7.45.0.tar.gz
RUN tar -zxvf curl-7.45.0.tar.gz
WORKDIR /root/curl-7.45.0
RUN ./configure --with-ssl --with-nghttp2=/usr/local
RUN make
RUN make install
RUN ldconfig

# Create a user and group used to launch processes
# The user ID 1000 is the default for the first "regular" user on Fedora/RHEL,
# so there is a high chance that this ID will be equal to the current user
# making it easier to use volumes (no permission issues)
RUN groupadd -r jboss -g 1000 && useradd -u 1000 -r -g jboss -m -d /opt/jboss -s /sbin/nologin -c "JBoss user" jboss && \
    chmod 755 /opt/jboss


WORKDIR /opt/jboss
    
EXPOSE 8080/tcp

COPY start.sh /start

RUN chmod a+rwx /start

USER jboss

CMD ["1d"]
ENTRYPOINT ["/start"]

#CMD ["-h"]
#ENTRYPOINT ["/usr/local/bin/curl"]

