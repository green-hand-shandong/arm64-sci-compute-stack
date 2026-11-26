FROM ubuntu-arm:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN sed -i 's|http://archive.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list 2>/dev/null || true
RUN apt-get update && apt-get install -y --no-install-recommends python3-pip python3-numpy python3-scipy && rm -rf /var/lib/apt/lists/*
RUN pip3 install pyscf==2.3.0 2>&1 | tail -1
WORKDIR /workspace
CMD ["python3"]
