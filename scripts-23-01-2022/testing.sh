#!/usr/bin/env bash
# Script for the automatic testing of installed software
# We are using different singularity container than the one for the installation
# so we are testing on a different OS
# 16/12/2021: Singularity container to EB 4.5.0 upgraded
#             Initial tests. This script is based on the install.sh script
# 22/01/2022: Added ARCH which will be handed over from the automatic-build.sh 
#             script

# Where is the script located?
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
# SOFTWARE_INSTDIR="/users/k1930241/software" # this comes from the site-config file
SOFTWARE_HOME="${SOFTWARE_INSTDIR}/${ARCH}"
# Which container name to be used:
CONTAINER_VERSION="eb-4.5.0-Lmod-rocky8-3.8.4.sif" # this needs to stay here!
# Which EasyBuild version to be used for the software installation:
# EB_VERSION="4.5.1" # this comes from the site-config file
# Where is the list of the software to be installed:
# The first one is for a list of EasyConfig files
SW_NAME="${WORKINGDIR}/softwarelist.txt"
# This one is for an EasyStack file in yaml format:
SW_YAML="${WORKINGDIR}/softwarelist.yaml"
# We might need to bind an additional external directory into the container:
# BINDDIR="/users/k1930241//software:/software" # this comes from the site-config file

#########################################################################################
# These should not need to be touched
OVERLAY_BASEDIR="${SOFTWARE_HOME}"
OVERLAY_LOWERDIR="${OVERLAY_BASEDIR}/lower"
OVERLAY_UPPERDIR="${OVERLAY_BASEDIR}/apps"
OVERLAY_WORKDIR="${OVERLAY_BASEDIR}/work"
OVERLAY_MOUNTPOINT="/apps/easybuild"
CONTAINER_DIR="${SOFTWARE_INSTDIR}/containers"
CONTAINER="${CONTAINER_DIR}/${CONTAINER_VERSION}"
SCRIPTS_DIR="${WORKINGDIR}/scripts"
SOFTWARE="${SCRIPTS_DIR}/${ARCH}-software-testing.sh"
LOG_DIR="${WORKINGDIR}/logs"
#########################################################################################

echo "Testing started at started at $(date)"
set +ve
# We check if the folders are here, if not we install them
if [ ! -d ${SOFTWARE_INSTDIR} ]; then
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

# We need to export these variables so we can modify the template for the software to be installed
export EASYBUILD_SOURCEPATH
export EASYBUILD_INSTALLPATH
export CORES
export MODULEPATH
export EB_VERSION
# export SW_LIST # we do this further down!
export SW_YAML
export WORKINGDIR
export ARCH

# We make a scripts and log directory in the working-directory, as that one is unique to all builds.
mkdir -p ${SCRIPTS_DIR} ${LOG_DIR}

# We create the software.sh file on the fly in the right place. Any previous version will be removed.
envsubst '${EASYBUILD_SOURCEPATH},${EASYBUILD_INSTALLPATH},${CORES},${MODULEPATH},${EB_VERSION}' < ${BASEDIR}/software-head.tmpl > ${SOFTWARE} 
if [ -s ${SW_NAME} ]; then
        SW_LIST=$(cat ${SW_NAME})
        export SW_LIST
        envsubst '${SW_LIST},${WORKINGDIR}' < ${BASEDIR}/software-list-test.tmpl >> ${SOFTWARE} 
fi
if [ -s ${SW_YAML} ]; then
        envsubst '${SW_YAML},${WORKINGDIR}' < ${BASEDIR}/software-yaml-test.tmpl >> ${SOFTWARE} 
        cp -f ${SW_YAML} ${SCRIPTS_DIR}
fi
# IF the above was successfull, we will build the tarball and the sha256sum file 
envsubst '${ARCH}' < ${BASEDIR}/software-bottom-test.tmpl >> ${SOFTWARE}

chmod a+x ${SOFTWARE}

# We check if we already have an EasyBuild module file.
# If there is none, we stop here as something went wrong. 
# If the directory exist and the requested EasyBuild version is there, we simply test the
# software stack which we provide. 
if [ -e ${OVERLAY_UPPERDIR}/modules/all/EasyBuild/${EB_VERSION}.lua ]; then
	echo "We are testing the software as defined in ${SOFTWARE}"
        cat "${SOFTWARE}"
	# We can execute the container and tell it what to do:
 	singularity exec --bind ${BINDDIR} --fusemount "container:${OVERLAY_BASEDIR}/fuse-overlayfs -o lowerdir=${OVERLAY_LOWERDIR} \
	-o upperdir=${OVERLAY_UPPERDIR} -o workdir=${OVERLAY_WORKDIR} ${OVERLAY_MOUNTPOINT}" ${CONTAINER} ${SOFTWARE}
else
	echo "It appears that there is no module file for ${EB_VERSION}, so we stop here!"
	exit 3
fi

echo "Installation finished at $(date)"

