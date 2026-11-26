FROM ubuntu-arm:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN sed -i 's|http://archive.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list 2>/dev/null || true
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential gfortran autoconf automake libtool libltdl-dev \
    libblas-dev liblapack-dev && rm -rf /var/lib/apt/lists/*
COPY mbdyn-1.7.3 /opt/mbdyn-src
WORKDIR /opt/mbdyn-src
RUN ./configure --prefix=/opt/mbdyn --with-mpi=no > /tmp/conf.log 2>&1; \
    make -j$(nproc) CXXFLAGS="-std=c++14 -O2" > /tmp/make.log 2>&1; echo "make rc=$?"; \
    make install CXXFLAGS="-std=c++14 -O2" > /tmp/inst.log 2>&1; echo "install rc=$?"
ENV PATH=/opt/mbdyn/bin:$PATH
WORKDIR /workspace
CMD ["mbdyn"]
