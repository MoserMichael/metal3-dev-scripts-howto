# instructions to get going with openshift metal3 dev-scripts

The [project](https://github.com/openshift-metal3/dev-scripts) installs openshift cluster in vm's that emulate baremetal nodes. 
This text records the steps to make it work. (worked on 10/2/2020)
Thanks to [Yuval Kashtan](https://github.com/yuvalk) for his help

- get a RHEL8.1 system.

- activate the RHEL system

```
subscription-manager register
/with the redhat user/

subscription-manager attach --auto
```

- check if required disk space is present

  The following command displays the available disk space
```
  df -h
```
  make sure that /opt is is a file system that has at least 80GB space.
  (I had to make a symbolic link from /opt to /usr that had enough disk space)

- Prepare the pull secret:
   open url in browser: https://cloud.redhat.com/openshift/install#pull-secret
   login with redhat account
   choose 'openstack platform'
   choose 'download pull secret'

-   Add an additional section to the downloaded pull secret; assuming that the pull secret is in file pull_secret
   (you can do that manually or use the jq utility)

```

AA='"registry.svc.ci.openshift.org":{"auth":"c3lzdGVtLXNlcnZpY2VhY2NvdW50LWtuaS1kZWZhdWx0OmV5SmhiR2NpT2lKU1V6STFOaUlzSW10cFpDSTZJaUo5LmV5SnBjM01pT2lKcmRXSmxjbTVsZEdWekwzTmxjblpwWTJWaFkyTnZkVzUwSWl3aWEzVmlaWEp1WlhSbGN5NXBieTl6WlhKMmFXTmxZV05qYjNWdWRDOXVZVzFsYzNCaFkyVWlPaUpyYm1raUxDSnJkV0psY201bGRHVnpMbWx2TDNObGNuWnBZMlZoWTJOdmRXNTBMM05sWTNKbGRDNXVZVzFsSWpvaVpHVm1ZWFZzZEMxMGIydGxiaTAxZEdkbU55SXNJbXQxWW1WeWJtVjBaWE11YVc4dmMyVnlkbWxqWldGalkyOTFiblF2YzJWeWRtbGpaUzFoWTJOdmRXNTBMbTVoYldVaU9pSmtaV1poZFd4MElpd2lhM1ZpWlhKdVpYUmxjeTVwYnk5elpYSjJhV05sWVdOamIzVnVkQzl6WlhKMmFXTmxMV0ZqWTI5MWJuUXVkV2xrSWpvaVlqZzNNRGt4WmpZdE5qRXlNeTB4TVdVNUxXRTJNVGt0TkRJd01UQmhPR1V3TURBeUlpd2ljM1ZpSWpvaWMzbHpkR1Z0T25ObGNuWnBZMlZoWTJOdmRXNTBPbXR1YVRwa1pXWmhkV3gwSW4wLm51VGR0RlczRENHcFpvT0pCbU45VjQwWG1wbmlZRE9tUnI2Z05vNGVwRVBrb1lDXzk1YmhWX0ttYjhoTnprOTNVTGtDNnJXNTVjTXFQMVM4RHh3QWw0RUxRZ2NFZXIyalBJLXZBNGUzdlZ5cHNLbS1XSkFxcWo2OGhNN0Z4ekMzRGgxY19lN19EQkJLOWtxZmcyRzZiNTJXQmI2RUhsODg2Q2Nza3JBVm1fbmprNS14ay1Ma1hSM3lXNW5JeXlZdXhNVGg1LUNMd3lQQy1yLVIzeklzdnlWelNPVTgyeUJaaE1tUmc3enUtOWlydThENHdqRFJQclhiSm1FV3lBM1FIUlJ2VTJuci01MTFEeEhEbWhtNW14YU0tSFA4emk3SU8zVEU5SU55S3BqTmo5eTIwNmtFN0NNSVNMWmRWWFl3MkpIQ1BmSmJQMHNJY3V0dnFvOTdGdw=="}'

cat pull-secret | jq '.auths += {'"$AA"' } ' | jq -c . >new_pull_secret

``` 

- install some packages on the RHEL machine (as root)
```
   dnf update
   dnf install git make sudo
```

- add a non root user

```
  adduser dev                                                                                                                                                                                
```

- add dev user to wheel group (so that it can use sudo)

```
   usermod -aG wheel dev                                                                                                                                                                      
```

- as root: enable sudo without login

  edit /etc/sudoers as root so that the following lines are uncommented (look like this):

```
    %wheel  ALL=(ALL)       ALL                                                                                                                                                               
    %wheel ALL=(ALL)       NOPASSWD: ALL                                                                                                                                                     
```

- get the dev-script project

```
    su - dev
    git clone https://github.com/openshift-metal3/dev-scripts.git
    cd dev-scripts
```

- prepare configuration file:

```
   cp config_example.sh config_dev.sh                                                                                                                                                        
```

- edit configuration file config_dev.sh

add the following line to config_dev.sh

```
  export VIRSH_DEFAULT_CONNECT_URI=qemu:///system
```

- add the pull secret (here you need the content of file new_pull_secret prepared earlier. add the line 

```
  export PULL_SECRET='... paste in the content of new_pull_secret here...'
```

- add number of nodes required

```
export NUM_WORKERS=3
export NUM_MASTERS=3
```

- optional: choose a openshift image 

 if you skip this step it will attempt to install the latest and greatest openshift image;
 If you require a particular image:

 visit https://openshift-release.svc.ci.openshift.org/ and choose an approved version (in green)

 click on a url in green.

 look for the following line and copy the /approved version/: 
 oc adm release extract --tools /approved version/

 in config_dev.sh file add the following line

```
export OPENSHIFT_RELEASE_IMAGE='/approved version/'
```

- if not for the first time: clean previous attempts to run dev-script installation

```
   sudo rm -rf /opt/dev-scripts /opt/metal3-dev-env logs/*
   make clean
```

- run the make (takes a lot of time; i use nohup so that it will continue with the procedure if you log off)


```
   nohup make &
```

- monitor progress of the proceedings:

follow nohup.out or files in logs/ directory


display vm's running.
```
  sudo virsh list
```

once the bootstrap VM is bringing up the node vm's, monitor if all nodes are up.

```
   cd ~/dev-scripts
   oc --config ./ocp/auth/kubeconfig get nodes
```


watch that all pods are well (status Running or Completed with not too many restarts)

````
oc --config ./ocp/auth/kubeconfig get pods --all-namespaces`
````

- on the .bashrc i put in the alias (as user dev)

```
alias oc='oc --config  ~/dev-scripts/ocp/auth/kubeconfig'

```

- to add some command completion to oc

```
oc completion bash >tmp
sudo cp tmp  /etc/bash_completion.d/oc_completion
```


## looking at problems when the boot process gets stuck


### bootstrap vm is running, but nodes don't come up.

```
    # see if bootrap vm is still running
    sudo virsh list

    #ssh to bootrap vm in dev-scripts:
    # get ip of vm (host name for the bootstrap vm is -)
    sudo virsh net-dhcp-leases baremetal

    # ssh to bootstrap vm
    ssh -l core /host-ip/

    once on the node:
    journalctl -b -f -u bootkube.service
```
