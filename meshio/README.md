# meshio 5.3
随 paraview 镜像自带（python3-meshio 包），或独立安装：
docker run --rm -v $PWD:/w paraview:5.10 python3 -c "import meshio; m=meshio.read('/w/in.msh'); meshio.write('/w/out.vtk', m)"
