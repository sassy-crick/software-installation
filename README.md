# Automatic software installation script



## Introduction:

The aim of the script is to install the software inside a container, and thus the so installed software is independent from the OS as much as possible. The idea comes from the EESSI project and how the software is installed in there. So kudos to them!

## How-to:

Before the script can run, there are a few files which need to be adjusted. 

- `install.sh`
- `softwarelist.txt`

The `install.sh` does basically the whole magic. There are a few lines at the top which need to be changed to reflect where the software needs to go. The most important are:

- `SOFTWARE_HOME` which is where the software tree and all the helper stuff lives
- `BINDDIR` is the directory which needs to be bound inside the container as per default Singularity does only mount `/tmp` and `/home` it seems.

You also might want to look at:
- `CONTAINER_VERSION` which is the name of the sif-file, i.e. the container
- `EB_VERSION` which is the version of EasyBuild to be used for building software. If that does not exist, it should be automatically installed
- `SW_LIST` contains a simple list of the EasyConfig files to be installed. All in one line with a blank between them. 

The `SW_LIST` might need to be changed later to an EasyStack file. 

The `software.sh` will be created on the fly in the right directory and  does contain the list of software which needs to be installed. 

The first time the script runs, it will create the directory structure but then stops as the Singularity container is not in place. For the full automated installation, we would download the container from somewhere. However, as this only needs to be done once, it is left for now like this.

Once the container in the right folder we are upgrading EasyBuild to the latest version. This way, a module file is created automatically. Once that is done, the software will be installed if required.  

## Requirements:

`Singularity` >= 2.7.x and `fusermount` >= 2.9.7


## To Do:

It needs to be tested on Lustre and/or Ceph as well but that does currently not work as `fusermount` on Rosalind is too old.

