#!/bin/bash
#Changedate:2015-9-22
#Note:Create the VMs accroding to the settings
#Version:2.5.1
#Author:www.isjian.com
#Copyright

set -e
#---------------------- ChangeLog -------------------------
#Version 2.5.1 ChangeLog:
#--可以自定义每个虚拟机的详细配置(名字，cpu，内存，hostname，磁盘大小,网卡数,ip地址)
#Version 2.1 ChangeLog:
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
#虚拟机个数(正整数)
V_nums=3
#虚拟机名字,多个虚拟机之间用空格隔开
#该变量只能为数字，字母下划线的组合
V_name="test-1 test-2 test-3"
#虚拟机CPU个数,多个值之间用空格隔开(正整数)
V_cpu="1 2 1"
#虚拟机内存大小(单位为G),多个值之间用空格隔开
V_memory="1 2 1"
#虚拟机根磁盘大小(正整数，单位为G)
V_rootsize="30 40 50"

#注:上面设置表示新建三台虚拟机，"test-1"为第一台虚机名称(
#virsh list命令看到的),其CPU个数为1，内存为1G，根磁盘大小为
#30G，"test-2"其CPU个数为2，内存为2G，根磁盘大小为40G,"test-3"
#其CPU个数为3，内存为3G，根磁盘大小为50G

#下面变量设置规则同上

#要创建的数据盘大小,单位为G
#如果不需要数据盘，则设置此变量为空，如V_datasize=""
#若只是其中某个虚机不需要数据盘，则在其相应位置上用"-"表示
#若设置为V_datasize="20 - 30",则表示第二台虚机(test-2)不创建数据盘
V_datasize="20 - 40"

#虚拟机网卡个数(正整数)
V_nics="2 2 1"
#虚拟机主机名(hostname)，多个主机名之间用空格隔开
V_hostname="test-1 test-2 test-3"

#虚拟机网络配置方式，可以使用nat，或者桥接方式
#--nat方式: 虚拟机通过nat方式访问外网,virbr0为libvirt自动创建，默认使用192.168.122.0/24这个网段
#--桥接方式: 要使用桥接方式访问外网,请改为宿主机上的某个网桥,比如br-ex,请确保此网桥可用(支持Linux Bridge,暂不支持OVS)
H_bridge="br-ex"
#虚拟磁盘存放目录(目录路径最后不需要带"/")
H_vmdir=/data/vhosts/test
#backing_image设置虚拟机的模板镜像，此项是必要的，请确保此处设置的镜像可用，负责虚拟机会创建失败
H_backimage="/data/images/centos65x64-2.6kernel.qcow2"

#是否设置虚拟机ip地址("y" or "n")
ipalter="y"

#注意：以下变量仅在ipalter设置为"y"时生效
#############################################
#虚拟机ip获取方式("dhcp" or "static")
V_nettype=static
#如果nettype使用static方式，则需要设置以下信息,
#ip地址数必须与创建的虚拟机个数匹配,中间用空格隔开
V_ip="172.16.12.63 172.16.12.64 172.16.12.65"
V_netmask="255.255.255.0"
V_gateway="172.16.12.254"
#注意:多个虚机的netmask和gateway是相同的
#############################################

