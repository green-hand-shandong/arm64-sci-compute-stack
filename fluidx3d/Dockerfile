FROM ubuntu-arm:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN sed -i 's|http://archive.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list 2>/dev/null || true
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential ocl-icd-opencl-dev pocl-opencl-icd clinfo make && rm -rf /var/lib/apt/lists/*
COPY src /opt/fluidx3d
WORKDIR /opt/fluidx3d
RUN make Linux -j$(nproc) > /tmp/make.log 2>&1; echo "make rc=$?"
WORKDIR /workspace
CMD ["/opt/fluidx3d/bin/FluidX3D"]
