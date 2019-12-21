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

docker版本:  

```
docker version
Client:
 Version:           19.03.4-ce
 API version:       1.40
 Go version:        go1.13.1
 Git commit:        9013bf583a
 Built:             Sat Oct 19 04:40:07 2019
 OS/Arch:           linux/amd64
 Experimental:      false

Server:
 Engine:
  Version:          19.03.4-ce
  API version:      1.40 (minimum version 1.12)
  Go version:       go1.13.1
  Git commit:       9013bf583a
  Built:            Sat Oct 19 04:39:38 2019
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          v1.3.0.m
  GitCommit:        d50db0a42053864a270f648048f9a8b4f24eced3.m
 runc:
  Version:          1.0.0-rc9
  GitCommit:        d736ef14f0288d6993a1845745d6756cfc9ddd5a
 docker-init:
  Version:          0.18.0
  GitCommit:        fec3683

```



执行下列命令:

```
git clone https://github.com/ceph/ceph.git
cd ceph
git checkout v15.0.0
./make_dist.sh # 产生 ceph-15.0.0.tar.bz2

git clone https://github.com/satanson/ceph_docker.git
cd ceph_docker/ceph_docker_build
cp ceph-15.0.0.tar.bz2 ./
tar -jxf ceph-15.0.0.tar.bz2
docker build . # 最终输出image的id

docker tag ${image_id} ceph_build:v15.0.0
```

 

### 用容器编译ceph

加快ceph的编译的方法:

1. 关闭test生成
2. 使用系统已经安装好的boost库
3. 使用ccache和pip cache
4. 并行编译

```
# 把build_in_docker.sh, cmake_cmd.sh 拷贝到ceph源码根目录
cp ceph_docker/cmake_cmd.sh ceph
cp ceph_docker/build_in_docker.sh ceph
cd ceph
mkdir -p ../ccache
mkdir -p ../pip_cache
# out-of-tree build
bash ./cmake_cmd.sh
cd build
make -j24
```



### 启动ceph集群

1. 将ceph_ops.sh脚本第8行的srcDir修改为ceph源码的root路径

2. 创建需要挂载的data, logs, run目录

   ```
   cd ceph_docker
   mkdir -p data/ceph_{mon,osd,mgr,client,rgw,mds}{0..2}_{data,logs,run}
   ```

3. 使用ceph_do.sh脚本管理集群

   ```
   cd ceph_docker
   ./ceph_do.sh # 根据命令提示选择下面操作
   choose target:
   1) cluster
   2) service
   #? 1
   1) bootstrap_start
   2) restart
   3) bootstrap
   4) start
   5) stop
   #? 1
   exec: bootstrap_start_ceph_cluster
   Are your sure[yes/no]: yes
   
   ```

4. 使用本地ceph命令查看状态

   ```
   cd ceph_docker
   ./ceph -s
   ./ceph df
   ```

5. 登录ceph_client0中操作ceph

   ```
   cd ceph_docker
   ./ceph_do.sh 
   choose target:
   1) cluster
   2) service
   #? 2
   service: 
   1) ceph_mon
   2) ceph_osd
   3) ceph_mgr
   4) ceph_client
   5) ceph_rgw
   6) ceph_mds
   #? 4
   cmd: 
   1) start
   2) stop
   3) restart
   #? 1
   node: 
   1) ceph_client0
   2) ceph_client1
   3) ceph_client2
   #? 1
   exec: start_ceph_client ceph_client0
   Are your sure[yes/no]: yes
   ```

6. 登入任何一个ceph节点操作

   ```
   docker exec -it ceph_osd /bin/bash
   ```

### 创建块设备并且部署mysql, 使用go-ycsb压测mysql

```
# 安装mysql:8.0
docker pull mysql:8.0

# 创建rbd盘
cd ceph_docker
./attach_disk.sh rbd/volume0 mysql0_data

# 启动mysqld0, 按提示操作
./mysqld_do.sh

# 启动mysql0, 按提示操作
./mysqld_do.sh

# 等于mysql0后创建test数据库
create database test;

# 使用go-ycsb压测
go get -u github.com/pingcap/go-ycsb
# 修改go_ycsb.sh的环境变量goycsb_basedir, 使得go-ycsb位于${goycsb_basedir}/bin/go-yscb
./go_ycsb.sh
```



