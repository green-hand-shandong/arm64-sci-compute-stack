from paraview.simple import *
# 读 VTK + 显示管线信息
r = OpenDataFile("/workspace/grid.vtk")
print("源对象:", r)
UpdatePipeline()
info = r.GetDataInformation()
print("点数:", info.GetNumberOfPoints())
print("单元数:", info.GetNumberOfCells())
# 应用 Calculator 滤镜处理密度
calc = Calculator(Input=r)
calc.Function = "density * 2"
calc.UpdatePipeline()
print("Calculator 滤镜运行 OK")
