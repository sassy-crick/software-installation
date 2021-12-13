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

# Some defaults
# Where is the script located?
BASEDIR=$(dirname "$0")

# We need to know which architecture we are running on.
# This is right now a bit of a hack
ARCH=$(cd /users/hpcbuild/build/tox/black && ./bin/python3 ./bin/eessi_software_subdir.py | awk -F"/" '{print $2"/"$3}')

# We need to set the right paths first.
# We do that via variables up here:
# These are the only bits which need to be modified:
# Where to install the software:
SOFTWARE_INSTDIR="/software/easybuild"
SOFTWARE_HOME="${SOFTWARE_INSTDIR}/${ARCH}"
# Which container name to be used:
CONTAINER_VERSION="eb-4.4.2-Lmod-ubuntu20-LTR-3.8.4.sif"
# Which EasyBuild version to be used for the software installation:
EB_VERSION="4.5.0"
# Where is the list of the software to be installed:
SW_LIST=$(cat ./softwarelist.txt)
# We might need to bind an additional external directory into the container:
BINDDIR="/software:/software"

# We need to export them so we can modify the template for the software to be installed
export EB_VERSION
export SW_LIST

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

# We create the software.sh file on the fly in the right place. Any previous version will be removed.
rm -f ${SOFTWARE}
envsubst '${EB_VERSION},${SW_LIST}' < ${BASEDIR}/software.tmpl > ${SOFTWARE} 
chmod a+x ${SOFTWARE}

# We check if we got the fuse-overly installed and if not, install it
if [ ! -f ${OVERLAY_BASEDIR}/fuse-overlayfs ]; then
	 wget -O ${OVERLAY_BASEDIR}/fuse-overlayfs https://github.com/containers/fuse-overlayfs/releases/download/v1.7.1/fuse-overlayfs-x86_64
	 chmod a+x ${OVERLAY_BASEDIR}/fuse-overlayfs  
fi

# We check if we already have an EasyBuild module file.
# If there is none, we assume it is a fresh installation and so we need
# to upgrade EasyBuild to the latest version first before we can continue
if [ ! -d ${OVERLAY_UPPERDIR}/modules/all/EasyBuild ]; then
		singularity exec --bind ${BINDDIR} --fusemount "container:${OVERLAY_BASEDIR}/fuse-overlayfs -o lowerdir=${OVERLAY_LOWERDIR} \
		-o upperdir=${OVERLAY_UPPERDIR} -o workdir=${OVERLAY_WORKDIR} ${OVERLAY_MOUNTPOINT}" ${CONTAINER} eb --install-latest-eb-release
	elif [ ! -e ${OVERLAY_UPPERDIR}/modules/all/EasyBuild/${EB_VERSION}.lua ]; then
	       	echo "We are upgrading EasyBuild to the latest version and then stop."
		# We can execute the container and tell it what to do:
		singularity exec --bind ${BINDDIR} --fusemount "container:${OVERLAY_BASEDIR}/fuse-overlayfs -o lowerdir=${OVERLAY_LOWERDIR} \
		-o upperdir=${OVERLAY_UPPERDIR} -o workdir=${OVERLAY_WORKDIR} ${OVERLAY_MOUNTPOINT}" ${CONTAINER} eb --install-latest-eb-release
fi

# If the directory exist and the latest EasyBuild module is there, we simply install the
# software stack which we provide. 
if [ -e ${OVERLAY_UPPERDIR}/modules/all/EasyBuild/${EB_VERSION}.lua ]; then
	echo "We are installing the software as defined in ${SOFTWARE}"
    cat "${SOFTWARE}"
	# We can execute the container and tell it what to do:
 	singularity exec --bind ${BINDDIR} --fusemount "container:${OVERLAY_BASEDIR}/fuse-overlayfs -o lowerdir=${OVERLAY_LOWERDIR} \
	-o upperdir=${OVERLAY_UPPERDIR} -o workdir=${OVERLAY_WORKDIR} ${OVERLAY_MOUNTPOINT}" ${CONTAINER} ${SOFTWARE}
fi

echo "Installation finished at $(date)"

