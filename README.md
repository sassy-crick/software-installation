# Automatic software installation script



## Introduction:

The aim of the script is to install the software inside a container, and thus the so installed software is independent from the OS as much as possible, and also takes care of different architectures. The idea comes from the EESSI project and how the software is installed in there. So kudos to them!!

## How-to:

Before the script can run, there are a few files which need to be adjusted. 

- `install.sh`
- `softwarelist.txt`
- `softwarelist.yaml`

The `install.sh` does basically the whole magic. There are a few lines at the top which need to be changed to reflect where the software needs to go. The most important are:

- `SOFTWARE_INSTDIR` which is where the software tree and all the helper stuff lives
- `BINDDIR` is the directory which needs to be bound inside the container as per default Singularity does only mount `/tmp` and `/home` it seems.

You also might want to look at:

- `CONTAINER_VERSION` which is the name of the sif-file, i.e. the container
- `EB_VERSION` which is the version of EasyBuild to be used for building software. If that does not exist, it should be automatically installed
- `SW_LIST` contains a simple list of the EasyConfig files to be installed. All in one line with a blank between them. 
- `SW_YAML`contains the software to be installed as an EasyStack file in `yaml` format. 

Both the `SW_LIST` and the `SW_YAML` are independent from each other. So as long as the file got a content, it will be used. 

The `software.sh` will be created on the fly in the right directory, using the various template files, and  does contain the list of software which needs to be installed which will be pulled in by the `softwarelist.txt` file. The EasyStack file, so it exists, will be places in the correct directory. 
If you need to change any of the paths where the software will be installed, you will need to look into `software.tmpl`, the Singularity Definition file `Singularity.eb-4.4.2-Lmod-ubuntu20-LTR` and both the `install.sh` and `interactive-install.sh` files. 
Note: You can mount any folder outside the container but you will need to make sure that the `MODULEPATH` variable are identical inside and outside the container. Thus, if you are using like in our example `/apps/easybuild` as the root install directory, the `MODULEPATH` then needs to be set to for example `/apps/easybuild/modules/all` inside and outside the container!

There is currently one bad hack in the `install.sh` script, which is the architecture where the container is running on is determined by a fixed-path script! That will be tidied up at one point, so please be aware of this! 
The idea about using `archspec.py` is that outside the container you got different paths where to install the software, but one common path for all the source files. If you are only having one type of architecture, you can set that manually at the top of the file. 

The first time the script runs, it will create the directory structure but then stops as the Singularity container is not in place. For the full automated installation, we would download the container from somewhere. However, as this only needs to be done once, it is left for now like this.

Once the container in the right folder we are upgrading EasyBuild to the latest version. This way, a module file is created automatically. Once that is done, the software will be installed if required.  

## Requirements:

`Singularity` >= 2.7.x and `fusermount` >= 2.9.7


## To Do:

It needs to be tested on Lustre but that does currently not work as `fusermount` on at the current cluster is too old.

Also, as mentioned above, the `archpsec.py` needs to be installed in a better way.

Finally, it somehow would be nice to include `--cuda-compute-capabilities=8.0` for the A100 GPU builds automatically to make it a bit more fool-proved. 
