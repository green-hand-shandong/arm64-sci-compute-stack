"""openEMS 验证：半波偶极子（金属盒实现）FDTD 全流程"""
import numpy as np, os
from CSXCAD import ContinuousStructure
from openEMS import openEMS
from openEMS.physical_constants import *

unit = 1e-3
f0 = 34e9
lambda0 = C0/f0*1e3  # mm
half_wave = lambda0/2

CSX = ContinuousStructure()
grid = CSX.GetGrid()
grid.SetDeltaUnit(unit)
grid.AddLine('x', np.arange(-5, 5.01, 0.5))
grid.AddLine('y', np.arange(-5, 5.01, 0.5))
grid.AddLine('z', np.arange(-5, 5.01, 0.25))

metal = CSX.AddMetal('dipole')
metal.AddBox([0,0,-half_wave/2], [0.2,0.2,half_wave/2])  # 细长盒当导线

FDTD = openEMS(NrTS=300, EndCriteria=1e-4)
FDTD.SetGaussExcite(f0/2, f0/4)
FDTD.SetBoundaryCond(['MUR']*6)
exc = CSX.AddExcitation('excite', 1, [0,0,1])
exc.AddBox([0.2,0,-0.25],[0.4,0.2,0.25])
FDTD.SetCSX(CSX)
FDTD.AddLumpedPort(1, 1.0, [0,0,-half_wave/2], [0,0,half_wave/2], 'z', True)

workdir = '/workspace/out'
os.makedirs(workdir, exist_ok=True)
FDTD.Run(workdir, verbose=0)
print("FDTD 完成")
print(f"输出文件: {sorted(os.listdir(workdir))}")
print(f'物理检查: C0={C0}, lambda0={lambda0:.4f}mm half_wave={half_wave:.4f}mm')
ut = np.loadtxt(f'{workdir}/port_ut_1', comments='%')
print(f"端口电压: 采样数={len(ut)}, max={abs(ut[:,1]).max():.3e}, 末值={abs(ut[-1,1]):.3e}")
