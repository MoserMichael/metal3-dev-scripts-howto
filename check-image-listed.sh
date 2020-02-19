#!/bin/bash


ENABLE_CHECK_IMAGE=1
ENABLE_CHECK_DISK=1
ENABLE_CHECK_MEM=1

REQUIRED_DISK_SPACE_GIG=80
REQUIRED_MEM_PER_MASTER_GIG=16
REQUIRED_MEM_PER_WORKER_GIG=8

# this script (if placed into the dev-script directory) checks if the current version defined in OPENSHIFT_RELEASE_IMAGE is listed as a 'green' image
# crawls https://openshift-release.svc.ci.openshift.org/ and extracts 'green links'

URL="https://openshift-release.svc.ci.openshift.org/"

function download_version_page {
    echo "downloading $URL ... "
    wget "$URL" -O out.html
    STAT=$?
    if [[ "$STAT" != "0" ]]; then
      echo "download $URL failed"
      exit 1
    fi
}

function get_green_versions {

    cat out.html | sed -n 's/.*<a class="text-success" href="\([^\"]*\)">\([^\<]*\)<.*$/\2/p'
}


function check_image {

    if [[ "$OPENSHIFT_RELEASE_IMAGE" == "" ]]; then
      echo "skipping image check; environment variable $OPENSHIFT_RELEASE_IMAGE not defined"
      return
    fi


    VER=$(echo "$OPENSHIFT_RELEASE_IMAGE" | sed -n 's/registry.svc.ci.openshift.org\/ocp\/release:\(.*\)$/\1/p')

    if [[ "$VER" == "" ]]; then
      echo "Invalid version string. can't get version from OPENSHIFT_RELEASE_IMAGE : $OPENSHIFT_RELEASE_IMAGE"
      exit 1
    fi

    download_version_page

    IS_PRESENT=$(get_green_versions | grep -cF "$VER")

    if [ "$IS_PRESENT" == "0" ]; then
      echo "Error: version $VER not listed as green version (OPENSHIFT_RELEASE_IMAGE: $OPENSHIFT_RELEASE_IMAGE)"
      exit 1
    fi

    echo "*** image version check passed: version $VER listed as green version ***"
}


function check_memory {
    local workers_mem="$REQUIRED_MEM_PER_WORKER_GIG"
    local masters_mem="$REQUIRED_MEM_PER_MASTER_GIG"
    local total_mem_required
    local freemem_gigs

    masters_mem=$(( masters_mem * NUM_MASTERS ))
    workers_mem=$(( workers_mem * NUM_WORKERS ))

    freemem_gigs=$(free -g | sed -n 2p | awk '{ print $4 }')

    total_mem_required=$(( masters_mem + workers_mem ))

    if [[ $freemem_gigs -lt $total_mem_required ]]; then
      echo "Error: not enough memory. Memory requirement: ${total_mem_required}Gi Free memory ${freemem_gigs}Gi"
      exit 1
    fi

    echo "*** memory requirements passed: enough free memory available ***"
}



function check_disk_space {
    REAL_OPT=$(pwd -P /opt)
    MOUNT_POINT=$(stat ${REAL_OPT} -c '%m')
    FREE_DISK_ON_MOUNT_POINT=$(df -h | sed '1d' | awk '{ print $6,$4 }' | grep -E "^${MOUNT_POINT}[[:space:]]" | awk '{ print $2 }')

    FREE_GIG=$(echo "$FREE_DISK_ON_MOUNT_POINT" |  sed -n 's/\([[:digit:]]*\)G$/\1/p')
 
    if [[ $FREE_GIG -lt $REQUIRED_DISK_SPACE_GIG ]]; then
        echo "Error: not  enough disk space. need $REQUIRED_DISK_SPACE_GIG gig on mount point of /opt - we now have ${FREE_GIG}Gi on ${MOUNT_POINT}"
    fi

    echo "*** disk space check passed: enough free disk for /opt directory  ***"
}

function Help {
    cat <<EOF
$0 [-a] [-n] [-m] [-d] [-i]  [-h] [-v]

check requirements for dev script.

default: perform all checks.

    -a  : enable all checks (default action)
    -n  : disable all checks
    -m  : enable check for sufficient free memory 
          (need ${REQUIRED_MEM_PER_MASTER_GIG}Gi per master) 
          (need ${REQUIRED_MEM_PER_WORKER_GIG}Gi per worker) 

    -d  : enable check for sufficient disk check disk space 
          (need $REQUIRED_DISK_SPACE_GIG}Gi on mount partition of /opt)

    -i  : enable image version validity check

    -h  : show this help message
    -v  : verbose output (for debugging)
EOF
    exit 1
}


set +x
while getopts "hanmdiv" opt; do
  case ${opt} in
    h)
        Help
        ;;
    v)
        set -x
        export PS4='+(${BASH_SOURCE}:${LINENO})'
        VERBOSE=1
        ;;
    n)
        ENABLE_CHECK_IMAGE=0
        ENABLE_CHECK_DISK=0
        ENABLE_CHECK_MEM=0
        ;;
    m)
        ENABLE_CHECK_MEM=1
        ;;
    d)
        ENABLE_CHECK_DISK=1
        ;;
    i)
        ENABLE_CHECK_IMAGE=0
        ;;
    a)
        ENABLE_CHECK_IMAGE=1
        ENABLE_CHECK_DISK=1
        ENABLE_CHECK_MEM=1
        ;;
    *)
        echo "error: invalid flag"
        Help
   esac
done


CFG_FILE="config_${USER}.sh"

if [ ! -f "$CFG_FILE" ]; then 
    echo "can't find $CFG_FILE"
    exit 1
fi

. ${CFG_FILE}
if [[ $VERBOSE != "1" ]]; then
  set +x
fi

if [[ "$ENABLE_CHECK_DISK" != "0" ]]; then
  check_disk_space
fi

if [[ "$ENABLE_CHECK_MEM" != "0" ]]; then
  check_memory
fi

if [[ "$ENABLE_CHECK_IMAGE" != "0" ]]; then
  check_image         
fi


