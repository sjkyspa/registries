FROM hub.deepi.cn/base
RUN apk --update add curl
# Java Version
ENV JAVA_VERSION_MAJOR 8
ENV JAVA_VERSION_MINOR 66
ENV JAVA_VERSION_BUILD 17
ENV JAVA_PACKAGE       jre
# Download and unarchive Java

RUN mkdir /opt && curl -jksSL -H "Cookie: oraclelicense=accept-securebackup-cookie"\
  http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz \
    | tar -xzf - -C /opt && \
    ln -s /opt/jre1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR} /opt/jdk && \
    rm -rf /opt/jdk/lib/plugin.jar \
           /opt/jdk/lib/ext/jfxrt.jar \
           /opt/jdk/bin/javaws \
           /opt/jdk/lib/javaws.jar \
           /opt/jdk/lib/desktop \
           /opt/jdk/plugin \
           /opt/jdk/man \
           /opt/jdk/lib/deploy* \
           /opt/jdk/lib/*javafx* \
           /opt/jdk/lib/*jfx* \
           /opt/jdk/lib/amd64/libdecora_sse.so \
           /opt/jdk/lib/amd64/libprism_*.so \
           /opt/jdk/lib/amd64/libfxplugins.so \
           /opt/jdk/lib/amd64/libglass.so \
           /opt/jdk/lib/amd64/libgstreamer-lite.so \
           /opt/jdk/lib/amd64/libjavafx*.so \
           /opt/jdk/lib/amd64/libjfx*.so

RUN apk add --update wget ca-certificates && \
    export ALPINE_GLIBC_BASE_URL="https://circle-artifacts.com/gh/andyshinn/alpine-pkg-glibc/6/artifacts/0/home/ubuntu/alpine-pkg-glibc/packages/x86_64" && \
    export ALPINE_GLIBC_PACKAGE="glibc-2.21-r2.apk" && \
    export ALPINE_GLIBC_BIN_PACKAGE="glibc-bin-2.21-r2.apk" && \
    wget "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE" "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_BIN_PACKAGE" && \
    apk add --allow-untrusted "$ALPINE_GLIBC_PACKAGE" "$ALPINE_GLIBC_BIN_PACKAGE" && \
    /usr/glibc/usr/bin/ldconfig "/lib" "/usr/glibc/usr/lib" && \
    echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf && \
    apk del wget ca-certificates && \
    rm "$ALPINE_GLIBC_PACKAGE" "$ALPINE_GLIBC_BIN_PACKAGE" /var/cache/apk/*

# Set environment
ENV JAVA_HOME /opt/jdk
ENV PATH ${PATH}:${JAVA_HOME}/bin
