##About
- 更新日期:2015-8-30
- 简介:Create the VMs accroding to the settings
<<<<<<< .merge_file_jz0YPh
- 最新版本:2.1(beta)
- 作者:www.isjian.com

##ChangeLog
### Version 2.1(beta) ChangeLog
1. 允许添加另一块数据盘
2. 允许设置虚拟机主机名

=======
- 最新版本:2.0.3
- 作者:www.isjian.com

##ChangeLog
>>>>>>> .merge_file_tMkORh
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
1. 如果创建多个虚拟机,虚拟机将被命名方式为vmhost-1,vmhost-2,vmhost-n 形式
2. 默认创建qcow2格式的磁盘，并且需要从一个后端镜像克隆,在脚本中设置backing变量为后端镜像路径，请注意该后端镜像需要是一个可启动的虚拟机镜像，这样创建出来的虚拟机就会跟此镜像中的系统保持一致，即克隆
<<<<<<< .merge_file_jz0YPh
3. 创建kvm虚拟机需要使用libvirt，该脚本会检测libvirt服务是否正常运行
=======
3. 创建kvm虚拟机需要使用libvirt，改脚本会检测libvirt服务是否正常运行
>>>>>>> .merge_file_tMkORh
4. 虚拟机网络默认使用nat方式(即桥接virbr0网桥，该网桥在启动libvirt服务后会自动生成),如果需要修改为Linux Bridge(桥接)方式，请确保宿主机中有可用的网桥,然后设置interface变量为该网桥名称
