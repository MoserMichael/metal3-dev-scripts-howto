#!/bin/bash -i


function Help {
    if [[ $1 != "" ]]; then
        echo "Error: $*"
    fi

cat <<EOF

$0 -m <host> [-h]

ssh to baremetal vm host. possible values for <host>

bootstrap - the bootstrap vm
master-1
...
master-<n>
worker-1
...
worker-<n>

EOF

exit 1
}

set -x 

BHOST=""
while getopts "hm:" opt; do
  case ${opt} in
    h)
	Help
        ;;
    m)
	BHOST="$OPTARG"
       ;;
   esac
done	

if [ "$BHOST" == "bootstrap" ]; then
	MHOST="-"
else
	MHOST="$BHOST"
fi

if [ "$MHOST" == "" ]; then
	Help "-m <host> is missing"
fi


set -x

BOOTRAP_HOST=$(sudo virsh net-dhcp-leases baremetal | grep -E "\s$MHOST\s")

if [ "$BOOTSTRAP_HOST" == "x" ]; then
   echo "host $BHOST not running ($MHOST does not appear in virsh net-dhcp-leases)"
   exit 1
fi

BOOTSTRAP_VM_IP=$(echo "$BOOTRAP_HOST" | /bin/grep ipv4 | tail -n1 | sed -e 's/.*\(192.*\)\/.*/\1/')

if [ "$BOOTSTRAP_VM_IP" == "x" ]; then
   echo "host $BHOST have an ipv4 address"
   exit 1
fi

echo "Attempting to ping $1 on ${BOOTSTRAP_VM_IP} ..." 

ping -w 2 "${BOOTSTRAP_VM_IP}"

echo "Attempting to ssh $1 on ${BOOTSTRAP_VM_IP} ..."

#ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no core@${BOOTSTRAP_VM_IP}
ssh -o StrictHostKeyChecking=no core@${BOOTSTRAP_VM_IP}