### 使用ceph fs文件系统

```
# 初始化ceph mds0
./ceph_do.sh 
choose target:
1) cluster
2) service
#? 2
service: 
1) ceph_mon
2) ceph_osd
3) ceph_mgr
4) ceph_client
5) ceph_rgw
6) ceph_mds
#? 6
cmd: 
1) bootstrap	    3) mkfs	       5) start		  7) stop	     9) restart	       11) login
2) bootstrap_all    4) mkfs_all	       6) start_all	  8) stop_all	    10) restart_all
#? 1
node: 
1) ceph_mds0
2) ceph_mds1
3) ceph_mds2
#? 1
exec: bootstrap_ceph_mds ceph_mds0
Are your sure[yes/no]: yes

# 启动ceph_mds0
./ceph_do.sh 
choose target:
1) cluster
2) service
#? 2
service: 
1) ceph_mon
2) ceph_osd
3) ceph_mgr
4) ceph_client
5) ceph_rgw
6) ceph_mds
#? 6
cmd: 
1) bootstrap	    3) mkfs	       5) start		  7) stop	     9) restart	       11) login
2) bootstrap_all    4) mkfs_all	       6) start_all	  8) stop_all	    10) restart_all
#? 5
node: 
1) ceph_mds0
2) ceph_mds1
3) ceph_mds2
#? 1
exec: start_ceph_mds ceph_mds0
Are your sure[yes/no]: yes

# 登入ceph_mds0
docker exec -it ceph_mds0 /bin/bash
scripts/init_cephfs.sh #setup
scripts/fini_cephfs.sh #teardown
```



### 对象存储

```
# 初始化所有ceph_rgw{0..2}
choose target:
1) cluster
2) service
#? 2
service: 
1) ceph_mon
2) ceph_osd
3) ceph_mgr
4) ceph_client
5) ceph_rgw
6) ceph_mds
#? 5
cmd: 
1) bootstrap	    3) mkfs	       5) start		  7) stop	     9) restart	       11) login
2) bootstrap_all    4) mkfs_all	       6) start_all	  8) stop_all	    10) restart_all
#? 2
exec: bootstrap_all_ceph_rgw
Are your sure[yes/no]: yes

# 启动ceph_rgw{0..2}
./ceph_do.sh 
choose target:
1) cluster
2) service
#? 2
service: 
1) ceph_mon
2) ceph_osd
3) ceph_mgr
4) ceph_client
5) ceph_rgw
6) ceph_mds
#? 5
cmd: 
1) bootstrap	    3) mkfs	       5) start		  7) stop	     9) restart	       11) login
2) bootstrap_all    4) mkfs_all	       6) start_all	  8) stop_all	    10) restart_all
#? 6
exec: start_all_ceph_rgw
Are your sure[yes/no]: yes

# 登入ceph_rgw0
docker exec -it ceph_rgw0 /bin/bash
scripts/add_rgw_user.sh bucket0 #创建桶bucket0，用户名为bucket0
scripts/rgw_put.sh bucket0 ceph_rgw0 scripts/functions.sh #put object操作
scripts/rgw_get.sh bucket0 ceph_rgw0 functions.sh #get object操作
scripts/rgw_info.sh bucket0 ceph_rgw0 functions.sh #info object操作
scripts/rgw_del.sh bucket0 ceph_rgw0 functions.sh #del object操作
```



### 调试ceph进程

以调试osd为例

```
# 以root用户登入ceph_osd0, 修改权限
docker exec -it -u root ceph_osd0 /bin/bash
echo 0 | tee /proc/sys/kernel/yama/ptrace_scope

# 登入ceph_osd0, 然后用gdb挂osd
ps -C ceph-osd -o pid,cmd # 获取ceph-osd的进程pid
gdb -q $(which ceph-osd) --pid=${pid} -ex "thread apply all bt" --batch-slient
```