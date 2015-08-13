#!/bin/bash
#Time:2015-7-16
#Note:Create the VMs accroding to the settings
#Version:2.0.2
#Author:www.isjian.com

#Version 2.0.2 ChangeLog:
#--添加身份检查，只允许root身份执行
#Version 2.0.1 ChangeLog:
#--vmname 变量只能为字母数字，下划线
#--virsh 命令存在检查
#--创建前检查虚拟磁盘是否存在
#Version 2.0 ChangeLog:
#--Fix some bugs
#--Add the variables check before create the vms
#--Set the vms ip before create the vms

#------------------------ argvs ---------------------------

#虚拟机数量
nums=2
#虚拟机名字，如果创建多个虚拟机,虚拟机将被命名方式为vmhost-1,vmhost-2,vmhost-n 形式,该变量只能为数字，字母下划线
vmname="x3"
#虚拟机磁盘大小(单位为G),默认为20G,最小4G
vdisksize=20
#虚拟磁盘存放目录
vdiskdir=/data/vhosts/x3

#vbacking设置虚拟机所使用的模板镜像，此项是必要的，请确保此处设置的镜像可用，否则虚拟机会创建失败
vbacking="/data/images/centos65x64-2.6kernel.qcow2"
#虚拟机核数(正整数)
vcpu=1
#虚拟机内存(G)
vmemory=1
#虚拟机网卡个数
nicnums="2"
#虚拟机网络配置方式，"virbr0"为nat方式，要使用桥接，请改为桥接网卡名，比如br-ex,请确保此网桥可用
interface="br-ex"

#是否设置虚拟机ip地址("y" or "n")
ipalter="y"

#注意：以下变量仅在ipalter设置为"y"时生效
#############################################
#虚拟机ip获取方式("dhcp" or "static")
nettype=static
#如果nettype使用static方式，则需要设置以下信息,ip地址数必须与创建的虚拟机个数匹配,中间须用空格隔开
vmipaddr="172.16.12.56 172.16.12.57"
vmnetmask="255.255.255.0"
vmgateway="172.16.12.254"
#############################################

#-----------------------------------------------------------

function argvs_check() {
#check the variable nums
	if ! test ${nums} -ge 1 2>/dev/null;then
		echo "Error! --The number of vm ${nums} set error!"
		exit 3
	fi

#check the virsh command 
	if ! which virsh &>/dev/null;then
		echo "Error! --the libvirt is not install,please install via:yum install libvirt-client libvirt"
		exit 2
	fi

#check the vmname 
	if ! echo "${vmname}" | grep -E "^\w+$" &>/dev/null;then
		echo "Error! --The name ${vmname} is illegal"
		exit 2
	fi

#check the vmname and vmdisk exists
	for k in `seq 1 ${nums}`;do
		vname="${vmname}-${i}"
		if virsh -q list --all | awk '{print $2}' | grep -w "${vname}" &>/dev/null;then
			echo "Error! --The vm ${vname} already exist!"
			exit 2
		fi

		if ls ${vdiskdir}/${vname}.disk &>/dev/null;then
			echo "Error! --The disk ${vdiskdir}/${vname}.disk already exist!"
			exit 2
		fi
	done

	vdisksize=${vdisksize:-20}
	vcpu=${vcpu:-1}
	vmemory=${vmemory:-2}
	nicnums=${nicnums:-2}

#check the diskdir exist
	if [ ! -d "${vdiskdir}" ];then
		echo "Error! --The dir ${vdiskdir} is not exist"
		exit 4
	fi

#check the backing file exist	
	if [ ! -f "${vbacking}" ];then
		echo "Error! --The backing file ${vbacking} not exist"
		exit 5
	fi

#check the interface
	if ! service libvirtd status &>/dev/null;then
		service libvirtd restart &>/dev/null
		[ $? -ne "0" ] && echo "Error! --Service libvirtd is not running,please install it or start it"
		exit 4
	else
		if brctl show | awk 'NR>1 && /^[^\t ]/{print $1}' | grep "${interface}" &>/dev/null;then
			ipaddr=$(ifconfig "${interface}" | awk '/inet addr/{print substr($2,6)}')	
			if ! ping -w 3 "${ipaddr}" &>/dev/null;then
				echo "Error! --The bridge ${interface} need a ip address"
				exit 6
			fi
		else
			echo "Error! --The ${interface} is not a bridge"
			exit
		fi
	fi

#check the vmipaddr
	if [ "${ipalter}" != "y" ] && [ "${ipalter}" != "n" ];then
		echo "Error! --Set the variable ipalter to 'y' or 'n'"
		exit 2
	fi

#when set the ip addr,Check the following options
	if [ "${ipalter}" == "y" ];then
	
		ipnums=`echo "${vmipaddr}" | awk '{print NF}'`
		if [ "${ipnums}" -ne "${nums}" ];then
			echo "Error! --The number of vm are:${nums},but the number of ip are:${ipnums},Both of them must be equal!"
			exit 7
		fi

		if [ "${nettype}" == "dhcp" ];then
			echo "dhcp set ok"
		elif [ "${nettype}" == "static" ];then
			[ -z "${vmipaddr}" ] && echo "Error! --you must set the vm ip address!" && exit 2
			[ -z "${vmnetmask}" ] && echo "Error! --you must set the vm netmask!" && exit 2
			[ -z "${vmgateway}" ] && echo "Error! --you must set the vm gateway!" && exit 2
		else
			echo "Error! --set the variable nettype to 'dhcp' or 'static'"
			exit 6
		fi

		if ! which "virt-copy-in" &>/dev/null;then
			echo "Error! --The virt-copy-in tools not install,please install via 'yum install libguestfs libguestfs-tools-c'"
			exit 8
		fi
	fi
}

