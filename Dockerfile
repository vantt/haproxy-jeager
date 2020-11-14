FROM ubuntu:bionic as builder
RUN apt update && apt install -y wget curl autoconf automake cmake build-essential git libev-dev libpthread-stubs0-dev pkg-config

WORKDIR /build

RUN cd /build \
&& wget https://github.com/opentracing/opentracing-cpp/archive/v1.6.0.tar.gz \
&& tar xf v1.6.0.tar.gz \
&& cd opentracing-cpp-1.6.0 \
&& mkdir build \
&& cd build \
&& cmake -DCMAKE_INSTALL_PREFIX=/opt .. \
&& make \
&& make install \
&& cd /build

RUN cd /build \
&& apt-get install -y libtool \
&& git clone https://github.com/haproxytech/opentracing-c-wrapper.git \
&& cd opentracing-c-wrapper \
&& ./scripts/bootstrap \
&& ./configure --prefix=/opt --with-opentracing=/opt \
&& make \
&& make install \
&& ./scripts/distclean \
&& ./scripts/bootstrap \
&& ./configure --prefix=/opt --with-opentracing=/opt \
&& make \
&& make install 

RUN apt-get install -y libevent-dev libev-dev zlib1g-dev \
&& cd /build \  
&& wget https://github.com/jaegertracing/jaeger-client-cpp/archive/v0.6.0.tar.gz \
&& tar xf v0.6.0.tar.gz \
&& cd jaeger-client-cpp-0.6.0 \
&& mkdir build \
&& cd build \
&& cmake -DCMAKE_INSTALL_PREFIX=/opt -DJAEGERTRACING_PLUGIN=ON -DHUNTER_CONFIGURATION_TYPES=Release -DHUNTER_BUILD_SHARED_LIBS=OFF .. \
&& make \
&& make install

RUN cd /build \
&& git clone https://github.com/haproxytech/spoa-opentracing \
&& cd spoa-opentracing \
&& ./scripts/bootstrap \
&& ./configure --with-opentracing=/opt \
&& make all 

RUN ls -l /build/opentracing-c-wrapper
RUN ls -l /build/opentracing-cpp-1.6.0
RUN ls -l /opt/lib /opt/bin

RUN mkdir /build/final \
&& cp /build/spoa-opentracing/src/spoa-opentracing /build/final \
&& cp /build/jaeger-client-cpp-0.6.0/build/libjaegertracing_plugin.so /build/final \
&& cp /build/jaeger-client-cpp-0.6.0/build/libjaegertracing_plugin.so /opt/lib

#ENTRYPOINT ./src/spoa-opentracing -r0 -u ${URL}

FROM haproxy:2.3
RUN apt-get update -y && apt-get install -y libev4 zlib1g
COPY --from=builder /build/final/* /usr/local/bin/
COPY --from=builder /opt/lib /opt/lib 

RUN ls -l /opt/lib /usr/local/bin/
