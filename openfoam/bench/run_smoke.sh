#!/bin/bash
set -e
source /opt/openfoam12/etc/bashrc
CASE=/tmp/smoke
rm -rf $CASE && mkdir -p $CASE && cd $CASE
cp -r $FOAM_TUTORIALS/incompressibleFluid/cavity/0 .
cp -r $FOAM_TUTORIALS/incompressibleFluid/cavity/constant .
cp -r $FOAM_TUTORIALS/incompressibleFluid/cavity/system .
sed -i 's/^endTime.*/endTime         0.05;/' system/controlDict
sed -i 's/^writeControl.*/writeControl    timeStep;/' system/controlDict
sed -i 's/^writeInterval.*/writeInterval   100000;/' system/controlDict
blockMesh > log.blockMesh 2>&1
cat > system/decomposeParDict <<DICT
FoamFile { version 2.0; format ascii; class dictionary; object decomposeParDict; }
numberOfSubdomains 8;
method scotch;
DICT
decomposePar -force > log.decompose 2>&1
mpirun --allow-run-as-root -np 8 --bind-to none foamRun -parallel > log.foamRun 2>&1
echo "steps=$(grep -c '^Time = ' log.foamRun) end=$(grep -c '^End' log.foamRun)"
grep ExecutionTime log.foamRun | tail -1
grep "Courant" log.foamRun | tail -1
