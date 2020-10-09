#!/bin/bash

set -u

PXE_VM="PXE4640"
TODO_VM="TODO4640"
NET_NAME="NET_4640"
NET_CIDR="192.168.150.0/24"
PXE_SHH_PORT=""
VM_SSH_PORT=""
SSH_KEY="~/.ssh/acit_admin_id_rsa"

#Creates a bash function which runs VBoxManage.exe when using vbmg
vbmg() {
    VBoxManage.exe "$@";
}


#Checks if there are any existence virtual machines in Vbox
find_machine() {
    local status=$(vbmg list vms | grep "$1" | cut -d'"' -f2)
    if [ -z "$status" ]; then return 1; else return 0; fi
}

find_running_machine() {
    local status=$(vbmg list runningvms | grep "$1" | cut -d'"' -f2)
    if [ -z "$status" ]; then return 1; else return 0; fi
}

find_running_machine "PXE4640" && vbmg controlvm PXE4640 acpipowerbutton

if find_machine "TODO4640"
then
    echo "TODO4640 exists!"
    # Do something else
else
    echo "TODO4640 does not exist."
    # Do something else
fi


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

#Finds the path to the vm folder
SED_PROGRAM="/^Config file:/ { s|^Config file: \+\(.\+\)\\\\.\+\.vbox|\1|; s|\\\\|/|gp }"
VM_FOLDER=$(vbmg showvminfo TODO4640 | sed -ne "$SED_PROGRAM" | tr -d "\r\n")