# WRF on ARM64 (aarch64) 构建与踩坑全记录

> 环境：鲲鹏920（TaiShan V110，2路96核@2.6GHz）· Ubuntu 22.04 · Docker
> WRF 版本：V4.8.1（GitHub wrf-model/WRF）
> 最终结果：em_b_wave 理想案例 `SUCCESS COMPLETE WRF`，输出 wrfout_d01 文件

WRF 是本次 ARM64 科学计算栈验证中**坑最多的一个软件**，前后共踩了三个独立的坑。
每个坑单独看都不难，但叠加在一起极难定位。本文完整记录排查过程，供同样在
ARM64 上构建 WRF 的同学参考。

---

## 坑 1：git 子模块缺失 → `Error 31: NoahMP submodule files not populating`

### 现象

```
Error Error Error NoahMP submodule files not populating WRF directories
make: *** [Makefile:111: wrf] Error 31
```

同时伴随大量：

```
Fatal Error: Cannot open module file 'bl_ysu.mod' for reading
Fatal Error: Cannot open module file 'bl_shinhong.mod' for reading
/bin/sh: 7: git: not found
```

### 根因

WRF V4.8+ 把 NoahMP、MYNN-EDMF、MYNN-SFC、TEMPO、MMM-physics 等物理方案
拆成了 git 子模块。`git clone --depth 1` **不会**拉取子模块；而 `./compile`
内部会检查这些文件是否存在，缺失时尝试用 `git submodule update` 补拉——
但编译容器里通常没有 git（或没有网络），于是被 `make -i` 忽略后继续编译，
最终在链接时因缺模块崩溃。

### 修复

在**宿主机**（有网络）拉取全部子模块：

```bash
git clone https://github.com/wrf-model/WRF.git
cd WRF
git submodule update --init --recursive
```

⚠️ 注意：`git clone --depth 1` 后子模块也是浅的，直接 `submodule update --init --recursive` 即可。

**Docker 构建时还有一个隐藏坑**：子模块目录本身是嵌套 git 仓库，
如果之前构建过一次（子模块还没拉），Docker 会缓存旧的 `COPY src` 层。
必须破坏缓存才能让新拉取的子模块进入镜像：

```dockerfile
# 简单粗暴：加一行注释破坏缓存
RUN echo "# rebuild $(date)" >> /dev/null
```

或构建时加 `--no-cache`。

### 子模块清单（WRF V4.8.1）

| 子模块 | 用途 |
|---|---|
| `phys/noahmp` | Noah-MP 陆面过程 |
| `phys/physics_mmm` | NCAR MMM 通用物理（bl_ysu/bl_shinhong/bl_gwdo 等） |
| `phys/MYNN-EDMF` | MYNN 边界层 |
| `phys/MYNN-SFC` | MYNN 表面层 |
| `phys/TEMPO` | TEMPO 微物理 |
| `phys/fire_behavior` | 火行为 |
| `phys/GFL` | GFL 方案 |
| `.ci/hpc-workflows` | CI 配置 |

另外 `phys/Makefile` 的 `submodules` 目标会做符号链接（如
`ln -sf MYNN-EDMF/module_bl_mynnedmf.F90 module_bl_mynnedmf.F`），
容器内无 git 时需手动补这些链接（见下方 Dockerfile 片段）。

---

## 坑 2：netcdf 链接缺 `-lnetcdff -lnetcdf` → undefined reference

### 现象

编译到链接 wrf.exe 时：

