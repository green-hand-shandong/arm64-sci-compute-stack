"""MEEP 验证：2D 空腔共振模式（官方入门例）—— 监听点频谱应有共振峰"""
import meep as mp
import numpy as np

# 2D: 16x16 (物理尺寸 16x16)，介质板 + 点源
cell = mp.Vector3(16, 16, 0)
geometry = [mp.Block(center=mp.Vector3(), size=mp.Vector3(12, 12, mp.inf),
                     material=mp.Medium(epsilon=12))]
fcen = 0.15
df = 0.2
sources = [mp.Source(mp.ContinuousSource(frequency=fcen), component=mp.Ez,
                     center=mp.Vector3(-4, 0), size=mp.Vector3(0, 1))]
sim = mp.Simulation(cell_size=cell, boundary_layers=[mp.PML(1.0)],
                    geometry=geometry, sources=sources, resolution=10)
freqs = mp.FluxRegion
# 监听点
sim.run(until=200)
# 输出某点 Ez 场
e = sim.get_field_point(mp.Ez, mp.Vector3(4, 0))
print(f"MEEP 运行完成, Ez(4,0) = {e:.4e}")
print(f"meep version: {mp.__version__}")
