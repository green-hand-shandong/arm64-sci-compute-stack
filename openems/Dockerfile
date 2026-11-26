FROM ubuntu-arm:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN sed -i 's|http://archive.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list 2>/dev/null || true
RUN apt-get update && apt-get install -y --no-install-recommends \
    openems python3-openems python3-numpy python3-h5py libnf2ff0 h5utils && rm -rf /var/lib/apt/lists/*
WORKDIR /workspace
CMD ["openEMS"]
