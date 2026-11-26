FROM ubuntu-arm:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN sed -i 's|http://archive.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list 2>/dev/null || true
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential python3-pip python3-numpy ninja-build && pip3 install meson==1.2.0 2>&1 | tail -1
COPY src /opt/su2-src
WORKDIR /opt/su2-src
RUN ./meson.py setup build -Denable-pywrapper=false --prefix=/opt/SU2 > /tmp/meson.log 2>&1 && \
    ninja -C build -j$(nproc) > /tmp/ninja.log 2>&1 && \
    ninja -C build install > /tmp/inst.log 2>&1
ENV PATH=/opt/SU2/bin:$PATH
ENV SU2_RUN=/opt/SU2/bin
WORKDIR /workspace
CMD ["SU2_CFD"]
