#!/usr/bin/env bash
# Script for the automatic installation of software
# We are using a singularity container for the installation
# so we are isolated from the OS
# This script does the actual installation.
# The software stack, so to speak will be in the 
# software.sh script. That will be replaced with a yml file
# later for production. 
# 28/10/2021: initial testing
# 09/11/2021: some tidy up
# 18/11/2021: Singularity container to EB 4.4.2 upgraded
# 23/11/2021: Installation path changed to /apps/easybuild
# 15/12/2021: Including a site specific site-config enfironment file which
#             contains all the configurable variables, so we got one place
#             to rule them all.
#             We also hand over the full path where to find the EasyStack file 
#             for example. This is also where any output files will go to. 
#             The WORKINGDIR comes from the GitHub app and will change for each 
#             run


# Where is the script located?
#BASEDIR=$(dirname "$0")
BASEDIR=$PWD

# Some defaults which we get from the site-config environment file
source ${BASEDIR}/site-config

# We need to know the path where to find the EasyStack file for example. 
if [ -s "$1" -a -d "$1" ]; then
        WORKINGDIR="$1"
else
        echo "The ${WORKINGDIR} does not appear to be a directory!"
        echo "Bombing out!"
        exit 2
fi

# We need to know which architecture we are running on.
# Right now, that happens at submission time

if [ -n "$2" ]; then 
        ARCH="$2"
else
        echo "No architecture was defined, so we are stopping here!"
        exit 2
fi

# We need to set the right paths first.
# We do that via variables up here:
# These are the only bits which need to be modified:
# Where to install the software:
SOFTWARE_INSTDIR="/users/k1930241/software"
SOFTWARE_HOME="${SOFTWARE_INSTDIR}/${ARCH}"
# Which container name to be used:
CONTAINER_VERSION="eb-4.4.2-Lmod-ubuntu20-LTR-3.8.4.sif"
# Which EasyBuild version to be used for the software installation:
# EB_VERSION="4.5.1" # this comes from the site-config file
# Where is the list of the software to be installed:
# The first one is for a list of EasyConfig files
SW_NAME="${WORKINGDIR}/softwarelist.txt"
# This one is for an EasyStack file in yaml format:
SW_YAML="${WORKINGDIR}/softwarelist.yaml"
# We might need to bind an additional external directory into the container:
BINDDIR="/users/k1930241/software:/software"

#########################################################################################
# These should not need to be touched
OVERLAY_BASEDIR="${SOFTWARE_HOME}"
OVERLAY_LOWERDIR="${OVERLAY_BASEDIR}/lower"
OVERLAY_UPPERDIR="${OVERLAY_BASEDIR}/apps"
OVERLAY_WORKDIR="${OVERLAY_BASEDIR}/work"
OVERLAY_MOUNTPOINT="/apps/easybuild"
CONTAINER_DIR="${SOFTWARE_INSTDIR}/containers"
CONTAINER="${CONTAINER_DIR}/${CONTAINER_VERSION}"
SCRIPTS_DIR="${OVERLAY_BASEDIR}/scripts"
SOFTWARE="${SCRIPTS_DIR}/software.sh"
#########################################################################################

echo "Installation started at $(date)"

# We check if the folders are here, if not we install them
if [ -d ${SOFTWARE_INSTDIR} ]; then
	echo "Making sure all directories exist in ${SOFTWARE_HOME} "
	mkdir -p ${OVERLAY_BASEDIR}/{lower,apps,work,scripts}
	mkdir -p ${SOFTWARE_INSTDIR}/sources
else
	echo "It appears that ${SOFTWARE_HOME} does not exist"
	echo "Please make sure the provided path is correct and make the required directory"
	echo "Bombing out here."
	exit 2
fi

# We check if the singularity container exists
if [ ! -f ${CONTAINER} ]; then
	echo "The Singularity Container ${CONTAINER} does not exist!"
	echo "Please install the container before you can continue."
	echo "Bombing out here."
	exit 2
fi

# We check if we got the fuse-overly installed and if not, install it
if [ ! -f ${OVERLAY_BASEDIR}/fuse-overlayfs ]; then
	 curl -o ${OVERLAY_BASEDIR}/fuse-overlayfs -L https://github.com/containers/fuse-overlayfs/releases/download/v1.7.1/fuse-overlayfs-x86_64
	 chmod a+x ${OVERLAY_BASEDIR}/fuse-overlayfs  
fi

# We check if we already have an EasyBuild module file.
# If there is none, we assume it is a fresh installation and so we need
# to upgrade EasyBuild to the latest version first before we can continue
#if [ ! -d ${OVERLAY_UPPERDIR}/modules/all/EasyBuild ]; then
#		singularity exec --bind ${BINDDIR}  --fusemount "container:${OVERLAY_BASEDIR}/fuse-overlayfs -o lowerdir=${OVERLAY_LOWERDIR} \
#		-o upperdir=${OVERLAY_UPPERDIR} -o workdir=${OVERLAY_WORKDIR} ${OVERLAY_MOUNTPOINT}" ${CONTAINER} eb --install-latest-eb-release
#	elif [ ! -e ${OVERLAY_UPPERDIR}/modules/all/EasyBuild/${EB_VERSION}.lua ]; then
#	       	echo "We are upgrading EasyBuild to the latest version and then stop."
#		# We can execute the container and tell it what to do:
#		singularity exec --bind ${BINDDIR}  --fusemount "container:${OVERLAY_BASEDIR}/fuse-overlayfs -o lowerdir=${OVERLAY_LOWERDIR} \
#		-o upperdir=${OVERLAY_UPPERDIR} -o workdir=${OVERLAY_WORKDIR} ${OVERLAY_MOUNTPOINT}" ${CONTAINER} eb --install-latest-eb-release
#fi

# If the directory exist and the latest EasyBuild module is there, we simply install the
# software stack which we provide. 
#if [ -e ${OVERLAY_UPPERDIR}/modules/all/EasyBuild/${EB_VERSION}.lua ]; then
	echo "This container is running on ${ARCH}"
	# We can execute the container and tell it what to do:
 	singularity shell --bind ${BINDDIR}  --fusemount "container:${OVERLAY_BASEDIR}/fuse-overlayfs -o lowerdir=${OVERLAY_LOWERDIR} \
	-o upperdir=${OVERLAY_UPPERDIR} -o workdir=${OVERLAY_WORKDIR} ${OVERLAY_MOUNTPOINT}" ${CONTAINER} 
#fi

#echo "Installation finished at $(date)"

