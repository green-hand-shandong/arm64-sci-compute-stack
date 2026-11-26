FROM ubuntu-arm:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN sed -i 's|http://archive.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list 2>/dev/null || true
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential gfortran autoconf automake libtool python3 python3-dev \
    python3-setuptools libopenmpi-dev openmpi-bin libblas-dev liblapack-dev \
    libhdf5-dev libcgns-dev libmed-dev libxml2-dev zlib1g-dev libscotch-dev && rm -rf /var/lib/apt/lists/*
COPY src /opt/saturne-src
RUN cd /opt/saturne-src && ./sbin/bootstrap > /tmp/bootstrap.log 2>&1
RUN cd /opt/saturne-src && ./configure --prefix=/opt/saturne --disable-gui \
    --with-cgns=/usr --with-scotch=/usr > /tmp/conf.log 2>&1; echo "conf rc=$?"
RUN cd /opt/saturne-src && make -j$(nproc) > /tmp/make.log 2>&1; echo "make rc=$?"
RUN cd /opt/saturne-src && make install > /tmp/inst.log 2>&1; echo "inst rc=$?"
ENV PATH=/opt/saturne/bin:$PATH
WORKDIR /workspace
CMD ["code_saturne"]
