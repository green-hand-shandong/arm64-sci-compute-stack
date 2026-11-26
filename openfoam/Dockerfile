FROM ubuntu-arm:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN sed -i 's|http://archive.ubuntu.com|http://mirrors.aliyun.com|g; s|http://security.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list 2>/dev/null || true

# OpenFOAM 官方 apt 源（arm64 支持）：直接写源文件，不依赖 add-apt-repository
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl ca-certificates gnupg software-properties-common \
 && curl -s https://dl.openfoam.org/gpg.key | apt-key add - \
 && echo "deb http://dl.openfoam.org/ubuntu jammy main" > /etc/apt/sources.list.d/openfoam.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends openfoam12 \
 && rm -rf /var/lib/apt/lists/*

RUN echo 'source /opt/openfoam12/etc/bashrc' >> /root/.bashrc
ENV BASH_ENV=/opt/openfoam12/etc/bashrc

WORKDIR /root
CMD ["/bin/bash"]

# 追加层：NUMA 工具 + 并行运行辅助
FROM openfoam12:arm64
RUN apt-get update && apt-get install -y --no-install-recommends numactl && rm -rf /var/lib/apt/lists/*
RUN echo 'source /opt/openfoam12/etc/bashrc' >> /root/.bashrc
ENV BASH_ENV=/opt/openfoam12/etc/bashrc
