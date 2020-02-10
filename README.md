# instructions to get going wih openshift metal3 dev-scripts

- get a RHEL8.1 system.


- Prepare the pull secret:
   open url in browser: https://cloud.redhat.com/openshift/install#pull-secret
   login with redhat account
   choose 'openstack platform'
   choose 'download pull secret'

-   Add an additional section to the downloaded pull secret; assuming that the pull secret is in file pull_secret

```
export ADD='registry.svc.ci.openshift.org":{"auth":"c3lzdGVtLXNlcnZpY2VhY2NvdW50LWtuaS1kZWZhdWx0OmV5SmhiR2NpT2lKU1V6STFOaUlzSW10cFpDSTZJaUo5LmV5SnBjM01pT2lKcmRXSmxjbTVsZEdWekwzTmxjblpwWTJWaFkyTnZkVzUwSWl3aWEzVmlaWEp1WlhSbGN5NXBieTl6WlhKMmFXTmxZV05qYjNWdWRDOXVZVzFsYzNCaFkyVWlPaUpyYm1raUxDSnJkV0psY201bGRHVnpMbWx2TDNObGNuWnBZMlZoWTJOdmRXNTBMM05sWTNKbGRDNXVZVzFsSWpvaVpHVm1ZWFZzZEMxMGIydGxiaTAxZEdkbU55SXNJbXQxWW1WeWJtVjBaWE11YVc4dmMyVnlkbWxqWldGalkyOTFiblF2YzJWeWRtbGpaUzFoWTJOdmRXNTBMbTVoYldVaU9pSmtaV1poZFd4MElpd2lhM1ZpWlhKdVpYUmxjeTVwYnk5elpYSjJhV05sWVdOamIzVnVkQzl6WlhKMmFXTmxMV0ZqWTI5MWJuUXVkV2xrSWpvaVlqZzNNRGt4WmpZdE5qRXlNeTB4TVdVNUxXRTJNVGt0TkRJd01UQmhPR1V3TURBeUlpd2ljM1ZpSWpvaWMzbHpkR1Z0T25ObGNuWnBZMlZoWTJOdmRXNTBPbXR1YVRwa1pXWmhkV3gwSW4wLm51VGR0RlczRENHcFpvT0pCbU45VjQwWG1wbmlZRE9tUnI2Z05vNGVwRVBrb1lDXzk1YmhWX0ttYjhoTnprOTNVTGtDNnJXNTVjTXFQMVM4RHh3QWw0RUxRZ2NFZXIyalBJLXZBNGUzdlZ5cHNLbS1XSkFxcWo2OGhNN0Z4ekMzRGgxY19lN19EQkJLOWtxZmcyRzZiNTJXQmI2RUhsODg2Q2Nza3JBVm1fbmprNS14ay1Ma1hSM3lXNW5JeXlZdXhNVGg1LUNMd3lQQy1yLVIzeklzdnlWelNPVTgyeUJaaE1tUmc3enUtOWlydThENHdqRFJQclhiSm1FV3lBM1FIUlJ2VTJuci01MTFEeEhEbWhtNW14YU0tSFA4emk3SU8zVEU5SU55S3BqTmo5eTIwNmtFN0NNSVNMWmRWWFl3MkpIQ1BmSmJQMHNJY3V0dnFvOTdGdw=='                                                                                                                         
                                                                                                                                                                                              
cat pull-secret | jq '.auths += '$ADD | jq -c >new_pull_secret                                                                                                                                
``` 

- check disk space

  The following command displays the available disk space
```
  df -h
```
  make sure that /opt is is a file system that has at least 80GB space.
  (I had to make a symbolic link from /opt to /usr that had enough disk space)

- install some packages on the RHEL machine (as root)
```
   dnf update
   dnf install gi make sudo
```

- add a non root user

```
  adduser dev                                                                                                                                                                                
```

- add dev user to wheel group (so that it can use sudo)

```
   adduser -aG wheel dev                                                                                                                                                                      
```

- as root: enable sudo without login

  edit /etc/sudoers as root and uncomment  

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

- if not for the first time: clean previous attempts to run dev-script installation

```
   make clean
   sudo rm -rf /opt/dev-scripts /opt/metal3-dev-env
```

- run the make (takes a lot of time; i use nohup so that it will continue with the procedure if you log off)


```
   nohup make &
```

- monitor progress of the proceedings:


display vm's running.
```
  sudo virsh list
```

once the bootstrap VM is bringing up the node vm's.

```
   cd ~/dev-scripts
   oc --config ./ocp/auth/kubeconfig get nodes
```



  
   

- 

- 
   
