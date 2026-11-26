FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive NETCDF=/usr NETCDF_classic=1
RUN sed -i 's|http://archive.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list || true
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential gfortran gcc csh m4 perl git \
    libopenmpi-dev openmpi-bin \
    libnetcdf-dev netcdf-bin libnetcdff-dev libpng-dev && \
    rm -rf /var/lib/apt/lists/*

# 拉取 WRF 源码 + 全部子模块（必须在有网络的环境构建）
RUN git clone https://github.com/wrf-model/WRF.git /opt/wrf-src && \
    cd /opt/wrf-src && git submodule update --init --recursive
WORKDIR /opt/wrf-src

# 补子模块符号链接（容器内 git 已可用，此处兜底）
RUN cd phys && \
    ln -sf MYNN-EDMF/module_bl_mynnedmf.F90 module_bl_mynnedmf.F || true && \
    ln -sf MYNN-EDMF/WRF/module_bl_mynnedmf_common.F90 module_bl_mynnedmf_common.F || true && \
    ln -sf MYNN-EDMF/WRF/module_bl_mynnedmf_driver.F90 module_bl_mynnedmf_driver.F || true

# 配置（13 = aarch64 GCC serial；MPI 并行改 15）
RUN (echo 13; echo 0) | ./configure > /tmp/conf.log 2>&1

# 修复 arm64 netcdf 链接（关键！）
RUN sed -i 's|external/io_netcdf -lwrfio_nf -L/usr/lib|external/io_netcdf -lwrfio_nf -L/usr/lib/aarch64-linux-gnu -lnetcdff -lnetcdf|' configure.wrf

# 编译（约 1 小时）
RUN ./compile em_real 2>&1 | tail -3

# 运行时必须 unlimited 栈
RUN echo "ulimit -s unlimited" >> /etc/profile

WORKDIR /workspace
CMD ["/bin/bash", "-c", "ulimit -s unlimited && exec bash"]
