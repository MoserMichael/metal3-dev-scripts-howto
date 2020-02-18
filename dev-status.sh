#!/bin/bash -x

# script to run the commands that get us some info on the cluster status

sudo virsh list

sudo virsh net-dhcp-leases baremetal

oc --config  ~/dev-scripts/ocp/auth/kubeconfig get nodes

#./show_bootstrap_log.sh


