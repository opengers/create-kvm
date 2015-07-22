#centos6.x下批量创建KVM虚拟机脚本
##说明
- 更新日期:2015-7-22.
- 版本:2.0.1
- 作者:www.isjian.com
- Version 2.0.1 ChangeLog:
- --vmname 变量只能为字母数字，下划线
- --virsh 命令存在检查

- Version 2.0 ChangeLog:
- --修复一些bugs
- --创建虚拟机之前，增加变量检查
- --支持设置虚拟机IP地址

##注意:
- 如果创建多个虚拟机,虚拟机将被命名方式为vmhost-1,vmhost-2,vmhost-n 形式
- 默认创建qcow2格式的磁盘，并且需要从一个后端镜像克隆,在脚本中设置backing变量为后端镜像路径，请注意该后端镜像需要是一个可启动的虚拟机镜像，这样创建出来的虚拟机就会跟此镜像中的系统保持一致，即克隆
- 创建kvm虚拟机需要使用libvirt，改脚本会检测libvirt服务是否正常运行
- 虚拟机网络默认使用nat方式(即桥接virbr0网桥，该网桥在启动libvirt服务后会自动生成),如果需要修改为Linux Bridge(桥接)方式，请确保宿主机中有可用的网桥,然后设置interface变量为该网桥名称
