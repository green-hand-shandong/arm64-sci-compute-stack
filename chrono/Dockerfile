FROM ubuntu-arm:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN sed -i 's|http://archive.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list 2>/dev/null || true
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake libeigen3-dev libyaml-cpp0.8 && rm -rf /var/lib/apt/lists/*
COPY src /opt/chrono-src
WORKDIR /opt/chrono-src
RUN cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/chrono \
    -DBUILD_TESTING=OFF -DENABLE_MODULE_IRRLICHT=OFF > /tmp/cmake.log 2>&1 && \
    cmake --build build -j$(nproc) > /tmp/make.log 2>&1 && \
    cmake --install build > /tmp/inst.log 2>&1
ENV LD_LIBRARY_PATH=/opt/chrono/lib
WORKDIR /workspace
CMD ["/bin/bash"]
