FROM ubuntu-arm:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN sed -i 's|http://archive.ubuntu.com|http://mirrors.aliyun.com|g; s|http://security.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list 2>/dev/null || true
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake gfortran git libopenmpi-dev openmpi-bin \
    libblas-dev liblapack-dev libarpack2-dev libmumps-dev libscotch-dev \
    libhdf5-dev libnetcdf-dev libxml2-dev libncurses5-dev libx11-dev \
    libgl1-mesa-dev libglu1-mesa-dev libftgl-dev libqwt-qt5-dev \
    qtbase5-dev libqt5opengl5-dev && rm -rf /var/lib/apt/lists/*
COPY src /opt/elmer-src
WORKDIR /opt/elmer-src
RUN mkdir build && cd build && cmake -DCMAKE_INSTALL_PREFIX=/opt/elmer \
    -DWITH_MPI=ON -DWITH_OpenMP=ON -DWITH_Mumps=ON -DWITH_MeshGen=ON \
    -DWITH_ElmmerGui=OFF -DWITH_PYTHON=OFF .. > /tmp/cmake.log 2>&1 && \
    make -j$(nproc) > /tmp/make.log 2>&1 && make install > /tmp/install.log 2>&1
ENV PATH=/opt/elmer/bin:$PATH
ENV ELMER_HOME=/opt/elmer
WORKDIR /workspace
CMD ["ElmerSolver"]
