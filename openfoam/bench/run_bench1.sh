#!/bin/bash
set -e
source /opt/openfoam12/etc/bashrc
MODE=${1:-none}
CASE=/tmp/case
rm -rf $CASE && mkdir -p $CASE && cd $CASE
cp -r $FOAM_TUTORIALS/incompressibleFluid/cavity/0 .
cp -r $FOAM_TUTORIALS/incompressibleFluid/cavity/constant .
cp -r $FOAM_TUTORIALS/incompressibleFluid/cavity/system .
sed -i 's/(20 20 1)/(160 160 24)/' system/blockMeshDict
sed -i 's/^endTime.*/endTime         0.03;/' system/controlDict
sed -i 's/^deltaT.*/deltaT          0.0005;/' system/controlDict
sed -i 's/^writeControl.*/writeControl    timeStep;/' system/controlDict
sed -i 's/^writeInterval.*/writeInterval   100000;/' system/controlDict
blockMesh > log.blockMesh 2>&1
case "$MODE" in
  interleave) EXE="numactl --interleave=all foamRun" ;;
  one-node)   EXE="numactl --cpunodebind=0 --membind=0 foamRun" ;;
  *)          EXE="foamRun" ;;
esac
START=$(date +%s.%N)
$EXE > log.foamRun 2>&1
END=$(date +%s.%N)
WALL=$(echo "$END $START" | awk '{printf "%.2f", $1-$2}')
EXEC=$(grep "ExecutionTime" log.foamRun | tail -1 | awk '{print $3}')
echo "RESULT cores=1 numa=$MODE wall=${WALL}s exec=${EXEC}s steps=$(grep -c '^Time = ' log.foamRun) end=$(grep -c '^End' log.foamRun)"