```
undefined reference to `nf_put_vara_int_'
undefined reference to `nf_strerror_'
undefined reference to `nf_get_vara_int_'
collect2: error: ld returned 1 exit status
make[1]: [Makefile:17: em_wrf] Error 1 (ignored)
```

且 `make -i` 模式下**不报最终失败**，显示 `build completed` 但
`main/*.exe` 根本不存在，`run/*.exe` 是断链符号链接。

### 根因

`./configure` 生成的 `configure.wrf` 中，`LIB_EXTERNAL` 只有：

```makefile
LIB_EXTERNAL = -L$(WRF_SRC_ROOT_DIR)/external/io_netcdf -lwrfio_nf -L/usr/lib
```

它假设 netcdf 的 Fortran/C 库都在 `-L/usr/lib` 下。但 Ubuntu 22.04
arm64 的库实际在 `/usr/lib/aarch64-linux-gnu/`，且 `-lnetcdff -lnetcdf`
根本没出现在链接行里。

### 修复

```bash
sed -i 's|external/io_netcdf -lwrfio_nf -L/usr/lib|external/io_netcdf -lwrfio_nf -L/usr/lib/aarch64-linux-gnu -lnetcdff -lnetcdf|' configure.wrf
```

⚠️ 顺序很重要：`-lnetcdff` 必须在 `-lnetcdf` **之前**（Fortran 接口依赖 C 接口）。

⚠️ 另一个隐蔽点：WRF 的 `Makefile` 用 `-i`（ignore-errors）模式，
链接失败也会显示 `build completed`。**必须检查 `main/*.exe` 是否真实存在**，
不能只看退出码。

### 环境变量

configure 需要 `NETCDF` 指向 netcdf 安装根目录：

```bash
export NETCDF=/usr        # Ubuntu 的 nc-config --prefix 就是 /usr
export NETCDF_classic=1
```

Dockerfile 里用 `ENV` 设置后，某些 shell 子进程可能丢失，建议在
`RUN` 内显式 `export`。

---

## 坑 3：段错误（Segmentation fault）→ `ulimit -s unlimited`

### 现象

编译全部成功，`ideal.exe` 正常运行并生成 `wrfinput_d01`，但
`wrf.exe` 启动即段错误（rc=139），无任何有效日志输出。

### 排查过程

- 换 `namelist.input.backwards` → 仍段错误（排除 namelist 格式问题）
- 降优化等级 `-Ofast` → `-O2` → 仍段错误（排除激进优化）
- 发现 **`ulimit -s unlimited` 后立刻正常运行**

### 根因

WRF 部分物理方案（尤其递归例程和大数组局部变量）需要远超默认
8MB 的栈空间。这是 WRF 的经典已知问题（官方 FAQ 有记录），x86 上
大家习惯性设置过所以少见，ARM64 新环境很容易漏掉。

### 修复

```bash
ulimit -s unlimited
```

建议写进镜像的 `/etc/profile` 或容器 entrypoint，避免每次手输。

---

## 最终可用的 Dockerfile

```dockerfile
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive NETCDF=/usr NETCDF_classic=1

RUN sed -i 's|http://archive.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list || true
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential gfortran gcc csh m4 perl git \
    libopenmpi-dev openmpi-bin \
    libnetcdf-dev netcdf-bin libnetcdff-dev libpng-dev && \
    rm -rf /var/lib/apt/lists/*

# ⚠️ 构建前必须在宿主机完成: git submodule update --init --recursive
COPY src /opt/wrf-src
WORKDIR /opt/wrf-src

# 手动补子模块符号链接（容器内无 git）
RUN cd phys && \
    ln -sf MYNN-EDMF/module_bl_mynnedmf.F90 module_bl_mynnedmf.F && \
    ln -sf MYNN-EDMF/WRF/module_bl_mynnedmf_common.F90 module_bl_mynnedmf_common.F && \
    ln -sf MYNN-EDMF/WRF/module_bl_mynnedmf_driver.F90 module_bl_mynnedmf_driver.F && \
    ln -sf ../phys/noahmp/parameters/NoahmpTable.TBL ../run/ || true

# 配置（选项 13 = Linux aarch64 GCC serial；并行选 15=dmpar）
RUN (echo 13; echo 0) | ./configure > /tmp/conf.log 2>&1

# 修复 arm64 netcdf 链接
RUN sed -i 's|external/io_netcdf -lwrfio_nf -L/usr/lib|external/io_netcdf -lwrfio_nf -L/usr/lib/aarch64-linux-gnu -lnetcdff -lnetcdf|' configure.wrf

# 编译（em_real = 真实大气；em_b_wave 等理想案例单独编译目标）
RUN ./compile em_real 2>&1 | tail -3

# ⚠️ 运行时必须: ulimit -s unlimited
```

## 验证

```bash
ulimit -s unlimited
cd test/em_b_wave
../main/ideal.exe && ls wrfinput_d01   # 初始场生成
../main/wrf.exe && grep "SUCCESS COMPLETE" rsl.error.0000
# → wrf: SUCCESS COMPLETE WRF
```

## 经验总结

| 坑 | 症状 | 一句话修复 |
|---|---|---|
| 子模块缺失 | Error 31 + git not found | 宿主机 `git submodule update --init --recursive` + 破坏 Docker 缓存 |
| netcdf 链接 | undefined nf_* 引用，但显示 build completed | sed 加 `-lnetcdff -lnetcdf -L/usr/lib/aarch64-linux-gnu` |
| 段错误 | ideal 正常但 wrf 秒崩无日志 | `ulimit -s unlimited` |

**通用教训**：WRF 的 Makefile 大量使用 `make -i` 忽略错误，
**退出码为 0 不代表编译成功**，必须验证 `main/*.exe` 的存在。
