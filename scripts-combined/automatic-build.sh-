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
${BASEDIR}/install.sh ${WORKINGDIR} ${ARCH} 
if [ $? -eq 0 ]; then
	echo "We are testing the installed software on a different container"
	${BASEDIR}/testing.sh ${WORKINGDIR} ${ARCH} 
else
	echo "There was a problem with the installation!"
fi

EOF

sbatch ${WORKINGDIR}/scripts/${ARCH}-submission.sh
done


