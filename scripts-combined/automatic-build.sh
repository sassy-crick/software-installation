#!/usr/bin/env bash
# Submission script which will start the automatic build process.
# We are basically sourcing the site-conf file to get all the variables
# for SLURM we need. As right now we are only having one architecture, we 
# are not using a loop for all architectures. 
# The script expects the path to be the first argument. 
# 15.12.2021: Initial, primitive script

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

# Make sure the directories are in place
mkdir -p ${WORKINGDIR}/{logs,scripts}

for i in $PLATFORMS ; do
$i

# This is for EasyBuild installations (or both)
if [[ ${INSTALLING} == "EB" || ${INSTALLING} == "BOTH" ]] ; then

cat <<EOF> ${WORKINGDIR}/scripts/${ARCH}-submission.sh
#!/usr/bin/env bash
# This is for SLURM. We might need to add to this!
# #SBATCH -C shape=${CONSTRAINT}
#SBATCH -p ${PARTITION}
#SBATCH -c ${CORES}
#SBATCH --job-name=${ARCH} 
#SBATCH -o ${WORKINGDIR}/logs/%j-${ARCH}.out 

export CORES=${CORES} 

# Now we run the job:
${BASEDIR}/easybuild/install.sh ${WORKINGDIR} ${ARCH} 
if [ $? -eq 0 ]; then
	echo "We are testing the installed software on a different container"
	${BASEDIR}/easybuild/testing.sh ${WORKINGDIR} ${ARCH} 
else
	echo "There was a problem with the installation!"
fi

EOF

sbatch ${WORKINGDIR}/scripts/${ARCH}-submission.sh
fi 

# This is for EESSI installations (or both)
if [[ ${INSTALLING} == "EESSI" || ${INSTALLING} == "BOTH" ]] ; then

cat <<EOF> ${WORKINGDIR}/scripts/${ARCH}-eessi-submission.sh
#!/usr/bin/env bash
# This is for SLURM. We might need to add to this!
# #SBATCH -C shape=${CONSTRAINT}
#SBATCH -p ${PARTITION}
#SBATCH -c ${CORES}
#SBATCH --job-name=${ARCH}-eessi
#SBATCH -o ${WORKINGDIR}/logs/%j-${ARCH}.out

export CORES=${CORES}
export EESSI_PILOT_VERSION=2021.12
EESSI_TMPDIR=/tmp/eessi

mkdir -p \${EESSI_TMPDIR}/software
cp -R ${BASEDIR}/eessi/software-layer \${EESSI_TMPDIR}
cp ${BASEDIR}/eessi/software-layer/EESSI-pilot-install-software-easystack.sh \${EESSI_TMPDIR}/software-layer
cp ${WORKINGDIR}/softwarelist.yaml \${EESSI_TMPDIR}/software/easystack.yml
cd \${EESSI_TMPDIR}/software-layer

echo \$PWD

./build_container.sh run \${EESSI_TMPDIR} ./run_in_compat_layer_env.sh ./EESSI-pilot-install-software-easystack.sh
if [ \$? -eq 0 ]; then
    # right now the ARCH seems to be set to Haswell, which is wrong as we are on Zen2
    # So we simply set that here to zen2
    # This should be automatically determined but somehow that does not work for the tarball it seems. 
    EESSI_SOFTWARE_SUBDIR=\$(cat /dev/shm/EESSI_SOFTWARE_SUBDIR)
    echo "Architecture is \$EESSI_SOFTWARE_SUBDIR"
    TARBALL=\${EESSI_TMPDIR}/eessi-\${EESSI_PILOT_VERSION}-software-linux-${ARCH////-}-$(date +'%s').tar.gz
    ./build_container.sh run \${EESSI_TMPDIR} ./create_tarball.sh \${EESSI_TMPDIR} \${EESSI_PILOT_VERSION} \${EESSI_SOFTWARE_SUBDIR} \${TARBALL}
    cp \${TARBALL} ${WORKINGDIR}
fi
EOF

sbatch ${WORKINGDIR}/scripts/${ARCH}-eessi-submission.sh
fi

done


