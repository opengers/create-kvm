#!/bin/bash
#Time:2015-7-2
#Note:create the VMs accroding to the settings
#Version:1.5
#Author:plcloud.lijian

#----------------------- argvs ----------------------

#虚拟机个数
nums=3
#如果创建多个虚拟机,虚拟机将被命名方式为vmhost-1,vmhost-2,vmhost-n 形式
vmname="x3"
#虚拟机磁盘大小(单位为G),默认为20G
vdisksize=20
#虚拟磁盘存放目录
vdiskdir=/data/vhosts/jython/x3

#如果需要从某个已有镜像克隆虚拟机，则设置镜像路径，要检查此镜像可用，并且路径正确，负责虚拟机会创建失败
#如果需要新建空白磁盘，则设置此项为空
vbacking="/data/images/centos65x64.qcow2"
#虚拟机CPU个数
vcpu=1
#虚拟机内存(G)
vmemory=2
#虚拟机网络"virbr0"为nat方式，要使用桥接方式，请改为桥接网卡名，比如br-ex,要确保此网桥可用
interface="br-ex"
#虚拟机网卡个数设置
nicnums="4"

#-----------------------------------------------------

function argvs_check() {
#check the vmname
	for i in `seq 1 ${nums}`;do
		vname="${vmname}-${i}"
		if virsh -q list --all | awk '{print $2}' | grep -w "${vname}" >/dev/null;then
			echo "error,the vhost ${vname} already exist!"
			exit
		fi
	done

	vdisksize=${vdisksize:-20}
	vcpu=${vcpu:-1}
	vmemory=${vmemory:-2}
	nicnums=${nicnums:-2}

#check the diskdir exist
	if [ ! -d "${vdiskdir}" ];then
		echo "the dir ${vdiskdir} is not exist"
		exit
	fi

#check the interface
	if ! service libvirtd status &>/dev/null;then
		service libvirtd restart &>/dev/null
		[ $? -ne "0" ] && echo "Service libvirtd is not running,please install it or start it"
		exit
	else
		if brctl show | awk 'NR>1 && /^[^\t]/{print $1}' | grep "${interface}" &>/dev/null;then
			ipaddr=$(ifconfig "${interface}" | awk '/inet addr/{print substr($2,6)}')	
			if ! ping -w 3 "${ipaddr}" &>/dev/null;then
				echo "error,the bridge ${interface} need a ip address"
			fi
		else
			echo "error,${interface} is not a bridge"
			exit
		fi
	fi
}

function create_disk() {
	if [ -n "${vbacking}" ];then
		qemu-img create -b "${vbacking}" -f qcow2 "${vdiskdir}/${vname}.disk" "${vdisksize}"G
	else
		qemu-img create -f qcow2 "${vdiskdir}/${vname}.disk" "${vdisksize}"G
	fi
}	

function create_xml() {
	#create the xml file
	cp ${vdiskdir}/base.xml ${vdiskdir}/${vname}.xml
	cd ${vdiskdir}
	sed -i "s/thisisname/${vname}/g" ${vname}.xml
	allname_tmp="${vdiskdir}/${vname}.disk"
	allname="$(echo $allname_tmp | sed -r 's/\//\\\//g')"
	sed -i "s/thisisdiskname/${allname}/g" ${vname}.xml

	[ ! -z ${vcpu} ] && sed -i "s/thisiscpu/${vcpu}/g" ${vname}.xml

	if [ ! -z ${vmemory} ];then
		vmem=$(python -c "print 1024*1024*${vmemory}")
		sed -i "s/thisismem/${vmem}/g" ${vname}.xml
	fi

	sed -i "s/thisisnetwork/${interface}/g" ${vname}.xml
}

function start_domin() {
	cd ${vdiskdir}
	virsh define ${vname}.xml
	virsh start ${vname}
}

function set_basexml() {
rm -fr ${vdiskdir}/base.xml
cat >> ${vdiskdir}/base.xml << 'EOF'
<domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
  <name>thisisname</name>
  <memory unit='KiB'>thisismem</memory>
  <currentMemory unit='KiB'>thisismem</currentMemory>
  <vcpu placement='static'>thisiscpu</vcpu>
  <os>
    <type arch='x86_64' machine='rhel6.5.0'>hvm</type>
    <boot dev='hd'/>
    <boot dev='cdrom'/>
    <bootmenu enable='yes'/>
    <bios useserial='yes' rebootTimeout='0'/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <pae/>
  </features>
  <cpu mode='host-model'>
    <model fallback='allow'/>
  </cpu>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <devices>
    <emulator>/usr/libexec/qemu-kvm</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='none'/>
      <source file='thisisdiskname'/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <controller type='ide' index='0'>
    </controller>
    <controller type='virtio-serial' index='0'>
    </controller>
    <controller type='usb' index='0'>
    </controller>
EOF

for i in `seq 1 ${nicnums}`;do
cat >> ${vdiskdir}/base.xml << 'EOF'
    <interface type='bridge'>
      <source bridge='thisisnetwork'/>
      <model type='virtio'/>
    </interface>
EOF
done

cat >> ${vdiskdir}/base.xml << 'EOF'
    <console type='pty'>
    </console>
    <input type='mouse' bus='ps2'/>
    <graphics type='vnc' autoport='yes' listen='0.0.0.0'>
      <listen type='address' address='0.0.0.0'/>
    </graphics>
    <video>
      <model type='cirrus' heads='1'/>
    </video>
    <memballoon model='virtio'>
    </memballoon>
  </devices>
  <qemu:commandline>
    <qemu:env name='SPICE_DEBUG_ALLOW_MC' value='1'/>
  </qemu:commandline>
</domain>
EOF
}

#main 
function main() {
	for i in `seq 1 ${nums}`;do
		vname="${vmname}-${i}"
		create_disk
		set_basexml
		create_xml
		create_disk
		start_domin
	done
}

argvs_check
main
