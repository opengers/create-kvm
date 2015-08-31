#!/bin/bash
<<<<<<< .merge_file_IABqZj
#Date:2015-8-30
#Note:Create the VMs accroding to the settings
#Version:2.1.beta
=======
#Date:2015-8-18
#Note:Create the VMs accroding to the settings
#Version:2.0.3
>>>>>>> .merge_file_AeJkMh
#Author:www.isjian.com

set -e
#---------------------- ChangeLog -------------------------
#Version 2.1(beta) ChangeLog:
#--允许添加另一块数据盘
#--允许设置虚拟机主机名
#Version 2.0.3 ChangeLog:
#--自定义虚拟机名称编号，vmhost-n,vmhost-{n+1},...
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

#虚拟机数量(正整数)
nums=2
#虚拟机初始编号,例如初始编号为3,则虚拟命名为vmhost-3,vmhost-4,vmhost-5,默认编号从1开始(正整数)
<<<<<<< .merge_file_IABqZj
startnum=4
=======
startnum=2
>>>>>>> .merge_file_AeJkMh
#虚拟机名字,该变量只能为(数字，字母下划线的组合)
vmname="test"
#虚拟磁盘存放目录(目录路径最后不需要带"/")
vdiskdir=/data/vhosts/test
#backing_image设置虚拟机的模板镜像，此项是必要的，请确保此处设置的镜像可用，负责虚拟机会创建失败
backing_image="/data/images/centos65x64-2.6kernel.qcow2"

#虚拟机CPU数(正整数,默认1)
vcpu=1
#虚拟机内存(G,默认1)
vmemory=1
<<<<<<< .merge_file_IABqZj
#虚拟机根磁盘大小(单位为G),默认为20G
=======
#虚拟机磁盘大小(单位为G),默认为20G
>>>>>>> .merge_file_AeJkMh
vdisksize=40
#数据盘大小,单位为G(留空则不添加)
vdisk_vdb=""
#虚拟机网卡个数(默认2)
nicnums="2"
#虚拟机网络配置方式，可以使用nat，或者桥接方式
#--nat方式: 虚拟机通过nat方式访问外网,virbr0为libvirt自动创建，默认使用192.168.122.0/24这个网段
#--桥接方式: 要使用桥接方式访问外网,请改为宿主机上的某个网桥,比如br-ex,请确保此网桥可用(支持Linux Bridge,暂不支持OVS)
interface="br-ex"
#虚拟机主机名，多个主机名之间用空格隔开，主机名个数需和新建的虚拟机数量(nums)保持一致
vmhostname="test-1 test-2"

#是否设置虚拟机ip地址("y" or "n")
ipalter="y"

#注意：以下变量仅在ipalter设置为"y"时生效
#############################################
#虚拟机ip获取方式("dhcp" or "static")
nettype=static
#如果nettype使用static方式，则需要设置以下信息,ip地址数必须与创建的虚拟机个数匹配,中间须用空格隔开
vmipaddr="172.16.12.61 172.16.12.62"
vmnetmask="255.255.255.0"
vmgateway="172.16.12.254"
#############################################

