#!/bin/bash
# NUMA 对比测试：CPU 亲和由容器 --cpuset-cpus 控制，容器内 mpirun 不绑核
set -e
source /opt/openfoam12/etc/bashrc
N=$1
MODE=${2:-none}   # none | node0(绑node0内存) | interleave(交错)
CASE=/tmp/case
rm -rf $CASE && mkdir -p $CASE && cd $CASE
cp -r $FOAM_TUTORIALS/incompressibleFluid/cavity/0 .
cp -r $FOAM_TUTORIALS/incompressibleFluid/cavity/constant .
cp -r $FOAM_TUTORIALS/incompressibleFluid/cavity/system .
sed -i 's/(20 20 1)/(160 160 24)/' system/blockMeshDict
sed -i 's/^endTime.*/endTime         0.05;/' system/controlDict
sed -i 's/^deltaT.*/deltaT          0.0005;/' system/controlDict
sed -i 's/^writeControl.*/writeControl    timeStep;/' system/controlDict
sed -i 's/^writeInterval.*/writeInterval   100000;/' system/controlDict
blockMesh > log.blockMesh 2>&1
cat > system/decomposeParDict <<DICT
FoamFile { version 2.0; format ascii; class dictionary; object decomposeParDict; }
numberOfSubdomains $N;
method scotch;
DICT
decomposePar -force > log.decompose 2>&1
case "$MODE" in
  node0)      PRE="numactl --membind=0" ;;
  interleave) PRE="numactl --interleave=all" ;;
  *)          PRE="" ;;
esac
START=$(date +%s.%N)
mpirun --allow-run-as-root -np $N --bind-to none $PRE foamRun -parallel > log.foamRun 2>&1
END=$(date +%s.%N)
WALL=$(echo "$END $START" | awk '{printf "%.2f", $1-$2}')
EXEC=$(grep "ExecutionTime" log.foamRun | tail -1 | awk '{print $3}')
echo "RESULT cores=$N numa=$MODE wall=${WALL}s exec=${EXEC}s steps=$(grep -c '^Time = ' log.foamRun) end=$(grep -c '^End' log.foamRun)"
