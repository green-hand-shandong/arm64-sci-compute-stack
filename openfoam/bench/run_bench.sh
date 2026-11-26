#!/bin/bash
# OpenFOAM 并行/NUMA 基准测试 v3：cavity 层流算例（稳定不发散）
# 加密网格 + 固定步长，跑 100 步计时
set -e
source /opt/openfoam12/etc/bashrc
N=$1
MODE=${2:-none}

CASE=/tmp/case
rm -rf $CASE && mkdir -p $CASE && cd $CASE
cp -r $FOAM_TUTORIALS/incompressibleFluid/cavity/0 .
cp -r $FOAM_TUTORIALS/incompressibleFluid/cavity/constant .
cp -r $FOAM_TUTORIALS/incompressibleFluid/cavity/system .

# 网格加密：20x20x1 → 160x160x24 ≈ 61.4 万单元
sed -i 's/(20 20 1)/(160 160 24)/' system/blockMeshDict

# 固定 100 步，不写盘
sed -i 's/^endTime.*/endTime         0.05;/' system/controlDict
sed -i 's/^deltaT.*/deltaT          0.0005;/' system/controlDict
sed -i 's/^writeControl.*/writeControl    timeStep;/' system/controlDict
sed -i 's/^writeInterval.*/writeInterval   100000;/' system/controlDict

blockMesh > log.blockMesh 2>&1

if [ $N -eq 1 ]; then
  case "$MODE" in
    interleave) EXE="numactl --interleave=all foamRun" ;;
    one-node)   EXE="numactl --cpunodebind=0 --membind=0 foamRun" ;;
    *)          EXE="foamRun" ;;
  esac
  START=$(date +%s.%N)
  $EXE > log.foamRun 2>&1
  END=$(date +%s.%N)
else
  cat > system/decomposeParDict <<DICT
FoamFile { version 2.0; format ascii; class dictionary; object decomposeParDict; }
numberOfSubdomains $N;
method scotch;
DICT
  decomposePar -force > log.decompose 2>&1
  START=$(date +%s.%N)
  case "$MODE" in
    interleave) mpirun --allow-run-as-root -np $N --bind-to none numactl --interleave=all foamRun -parallel > log.foamRun 2>&1 ;;
    one-node)   mpirun --allow-run-as-root -np $N --bind-to core --map-by slot numactl --interleave=all --cpunodebind=0 --membind=0 foamRun -parallel > log.foamRun 2>&1 ;;
    *)          mpirun --allow-run-as-root -np $N --bind-to none foamRun -parallel > log.foamRun 2>&1 ;;
  esac
  END=$(date +%s.%N)
fi

WALL=$(echo "$END $START" | awk '{printf "%.2f", $1-$2}')
EXEC=$(grep "ExecutionTime" log.foamRun | tail -1 | awk '{print $3}')
STEPS=$(grep -c '^Time = ' log.foamRun)
OK=$(grep -c '^End' log.foamRun)
CELLS=$(grep "nCells" log.blockMesh | head -1 | awk '{print $2}')
echo "RESULT cores=$N numa=$MODE cells=$CELLS wall=${WALL}s exec=${EXEC}s steps=$STEPS end=$OK"