<<<<<<< .merge_file_IABqZj
#------------------- function -----------------------------
function argvs_check() {
	if [ `whoami` != root ]; then
   		echo "Error! --you must login in as root"
   		exit
=======
#-----------------------------------------------------------

function argvs_check() {
#check the var nums
	if ! test "${nums}" -ge 1 2>/dev/null;then
		echo "Error! --The nums set error!"
		exit 3
>>>>>>> .merge_file_AeJkMh
	fi
	
	nums=${nums:-1}
	vdisksize=${vdisksize:-20}
	vcpu=${vcpu:-1}
	vmemory=${vmemory:-2}
	nicnums=${nicnums:-2}
    startnum=${startnum:-1}

#check the var
	for inum in "${nums}" "${startnum}" "${vdisksize}" "${vcpu}" "${vmemory}" "${nicnums}"
	do
		if ! test "${inum}" -ge 1 2>/dev/null;then
			echo "Error! --The ${inum} set error!"
			exit 3
		fi
	done

<<<<<<< .merge_file_IABqZj
#check the var vdisk_vdb
	if [ ! -z ${vdisk_vdb} ];then
		if ! test "${vdisk_vdb}" -ge 1 2>/dev/null;then
			echo "Error! --The startnum set error!"
			exit 3
		fi
=======
#check the var startnum
	if ! test "${startnum}" -ge 1 2>/dev/null;then
		echo "Error! --The startnum set error!"
		exit 3
>>>>>>> .merge_file_AeJkMh
	fi

#check the virsh command 
	if ! which virsh &>/dev/null;then
		echo "Error! --the libvirt is not install,please install it via:yum install libvirt-client libvirt"
		exit 2
	fi

#check the vmname 
	if ! echo "${vmname}" | grep -E "^\w+$" &>/dev/null;then
		echo "Error! --The vmname set is illegal"
		exit 2
	fi

#check the diskdir exist
	if [ ! -d "${vdiskdir}" ];then
		echo "Error! --The dir ${vdiskdir} is not exist"
		exit 4
	fi

#check the backing file exist	
	if [ ! -f "${backing_image}" ];then
		echo "Error! --The backing file ${backing_image} not exist"
		exit 5
	fi

#check whether the disk exist
	for k in `seq ${startnum} $((startnum+nums-1))`;do
		vname="${vmname}-${k}"
		if virsh -q list --all | awk '{print $2}' | grep -w "${vname}" &>/dev/null;then
			echo "Error! --The vm ${vname} already exist!"
			exit 2
		fi

		if ls ${vdiskdir}/${vname}.disk &>/dev/null;then
			echo "The disk ${vdiskdir}/${vname}.disk already exist!"
			exit 2
		fi

		if [ ! -z "${vdisk_vdb}" ];then
	        if ls ${vdiskdir}/${vname}-data1.disk &>/dev/null;then
   	        	echo "The disk ${vdiskdir}/${vname}-data1.disk already exist!"
   		    	exit 2
        	fi	
		fi
	done

<<<<<<< .merge_file_IABqZj
#check the vmhostname
	hostnamenums=`echo "${vmhostname}" | awk '{print NF}'`
	if [ "${hostnamenums}" -ne "${nums}" ];then
		echo "Error! --The number of vm are:${nums},but the number of hostname are:${hostnamenums},Both of them must be equal!"
		exit 4
	fi
=======
	vdisksize=${vdisksize:-20}
	vcpu=${vcpu:-1}
	vmemory=${vmemory:-2}
	nicnums=${nicnums:-2}
    startnum=${startnum:-1}
>>>>>>> .merge_file_AeJkMh

#check the interface
	if ! service libvirtd status &>/dev/null;then
		service libvirtd restart &>/dev/null
		[ $? -ne "0" ] && echo "Error! --Service libvirtd is not running,please install it or start it"
		exit 4
	else
		if brctl show | awk 'NR>1 && /^[^\t]/{print $1}' | grep "${interface}" &>/dev/null;then
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
			exit 2
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
	qemu-img create -b "${backing_image}" -f qcow2 "${vdiskdir}/${vname}.disk" "${vdisksize}"G &>/dev/null
	if [ "$?" -ne "0" ];then
<<<<<<< .merge_file_IABqZj
		echo "Error! --can't create ${vdiskdir}/${vname}.disk"
=======
		echo "create ${vdiskdir}/${vname}.disk OK!"
>>>>>>> .merge_file_AeJkMh
		exit 4
	fi 
	echo "create ${vdiskdir}/${vname}.disk OK!"

	if [ ! -z ${vdisk_vdb} ];then
		qemu-img create -f qcow2 "${vdiskdir}/${vname}-data1.disk" "${vdisk_vdb}"G &>/dev/null
		if [ "$?" -ne "0" ];then
        	echo "Error! --can't create ${vdiskdir}/${vname}-data1.disk"
        	exit 4
    	fi 
    	echo "create datadisk ${vdiskdir}/${vname}-data1.disk OK!"
	fi
}	

function create_xml() {
	#create the xml file
<<<<<<< .merge_file_IABqZj
	\cp -rf ${vdiskdir}/base.xml ${vdiskdir}/${vname}.xml
	cd ${vdiskdir}
	sed -i "s/thisisname/${vname}/g" ${vname}.xml
	allname_tmp="${vdiskdir}/${vname}"
	allname="$(echo $allname_tmp | sed -r 's/\//\\\//g')"
	sed -i "s/thisisdiskname/${allname}\.disk/g" ${vname}.xml
	sed -i "s/thisisdatadiskname/${allname}-data1\.disk/g" ${vname}.xml

	sed -i "s/thisiscpu/${vcpu}/g" ${vname}.xml

	vmem=$(python -c "print int(1024*1024*${vmemory})")
	sed -i "s/thisismem/${vmem}/g" ${vname}.xml

	sed -i "s/thisisnetwork/${interface}/g" ${vname}.xml

	virsh define ${vname}.xml &>/dev/null && echo "define ${vname} OK!" || echo "Error! --can't define ${vname}"
=======
	cp ${vdiskdir}/base.xml ${vdiskdir}/${vname}.xml
	cd ${vdiskdir}
	sed -i "s/thisisname/${vname}/g" ${vname}.xml
	allname_tmp="${vdiskdir}/${vname}.disk"
	allname="$(echo $allname_tmp | sed -r 's/\//\\\//g')"
	sed -i "s/thisisdiskname/${allname}/g" ${vname}.xml

	[ ! -z ${vcpu} ] && sed -i "s/thisiscpu/${vcpu}/g" ${vname}.xml

	if [ ! -z ${vmemory} ];then
		vmem=$(python -c "print int(1024*1024*${vmemory})")
		sed -i "s/thisismem/${vmem}/g" ${vname}.xml
	fi

	sed -i "s/thisisnetwork/${interface}/g" ${vname}.xml

	virsh define ${vname}.xml &>/dev/null
	echo "define ${vname} OK!"
>>>>>>> .merge_file_AeJkMh
}

function create_ipaddr() {
	if [ "${ipalter}" == "y" ];then
		echo "Set the ${vname} ip address..."
<<<<<<< .merge_file_IABqZj
		\rm -fr /tmp/ifcfg-eth0
		macaddr=`virsh domiflist ${vname} | awk 'NR==3{print $5}'`
		if [ "${nettype}" == "static" ];then
			eth0ip=`echo "$vmipaddr" | awk -v m=${l} '{print $m}'`
			cat > /tmp/ifcfg-eth0 <<- EOF
=======
		rm -fr ifcfg-eth0
		macaddr=`virsh domiflist ${vname} | awk 'NR==3{print $5}'`
		if [ "${nettype}" == "static" ];then
			eth0ip=`echo $vmipaddr | awk -v m=${l} '{print $m}'`
			l=$((l+1))
			cat > ifcfg-eth0 <<- EOF
>>>>>>> .merge_file_AeJkMh
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
<<<<<<< .merge_file_IABqZj
			cat > /tmp/ifcfg-eth0 <<- EOF
=======
			cat > ifcfg-eth0 <<- EOF
>>>>>>> .merge_file_AeJkMh
			DEVICE=eth0
			HWADDR=${macaddr}
			TYPE=Ethernet
			ONBOOT=yes
			NM_CONTROLLED=no
			BOOTPROTO=dhcp
			EOF
		fi

<<<<<<< .merge_file_IABqZj
		sed -r -i "s/^( |\t)*//g" /tmp/ifcfg-eth0
		virt-copy-in -a ${vdiskdir}/${vname}.disk /tmp/ifcfg-eth0 /etc/sysconfig/network-scripts/
		echo "Set the ${vname} ip address OK!"
		\rm -f /tmp/ifcfg-eth0
	fi
}

function set_vmhostname {
	echo "set the ${vmname} hostname..."
	ihostname=`echo "${vmhostname}" | awk -v m=${l} '{print $m}'`
	\rm -f /tmp/network
	cat >> /tmp/network <<- EOF
	NETWORKING=yes
	HOSTNAME=${ihostname}
	EOF
	virt-copy-in -a ${vdiskdir}/${vname}.disk /tmp/network /etc/sysconfig/
	if [ $? -eq 0 ];then
		echo "set the ${vmname} hostname ok"
	else
		echo "Error! --can't set the ${vmname} hostname"
		exit 3
=======
		sed -r -i "s/^( |\t)*//g" ifcfg-eth0
		virt-copy-in -a ${vdiskdir}/${vname}.disk ifcfg-eth0 /etc/sysconfig/network-scripts/
		echo "Set the ${vname} ip address OK!"
		rm -fr ifcfg-eth0
>>>>>>> .merge_file_AeJkMh
	fi
}

function start_domin() {
	virsh start ${vname}
}

function set_basexml() {
<<<<<<< .merge_file_IABqZj
\rm -f ${vdiskdir}/base.xml
=======
rm -fr ${vdiskdir}/base.xml
>>>>>>> .merge_file_AeJkMh
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
EOF

if [ ! -z ${vdisk_vdb} ];then
	cat >> ${vdiskdir}/base.xml << 'EOF'
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='none'/>
      <source file='thisisdatadiskname'/>
      <target dev='vdb' bus='virtio'/>
    </disk>
EOF
fi

cat >> ${vdiskdir}/base.xml << 'EOF'
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

#main 
function main() {
	l=1
	for i in `seq ${startnum} $((startnum+nums-1))`;do
		vname="${vmname}-${i}"
		create_disk
		set_basexml
		create_xml
		create_ipaddr
		set_vmhostname
		start_domin
		l=$((l+1))
	done
	unset l
}

#check the user 
if [ `whoami` != root ]; then
    echo "Error! --you must login in as root"
    exit
fi
argvs_check
main
