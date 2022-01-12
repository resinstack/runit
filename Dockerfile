FROM alpine:latest as BUILD
WORKDIR /runit
COPY patches patches
RUN apk add --no-cache build-base wget upx && \
        wget http://smarden.org/runit/runit-2.1.2.tar.gz && \
        tar -xvzf runit*.tar.gz --strip-components 1 && \
        for p in patches/*.patch ; do patch -Np0 < $p ; done && \
        cd runit*/src && \
        sed -e 's,sbin/runit,usr/bin/runit,g' -i runit.h && \
        echo "gcc -O2 -static" >conf-cc && \
        echo "gcc -s -static" >conf-ld && \
        sed -i -e 's:short x\[4\];$:gid_t x[4];:' chkshsgr.c && \
        make && \
        mkdir -p /opt/runit && \
        for f in chpst runit runit-init runsv runsvchdir runsvdir sv svlogd utmpset; do cp $f /opt/runit/$f ; done && \
        upx /opt/runit/*

FROM scratch
LABEL org.opencontainers.image.source https://github.com/resinstack/runit
COPY --from=BUILD /opt/runit/* /usr/bin/