#------------------- function -----------------------------
function argvs_check() {
	if [ `whoami` != root ]; then
   		echo "Error! --you must login in as root"
   		exit
	fi

	if ! test "${V_nums}" -ge 1 2>/dev/null;then
		echo "Error! --The ${V_nums} is illegal!"
		exit 3
	fi

#must be three argvs
	m=0
	for i in "${V_name}" "${V_cpu}" "${V_memory}" "${V_rootsize}" "${V_hostname}" "${V_nics}" "${V_datasize}" "${V_ip}"
	do
		m=$((m+1))
		if [ ${m} -eq 7 ];then
			[ -z "${i}" ] && continue
		fi
		
		if [ ${m} -eq 8 ];then
			if [ ${ipalter} != "y" ] || [ "${V_nettype}" != "static" ];then
				continue
			fi
		fi

		i_nums=`echo "${i}" | awk '{print NF}'`
		if [ "${i_nums}" -ne "${V_nums}" ];then
			echo "Error! --The number of [ ${i} ] is not equal to ${V_nums}"
			exit 4
		fi

		if echo "$m" | grep -E "(2|3|4|6|7)" &>/dev/null;then
			for j in ${i};do
				if [ "$m" -eq 7 ] && [ "${j}" == "-" ];then
					continue
				fi
				if ! test "${j}" -ge 1 2>/dev/null;then
					echo "Error! --The ${j} is illegal!"
					exit 3
				fi
			done
		fi

		if echo "$m" | grep -E "(1|5)" &>/dev/null;then
			for k in ${i};do
				if ! echo "${k}" | grep -E "^(\w|-)+$" &>/dev/null;then
					echo "Error! --The var:${k} is illegal"
					exit 2
				fi
			done
		fi
	done

#check the diskdir exist
	if [ ! -d "${H_vmdir}" ];then
		echo "Error! --The dir ${H_vmdir} is not exist"
		exit 4
	fi

#check the backing file exist	
	if [ ! -f "${H_backimage}" ];then
		echo "Error! --The backing file ${H_backimage} not exist"
		exit 5
	fi

#check whether the disk exist
    for l in `seq 1 ${V_nums}`;do
        v_name_tmp=`echo "${V_name}" | awk -v m=${l} '{print $m}'`
		if virsh -q list --all | awk '{print $2}' | grep -w "${v_name_tmp}" &>/dev/null;then
			echo "Error! --The vm ${v_name_tmp} already exist!"
			exit 2
		fi

		if ls ${H_vmdir}/${v_name_tmp}.disk &>/dev/null;then
			echo "The disk ${H_vmdir}/${v_name_tmp}.disk already exist!"
			exit 2
		fi

		if [ ! -z "${V_datasize}" ];then
	        if ls ${H_vmdir}/${v_name_tmp}-data1.disk &>/dev/null;then
   	        	echo "The disk ${H_vmdir}/${v_name_tmp}-data1.disk already exist!"
   		    	exit 2
        	fi	
		fi
	done

#check the virsh cmd
	if ! which virsh &>/dev/null;then
		echo "Error! --the libvirt is not install,please install it via:yum install libvirt-client libvirt"
		exit 2
	fi
	if ! which "virt-copy-in" &>/dev/null;then
		echo "Error! --The virt-copy-in tools not install,please install via 'yum install libguestfs libguestfs-tools-c'"
		exit 8
	fi

#check the interface
	if ! service libvirtd status &>/dev/null;then
		service libvirtd restart &>/dev/null
		[ $? -ne "0" ] && echo "Error! --Service libvirtd is not running,please install it or start it"
		exit 4
	else
		if brctl show | awk 'NR>1 && /^[^\t]/{print $1}' | grep "${H_bridge}" &>/dev/null;then
			ipaddr=$(ifconfig "${H_bridge}" | awk '/inet addr/{print substr($2,6)}')	
			if ! ping -w 3 "${ipaddr}" &>/dev/null;then
				echo "Error! --The bridge ${H_bridge} need a ip address"
				exit 6
			fi
		else
			echo "Error! --The ${H_bridge} is not a bridge"
			exit
		fi
	fi

#when set the ip addr,Check the following options
	if [ "${ipalter}" == "y" ];then
		if [ "${V_nettype}" == "dhcp" ];then
			echo "dhcp set ok"
		elif [ "${V_nettype}" == "static" ];then
			v_ip_tmp=`echo "${V_ip}" | awk '{print NF}'`
        	if [ "${v_ip_tmp}" -ne "${V_nums}" ];then
            	echo "Error! --The number of ${v_ip_tmp} is not equal to ${V_nums}"
            	exit 4
        	fi

			if ! ping -w 3 "${V_gateway}" &>/dev/null;then
                echo "Error! --The gateway:${V_gateway} not access"
                exit 3
            fi

            if [ -z "${V_netmask}" ];then
                echo "Error! --you must set the vm netmask!"
                exit 3
            fi
		else
			echo "Error! --set the variable nettype to 'dhcp' or 'static'"
			exit 6
		fi
	elif [ "${ipalter}" == "n" ];then
		echo "won't set the vm ips..."
	else
		echo "Error! --Set the variable ipalter to 'y' or 'n'"
		exit 2
	fi
}

function create_disk() {
	echo "++++++++"
	qemu-img create -b "${H_backimage}" -f qcow2 "${H_vmdir}/${v_name}.disk" "${v_rootsize}"G &>/dev/null
	if [ "$?" -ne "0" ];then
		echo "Error! --can't create rootdisk ${H_vmdir}/${v_name}.disk"
		exit 4
	fi 
	echo "create rootdisk ${H_vmdir}/${v_name}.disk ok!"

	if [ ! -z "${V_datasize}" ] && [ "${v_datasize}" != "-" ];then
		qemu-img create -f qcow2 "${H_vmdir}/${v_name}-data1.disk" "${v_datasize}"G &>/dev/null
		if [ "$?" -ne "0" ];then
        	echo "Error! --can't create datadisk ${H_vmdir}/${v_name}-data1.disk"
        	exit 4
    	fi 
    	echo "create datadisk ${H_vmdir}/${v_name}-data1.disk ok!"
	fi
}	