function create_disk() {
	echo "++++++++"
	qemu-img create -b "${vbacking}" -f qcow2 "${vdiskdir}/${vname}.disk" "${vdisksize}"G &>/dev/null
	if [ "$?" -ne "0" ];then
		echo "create ${vdiskdir}/${vname}.disk OK!"
		exit 4
	fi 
	echo "create ${vdiskdir}/${vname}.disk OK!"
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

	virsh define ${vname}.xml &>/dev/null
	echo "define ${vname} OK!"
}

function create_ipaddr() {
	if [ "${ipalter}" == "y" ];then
		echo "Set the ${vname} ip address..."
		rm -fr ifcfg-eth0
		macaddr=`virsh domiflist ${vname} | awk 'NR==3{print $5}'`
		if [ "${nettype}" == "static" ];then
			eth0ip=`echo $vmipaddr | awk -v i=${i} '{print $i}'`
			cat > ifcfg-eth0 <<- EOF
			DEVICE=eth0
			HWADDR=${macaddr}
			TYPE=Ethernet
			ONBOOT=yes
			NM_CONTROLLED=no
			BOOTPROTO=static
			IPADDR=${eth0ip}
			NETMASK=${vmnetmask}
			GATEWAY=${vmgateway}
			DNS1=223.5.5.5
			DNS2=223.6.6.6
			EOF
		elif [ "${nettype}" == "dhcp" ];then
			cat > ifcfg-eth0 <<- EOF
			DEVICE=eth0
			HWADDR=${macaddr}
			TYPE=Ethernet
			ONBOOT=yes
			NM_CONTROLLED=no
			BOOTPROTO=dhcp
			EOF
		fi

		sed -r -i "s/^( |\t)*//g" ifcfg-eth0
		virt-copy-in -a ${vdiskdir}/${vname}.disk ifcfg-eth0 /etc/sysconfig/network-scripts/
		echo "Set the ${vname} ip address OK!"
		rm -fr ifcfg-eth0
	fi
}

function start_domin() {
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

for j in `seq 1 ${nicnums}`;do
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

function main() {
	for i in `seq 1 ${nums}`;do
		vname="${vmname}-${i}"
		create_disk
		set_basexml
		create_xml
		create_ipaddr
		start_domin
	done
}

#check the user 
if [ `whoami` != root ]; then
	echo "Error! --you must login in as root"
	exit
fi
argvs_check
main
