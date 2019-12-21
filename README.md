# docker化ceph集群



docker化ceph集群, 方便实操演练调试ceph代码, 提高"改代码-编译-部署-重现"的周转率.

包括的内容有: 

### ceph编译和启动服务的镜像

- ceph\_docker\_build/Dockerfile: 创建docker_build镜像, 用于编译ceph和启动ceph集群.

### ceph集群的配置文件

- ceph\_conf: ceph集群配置文件.
- ceph_do.sh, ceph_ops.sh: 管理ceph集群的一键启动脚本.
- scripts: 管理mon, osd, mgr, radosgw, mds服务的脚本.
- data/ceph\_{mon,osd,mgr,rgw,mds}\_{0..2}\_{data,run,logs}: ceph服务的所需的各种的数据, 日志和domain socket存储所需的挂载路径.

### 块设备/文件系统/对象存储

- attach\_disk.sh, detach\_disk.sh: **rbd块设备挂载**
- scripts/init_fs.sh, scripts/fini_fs.sh: **ceph fs setup/teardown脚本**
- scripts/rgw\_{init,put,get,del,info}: **ceph 对象存储相关脚本**



## 使用方法

### 编译镜像