function create_xml() {
	#create the xml file
	\cp -f ${H_vmdir}/base.xml ${H_vmdir}/${v_name}.xml
	cd ${H_vmdir}
	sed -i "s/thisisname/${v_name}/g" ${v_name}.xml
	allname_tmp="${H_vmdir}/${v_name}"
	allname="$(echo ${allname_tmp} | sed -r 's/\//\\\//g')"
	sed -i "s/thisisdiskname/${allname}\.disk/g" ${v_name}.xml
	sed -i "s/thisisdatadiskname/${allname}-data1\.disk/g" ${v_name}.xml

	sed -i "s/thisiscpu/${v_cpu}/g" ${v_name}.xml

	vmem=$(python -c "print int(1024*1024*${v_memory})")
	sed -i "s/thisismem/${vmem}/g" ${v_name}.xml

	sed -i "s/thisisnetwork/${H_bridge}/g" ${v_name}.xml

	virsh define ${v_name}.xml &>/dev/null && echo "define ${v_name} ok!" || echo "Error! --can't define ${v_name}"
}

function create_ipaddr() {
	if [ "${ipalter}" == "y" ];then
		echo "Set the ${v_name} ip address..."
		\rm -f /tmp/ifcfg-eth0
		v_mac=`virsh domiflist ${v_name} | awk 'NR==3{print $5}'`
		if [ "${V_nettype}" == "static" ];then
			cat > /tmp/ifcfg-eth0 <<- EOF
			DEVICE=eth0
			HWADDR=${v_mac}
			TYPE=Ethernet
			ONBOOT=yes
			NM_CONTROLLED=no
			BOOTPROTO=static
			IPADDR=${v_ip}
			NETMASK=${V_netmask}
			GATEWAY=${V_gateway}
			DNS1=223.5.5.5
			DNS2=223.6.6.6
			EOF
		elif [ "${V_nettype}" == "dhcp" ];then
			cat > /tmp/ifcfg-eth0 <<- EOF
			DEVICE=eth0
			HWADDR=${v_mac}
			TYPE=Ethernet
			ONBOOT=yes
			NM_CONTROLLED=no
			BOOTPROTO=dhcp
			EOF
		fi

		sed -r -i "s/^( |\t)*//g" /tmp/ifcfg-eth0
		virt-copy-in -a ${H_vmdir}/${v_name}.disk /tmp/ifcfg-eth0 /etc/sysconfig/network-scripts/
		echo "Set the ${v_name} ip address OK!"
		\rm -f /tmp/ifcfg-eth0
	fi
}

function set_vmhostname {
	\rm -f /tmp/network
	cat >> /tmp/network <<- EOF
	NETWORKING=yes
	HOSTNAME=${v_hostname}
EOF
	sed -r -i "s/^( |\t)*//g" /tmp/network
	virt-copy-in -a ${H_vmdir}/${v_name}.disk /tmp/network /etc/sysconfig/
	if [ $? -eq 0 ];then
		echo "set the ${v_name} hostname ok"
	else
		echo "Error! --can't set the ${v_name} hostname"
		exit 3
	fi
}

function start_vm() {
	virsh start ${v_name}
}

function set_basexml() {
\rm -f ${H_vmdir}/base.xml
cat >> ${H_vmdir}/base.xml << 'EOF'
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

if [ ! -z "${V_datasize}" ] && [ "${v_datasize}" != "-" ];then
	cat >> ${H_vmdir}/base.xml << 'EOF'
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='none'/>
      <source file='thisisdatadiskname'/>
      <target dev='vdb' bus='virtio'/>
    </disk>
EOF
fi

cat >> ${H_vmdir}/base.xml << 'EOF'
    <controller type='ide' index='0'>
    </controller>
    <controller type='virtio-serial' index='0'>
    </controller>
    <controller type='usb' index='0'>
    </controller>
EOF

for j in `seq 1 ${v_nics}`;do
cat >> ${H_vmdir}/base.xml << 'EOF'
    <interface type='bridge'>
      <source bridge='thisisnetwork'/>
      <model type='virtio'/>
    </interface>
EOF
done

cat >> ${H_vmdir}/base.xml << 'EOF'
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
	for i in `seq 1 ${V_nums}`;do
		v_name=`echo "${V_name}" | awk -v m=${i} '{print $m}'`
		v_cpu=`echo "${V_cpu}" | awk -v m=${i} '{print $m}'`
		v_memory=`echo "${V_memory}" | awk -v m=${i} '{print $m}'`
		v_rootsize=`echo "${V_rootsize}" | awk -v m=${i} '{print $m}'`
		v_datasize=`echo "${V_datasize}" | awk -v m=${i} '{print $m}'`
		v_nics=`echo "${V_nics}" | awk -v m=${i} '{print $m}'`
		v_hostname=`echo "${V_hostname}" | awk -v m=${i} '{print $m}'`
		v_ip=`echo "${V_ip}" | awk -v m=${i} '{print $m}'`
		create_disk
		set_basexml
		create_xml
		create_ipaddr
		set_vmhostname
		start_vm
	done
}

argvs_check
main
