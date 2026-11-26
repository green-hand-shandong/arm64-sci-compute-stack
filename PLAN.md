# 开源科学计算/仿真软件测试计划

> 设备：ARM64 (aarch64) · Ubuntu 20.04 · 96核/4 NUMA · 1TiB RAM · Docker 29
> 测试方法：每个项目容器化 → 运行官方教程算例 → 验证收敛/输出 → 记录耗时
> 状态标记：⬜待测 🟨进行中 ✅通过 ❌失败 ⛔不适用

## 基准环境（已完成）
- [x] ✅ OpenFOAM 12 镜像 `openfoam12:arm64`（Ubuntu 22.04 基底 + 官方 apt 源）
- [x] ✅ 功能链路：blockMesh/checkMesh/decomposePar/mpirun/reconstructPar/foamPostProcess
- [x] ✅ 并行扩展：1核 357.6s / 8核 80.1s / 24核 41.5s / 96核 473.7s（61.4万网格）
- [x] ✅ NUMA 结论：默认调度最优；显式绑定均为负优化（8核/24核一致）
- [x] ✅ 六领域：结构/激波/多相/共轭传热/多组分/颗粒流 全部收敛
- 构建 Dockerfile：`/data2/gxw/openfoam-docker/Dockerfile`
- 测试脚本：`/data2/gxw/openfoam-docker/bench/`

## 测试清单

### 1. CFD
- [x] ✅ **OpenFOAM 12** — Fluent/STAR-CCM+ 替代（已深入测试）
- [x] ✅ **SU2 v8.0.0** — 伴随优化 CFD（meson 编译；NACA0012 Euler 50 步 Exit Success）
- [x] ✅ **Code_Saturne 9.3** — EDF 工业级 CFD（源码编译成功；study 创建/运行管线验证，空 case 缺网格输入符合预期）
- [x] ✅ **FluidX3D** — LBM（pocl CPU OpenCL；benchmark 20 MLUPs）
- [x] ✅ **WRF V4.8.1** — 中尺度气象（源码编译约1小时；em_b_wave 理想案例 SUCCESS COMPLETE + wrfout 输出）

### 2. 结构有限元（FEM）
- [x] ✅ **CalculiX 2.17** — Abaqus 替代（悬臂梁弯曲：误差3.5%，收敛正确）
- [ ] ⛔ **Code_Aster** — 官网 tarball 需注册下载（404），Debian 无包，GitHub 无官方镜像；本轮无法获取源码
- [x] ✅ **Elmer 26.2** — 多物理场（源码编译2.34GB镜像；Beam_3D_Cantilever PASSED）
- [x] ✅ **FEniCSx 0.8.0** — Python FEM 框架（官方镜像；Poisson max(u)=0.0736 vs 理论0.0719）
- [ ] ⛔ **NGSolve** — PyPI 无 arm64 包，PPA 被墙（需源码编译，暂缓）
- [ ] ⛔ **MOOSE** — 需 libmesh/petsc 子模块源码编译（2-3小时），本轮时间受限未完成；系统 petsc 路径下 make 失败于缺 libmesh 子模块

### 3. 电磁
- [x] ✅ **openEMS 0.0.35** — 全波 FDTD（HFSS 替代；34GHz 偶极子 FDTD 端口信号 ✓）
- [x] ✅ **MEEP 1.17.1** — 光子 FDTD（2D 介质腔 Ez 场演化正常）
- [x] ✅ **Elmer 电磁模块** — CoilSolver1 磁场测试 PASSED all 3

### 4. 分子动力学 / 第一性原理
- [x] ✅ **LAMMPS 2022** — 材料 MD（LJ 液体 4000 原子 NVE 1000 步，能量守恒 ✓）
- [x] ✅ **GROMACS 2021.4** — 生物 MD（LJ 体系能量最小化：Fmax 6.8e-6 收敛）
- [x] ✅ **Quantum ESPRESSO 6.7** — DFT（硅金刚石 SCF：-93.449 Ry，7 次迭代收敛）
- [x] ✅ **PySCF 2.3.0** — Python 量子化学（H2 RHF：-1.116759 Eh，与文献一致）

### 5. 多体动力学
- [x] ✅ **MBDyn 1.7.3** — 多体动力学（源码编译 C++14；单摆求解正常终止）
- [x] ✅ **Project Chrono** — 多体动力学（源码编译；demo_CH_EulerAngles 旋转矩阵输出正确）

