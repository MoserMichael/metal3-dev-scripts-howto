#!/bin/bash -e


# this script (if placed into the dev-script directory) checks if the current version defined in OPENSHIFT_RELEASE_IMAGE is listed as a 'green' image 
# crawls https://openshift-release.svc.ci.openshift.org/ and extracts 'green links'

. config_${USER}.sh

URL="https://openshift-release.svc.ci.openshift.org/"

function download_version_page { 
    set +e
    echo "downloading $URL ... "
    wget "$URL" -O out.html
    STAT=$?
    set -e
    if [[ "$STAT" != "0" ]]; then
      echo "download $URL failed"
      exit 1
    fi
}

function get_green_versions {

    cat out.html | sed -n 's/.*<a class="text-success" href="\([^\"]*\)">\([^\<]*\)<.*$/\2/p'
}

if [[ "$OPENSHIFT_RELEASE_IMAGE" == "" ]]; then
  echo "environment varable $OPENSHIFT_RELEASE_IMAGE not defined"
  exit 1
fi


set +x

VER=$(echo $OPENSHIFT_RELEASE_IMAGE | sed -n 's/registry.svc.ci.openshift.org\/ocp\/release:\(.*\)$/\1/p')

if [[ "$VER" == "" ]]; then
  echo "Invalid version string. can't get version from OPENSHIFT_RELEASE_IMAGE : $OPENSHIFT_RELEASE_IMAGE"
  exit 1
fi

download_version_page

IS_PRESENT=$(get_green_versions | grep -F "$VER" | wc -l)

if [ "$IS_PRESENT" == "0" ]; then
  echo "version $VER not listed as green version (OPENSHIFT_RELEASE_IMAGE: $OPENSHIFT_RELEASE_IMAGE)"
  exit 1
fi

echo "*** version $VER listed as green version! ***"








