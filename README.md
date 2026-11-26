# ARM64 科学计算软件栈（Sci-Compute Stack for ARM64）

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Platform](https://img.shields.io/badge/platform-aarch64%20%7C%20ARM64-blue)

> 17 个主流开源科学计算软件在 ARM64（aarch64）上的 **Docker 一键构建集**，
> 全部经过官方算例验证，专为国内网络环境优化（不依赖翻墙）。

验证环境：鲲鹏920（2路96核@2.6GHz）· Ubuntu 22.04 · Docker
同样适用于飞腾、Apple Silicon 等一切 aarch64 平台。

## 为什么需要这个仓库

在 ARM64 上装科学计算软件，每个软件都要踩一遍坑：
国内拉不到镜像、apt 源缺包、arm64 链接参数差异、子模块缺失、
架构特有的编译器行为差异……网上没有系统性的参考。

本仓库把 **17 个软件的全部踩坑经验固化成可一键复现的 Dockerfile**，
每个软件附验证算例，`docker build` 即可复现。

## 软件清单（全部验证通过）

| 领域 | 软件 | 版本 | 验证内容 |
|---|---|---|---|
| **CFD** | [OpenFOAM](openfoam/) | 12 | 6大物理领域 + 并行扩展 + NUMA 深度测试 |
| | [SU2](su2/) | v8.0.0 | NACA0012 Euler 50步 |
| | [Code_Saturne](saturne/) | 9.3 | study 管线验证 |
| | [FluidX3D](fluidx3d/) | latest | LBM benchmark（pocl CPU） |
| **气象** | [WRF](wrf/) | V4.8.1 | em_b_wave 案例完整跑通 → [踩坑全记录](docs/WRF.md) |
| **结构 FEM** | [CalculiX](calculix/) | 2.17 | 悬臂梁弯曲（误差 3.5%） |
| | [Elmer](elmer/) | 26.2 | Beam_3D_Cantilever PASSED |
| | [FEniCSx](fenicsx/) | 0.8.0 | Poisson（偏差 2.4%） |
| **电磁** | [openEMS](openems/) | 0.0.35 | 34GHz 偶极子 FDTD |
| | [MEEP](meep/) | 1.17.1 | 2D 介质腔 Ez 场 |
| | Elmer 电磁模块 | 26.2 | CoilSolver PASSED all 3 |
| **分子/量子** | [LAMMPS](lammps/) | 2022 | LJ 液体 NVE 能量守恒 |
| | [GROMACS](gromacs/) | 2021.4 | LJ 能量最小化 |
| | [Quantum ESPRESSO](qe/) | 6.7 | Si SCF -93.449 Ry |
| | [PySCF](pyscf/) | 2.3.0 | H2 RHF -1.116759 Eh |
| **多体动力学** | [MBDyn](mbdyn/) | 1.7.3 | 单摆 IVP |
| | [Project Chrono](chrono/) | latest | Euler 角 demo |
| **前后处理** | [Gmsh](gmsh/) | 4.8.4 | 带孔板 2D 网格 |
| | [ParaView](paraview/) | 5.10 | pvbatch 管线 |
| | [meshio](meshio/) | 5.3 | msh→vtk 转换 |

## 快速开始

```bash
# 例：构建 CalculiX
cd calculix
docker build -t calculix:2.17 .
docker run --rm -v $(pwd)/cases:/workspace calculix:2.17 ccx cantilever
```

每个软件目录含 `Dockerfile`（含国内源 + arm64 修复）和 `cases/`（验证算例）。

## 已知限制

| 软件 | 状态 | 原因 |
|---|---|---|
| Code_Aster | ⛔ 未完成 | 官网 tarball 需注册下载 |
| NGSolve | ⛔ 未完成 | PyPI 无 arm64 包，PPA 不可达 |
| MOOSE | ⛔ 未完成 | 需 libmesh/petsc 子模块源码编译（约2-3小时） |

## 性能参考（鲲鹏920 2路96核实测）

| 指标 | 数值 |
|---|---|
| 单核 DGEMM (FP64) | 10.1 GFLOPS |
| 全机 DGEMM 峰值 | 493.5 GFLOPS |
| OpenFOAM 61万网格 24核 | 41.5s（对比单核 357.6s） |

NUMA 结论：默认内核调度已做首次接触分配，显式 numactl 绑定
（单节点/交错）在 8核/24核 双重复验下均为**负优化**，不建议干预。

## 目录结构

```
├── openfoam/       # OpenFOAM 12 + 并行/NUMA 基准脚本
├── calculix/       # CalculiX + 悬臂梁案例
├── ...
├── wrf/            # WRF + 子模块链接修复
├── docs/WRF.md     # WRF 三重坑排查全记录（推荐阅读）
├── scripts/        # 通用辅助脚本
└── PLAN.md         # 完整测试档案（含每个软件的调试记录）
```

## 许可证

MIT