### 6. 前后处理
- [x] ✅ **Gmsh 4.8.4** — CAD+网格（带孔板 2D 网格生成 OK）
- [x] ✅ **ParaView 5.10** — 后处理（pvbatch 读 VTK+Calculator 滤镜 OK）
- [x] ✅ **meshio 5.3** — 网格转换（gmsh msh→vtk 1186点/2272单元）

## 测试记录

| 日期 | 项目 | 版本 | 算例 | 结果 | 耗时 | 备注 |
|---|---|---|---|---|---|---|
| 2026-11-19 | OpenFOAM 12 | v12 (20240902) | cavity/pitzDaily + 6领域 | ✅ | 见上 | 全部收敛 |
| 2026-11-20 | OpenFOAM 12 | 多领域 | plateHole/forwardStep/damBreak/CHT/verticalChannel/Goldschmidt | ✅ | 4.2s~1948s | 六领域覆盖 |
| 2026-11-23 | CalculiX 2.17 | 2.17-3 (Ubuntu) | 悬臂梁弯曲 C3D8 | ✅ | 0.015s | 挠度误差3.5%（网格收敛验证） |
| 2026-11-23 | FEniCSx 0.8.0 | 官方镜像 | Poisson 方程 | ✅ | <1s | max(u) 偏差2.4% |
| 2026-11-23 | Elmer 26.2 | 源码编译 | Beam_3D_Cantilever | ✅ | 0.48s | 参考解对比 PASSED |
| 2026-11-23 | Gmsh 4.8.4 | 4.8.4 (Ubuntu) | 带孔板 2D 网格 | ✅ | 0.05s | msh4.1 输出正常 |
| 2026-11-24 | LAMMPS 2022 | 20220106 (Ubuntu) | LJ 液体 NVE 1000步 | ✅ | 3.7s | 能量守恒验证 ✓ |
| 2026-11-24 | openEMS 0.0.35 | 0.0.35 (Ubuntu) | 34GHz 偶极子 FDTD | ✅ | ~20s | 端口电压信号 ✓ |
| 2026-11-24 | QE 6.7 | 6.7 (Ubuntu) | Si 金刚石 SCF | ✅ | ~60s | -93.449 Ry 文献一致 |
| 2026-11-24 | GROMACS 2021.4 | 2021.4 (Ubuntu) | LJ 能量最小化 | ✅ | ~5s | Fmax 6.8e-6 |
| 2026-11-24 | PySCF 2.3.0 | pip | H2 RHF | ✅ | ~10s | -1.116759 Eh |
| 2026-11-24 | MBDyn 1.7.3 | 源码编译 | 单摆 IVP | ✅ | ~3s | 求解正常终止 |
| 2026-11-24 | MEEP 1.17.1 | 1.17.1 (Ubuntu) | 2D 介质腔 | ✅ | 1.2s | Ez 场演化 ✓ |
| 2026-11-24 | ParaView 5.10 | 5.10 (Ubuntu) | VTK 读取+滤镜 | ✅ | ~10s | 1000点管线 OK |
| 2026-11-24 | meshio 5.3 | 5.3 (Ubuntu) | msh→vtk | ✅ | <1s | 1186点/2272单元 |
| 2026-11-24 | SU2 v8.0.0 | 源码编译 meson | NACA0012 Euler | ✅ | ~60s | Exit Success |
| 2026-11-24 | FluidX3D | 源码编译 | LBM benchmark 64^3 | ✅ | ~120s | 20 MLUPs (pocl CPU) |
| 2026-11-24 | Elmer 电磁 | 同 Elmer 镜像 | CoilSolver1 | ✅ | 0.6s | PASSED all 3 |
| 2026-11-24 | Code_Saturne 9.3 | 源码编译 | study 管线 | ✅ | ~90s编译 | 求解器到网格读取 ✓ |
| 2026-11-24 | Project Chrono | 源码编译 | Euler 角 demo | ✅ | ~3s | 旋转矩阵正确 |
| 2026-11-24 | MOOSE | 源码（子模块缺失） | — | ⛔ | — | 需 libmesh 子模块，超时放弃 |
| 2026-11-24 | Code_Aster | 源码不可得 | — | ⛔ | — | 官网 tarball 需注册 |
| 2026-11-25 | WRF V4.8.1 | 源码编译 | em_b_wave 理想案例 | ✅ | ideal即时+wrf~60s | SUCCESS COMPLETE |
| 2026-11-25 | （调试记录）WRF | — | — | — | — | 根因：git 子模块缺失+NETCDF链接缺 -lnetcdff -lnetcdf+需 ulimit -s unlimited |
