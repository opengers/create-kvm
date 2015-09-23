##About
- 更新日期:2015-9-22
- 简介:Create the VMs accroding to the settings
- 最新版本:2.5.1
- 作者:www.isjian.com

##ChangeLog
### Version 2.5.1 ChangeLog
1. 可以自定义每个虚拟机的详细配置(名字，cpu，内存，hostname，磁盘大小,网卡数,ip地址)

### Version 2.1 ChangeLog
1. 允许添加另一块数据盘
2. 允许设置虚拟机主机名

### Version 2.0.3 ChangeLog
1. 自定义虚拟机名称编号，vmhost-n,vmhost-{n+1},...

### Version 2.0.2 ChangeLog
1. 添加身份检查，只允许root身份执行

### Version 2.0.1 ChangeLog
1. vmname 变量只能为字母数字，下划线
2. virsh 命令存在检查
3. 创建前检查虚拟磁盘是否存在

### Version 2.0 ChangeLog
1. Fix some bugs
2. Add the variables check before create the vms
3. Set the vms ip before create the vms

##注意:
1. 宿主机(hosts)指运行虚拟机的物理机，虚机(guest)指所创建的kvm虚拟机
2. 在脚本中的变量命名是有规律的，像"V_name"，"V_cpu"，这种"V_xxx"形式变量表示此变量是与虚机相关,"H_bridge","H_vmdir"这种"H_xxx"形式表示此变量是与宿主机相关
3. 脚本会检查当前系统环境是否符合要求，请根据报错信息定位错误原因
4. 此脚本所创建的虚机是根据母镜像创建的,创建的每个虚机都是母镜像的一份克隆(链接克隆，并不是完整的拷贝,要了解更多信息，请搜索qcow2格式特性),因此创建的多个虚机系统将会与母镜像系统保持一致
5. 一旦创建了虚机，此母镜便被设为只读模式，虚机在有需要时会读母镜像，任何对母镜像的修改或路径变更将导致虚机启动异常，关于更多信息，请参考:http://www.isjian.com/2015/07/kvm-libvirt-qemu-3/
6. 要获得centos6母镜像，请访问http://cloud.centos.org/centos/6/images/,其它Linux发行版镜像，请参考:http://docs.openstack.org/image-guide/content/ch_obtaining_images.html
7. 脚本创建的虚机磁盘格式都为qcow2,在脚本中设置H_backimage变量为母镜像路径，请注意该母镜像需要是一个可正常启动的母镜像
8. 创建kvm虚拟机需要使用libvirt，设置虚机ip，hostname需要使用libguestfish工具
9. 虚机网络默认使用nat方式(即虚机网卡桥接virbr0网桥，该网桥在启动libvirtd服务后会自动生成),如果需要修改为Linux Bridge(与宿主机同一个网段)方式，请确保宿主机中有可用的网桥,然后设置H_bridge变量为该网桥名称
