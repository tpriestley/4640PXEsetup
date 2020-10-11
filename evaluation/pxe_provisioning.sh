#!/bin/bash

set -uxe

PXE_VM="PXE4640"
TODO_VM="TODO4640"
TODO_VDI="STORAGE4640"
NET_NAME="NET_4640"
NET_CIDR="192.168.150.0/24"
SSH_KEY="~/.ssh/acit_admin_id_rsa"
PXE_PORT_FORWARDING="PXESSH:tcp:[]:9222:[192.168.150.10]:22"
TODOSSH_PORT_FORWARDING="TODOSSH:tcp:[]:8022:[192.168.150.200]:22"
VMHTTP_PORT_FORWARDING="VMHTTP:tcp:[]:8080:[192.168.150.200]:80"

#Creates a bash function which runs VBoxManage.exe when using vbmg
vbmg() {
    VBoxManage.exe "$@";
}


#Checks if there are any existing virtual machines in Vbox
find_machine() {
    local status=$(vbmg list vms | grep "$1" | cut -d'"' -f2)
    if [ -z "$status" ]; then return 1; else return 0; fi
} 

find_running_machine() {
    local status=$(vbmg list runningvms | grep "$1" | cut -d'"' -f2)
    if [ -z "$status" ]; then return 1; else return 0; fi
}

#Setup the NAT-network
vbmg natnetwork add --netname ${NET_NAME} --enable --dhcp off \
    --network ${NET_CIDR} \
    --port-forward-4  ${PXE_PORT_FORWARDING}
    --port-forward-4  ${TODOSSH_PORT_FORWARDING}
    --port-forward-4  ${VMHTTP_PORT_FORWARDING}

#Start PXE vm
vbmg startvm ${PXE_VM}

#Waiting for virtual machine to be up and running
while /bin/true; do
    ssh -i ${SSH_KEY} -p 9222 \
        -q -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        admin@localhost exit
    if [ $? -ne 0 ]; then
            echo "PXE server is not up, sleeping..."
            sleep 5
    else
            break
    fi
done

#Check if TODO4640 exists, remove the TODO4640 and create a new one
if find_machine "TODO4640"
then
    echo "TODO4640 exists!"
    vbmg controlvm $TODO_VM poweroff
    vbmg unregistervm $TODO_VM --delete
else
    echo "TODO4640 does not exist."
    #Create TODO4640
    vbmg createvm --name ${TODO_VM} --ostype RedHat_64 --register
    #Modify TODO4640
    vbmg modifyvm ${TODO_VM} \
    --memory 2048 \
    --nic1 natnetwork --nat-network1 NET4640 --cableconnected1 on \
    --boot1 disk --boot2 net --boot3 none --boot4 none \
    --graphicscontroller vmsvga
    #Add a 10GB hard disk to TODO4640
    vbmg storagectl ${TODO_VM} --name $TODO_VDI --add sata --controller IntelAHCI
    vbmg createmedium disk --filename /full/path/to/the/disk_file.vdi --size 10240
fi

#Waiting for virtual machine to be up and running
while /bin/true; do
    ssh -i ${SSH_KEY} -p 8022 \
        -q -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        admin@localhost exit
    if [ $? -ne 0 ]; then
            echo "Waiting for TODO4640 install to complete..."
            sleep 5
    else
            break
    fi
done



#Finds the path to the vm folder
SED_PROGRAM="/^Config file:/ { s|^Config file: \+\(.\+\)\\\\.\+\.vbox|\1|; s|\\\\|/|gp }"
VM_FOLDER=$(vbmg showvminfo TODO4640 | sed -ne "$SED_PROGRAM" | tr -d "\r\n")

find_running_machine "PXE4640" && vbmg controlvm PXE4640 acpipowerbutton
