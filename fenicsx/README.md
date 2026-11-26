# FEniCSx 0.8.0
官方镜像直接可用（ARM64 原生支持）：
docker pull hub.rat.dev/dolfinx/dolfinx:v0.8.0   # 国内中转
docker tag hub.rat.dev/dolfinx/dolfinx:v0.8.0 dolfinx:v0.8.0
验证: docker run --rm -v $PWD:/work dolfinx:v0.8.0 python3 /work/poisson.py
