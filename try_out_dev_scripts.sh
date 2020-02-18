#!/bin/bash

set -ex

VERSION="4.3"
OC_PARAM="--config  ~/dev-scripts/ocp/auth/kubeconfig"
TAKE=1


function download_version_page { 
    wget https://openshift-release.svc.ci.openshift.org/ -O out.html                                                                                                                          
}


function get_green_versions {

    cat out.html | sed -n 's/.*<a class="text-success" href="\([^"]*\)">\([^\<]*\)<.*$/\2/p'
}


function run_dev_script {

    rm -rf ./failures || true
    mkdir ./failures || true

    echo "**** take $TAKE : running dev scripts $REL **** "
    
    export OPENSHIFT_RELEASE_IMAGE="$REL"
    sudo rm -rf /opt/dev-scripts /opt/metal3-dev-env logs/* make.log


    nohup make clean all  >make.log 2>&1 &

    echo "running make clean all in the background. waiting for a long time each turn...."
    date
    sleep 45m

    # check if cluster is up
    set +e
    OC_OUT=`oc $OC_PARAM get nodes 2>&1`  
    STAT=$?
    set -e 

    echo "oc get nodes: ${OC_OUT}"


    if [[  "$STAT" != 0 ]]; then

	set +e 

	sudo virsh list 2>&1 | tee ./failures/virsh-list.${TAKE}.log
	sudo virsh net-dhcp-leases baremetal 2>&1 | tee ./failures/virsh-dhcp.${TAKE}.log

        nohup ./show_bootstrap_log.sh bootkube.service >"./failures/bootstrap_log.fail.${TAKE}.log" 2>&1
	sleep 2m
	pkill show_bootstrap_log.sh
	kill $(ps -elf | grep ssh | grep journal | awk '{ print $4 }')

        mv  -f make.log ./failures/nohup.fail.${TAKE}.log
        mv logs ./failures/logs_fail.${TAKE}

        pkill  make  || true
        pkill -9 make || true 
	set -e

    else
        echo "kubectl output ${OUT} . has dev-scripts succeeded now?"
        exit 0
    fi

    ((TAKE+=1))


}

download_version_page

CI_VERSIONS=`get_green_versions | grep ".ci." | grep "$VERSION"`
NIGHTLY_VERSIONS=`get_green_versions | grep ".nightly." | grep "$VERSION"`

ALL_VERSIONS=$(echo -e "$CI_VERSIONS\n$NIGHTLY_VERSIONS")


while IFS= read -r line; do 
    REL="registry.svc.ci.openshift.org/ocp/release:$line"

    run_dev_script

done <<< "$ALL_VERSIONS"


