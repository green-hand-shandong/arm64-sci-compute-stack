# WRF 验证案例：em_b_wave（理想重力波）

容器内运行：
```bash
docker run --rm -it wrf:final bash -c "
ulimit -s unlimited
cd /opt/wrf-src/test/em_b_wave
../../main/ideal.exe && ../../main/wrf.exe
grep 'SUCCESS COMPLETE' rsl.error.0000
"
```
预期输出：`wrf: SUCCESS COMPLETE WRF`
