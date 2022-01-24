#!/bin/bash
#SBATCH --job-name=build_easystack
#SBATCH --time=01:00:00
#SBATCH -p cpu
#SBATCH -c 36
#SBATCH -o /users/k1930241/testing/11/logs/%j-eessi.out

# Debugging
set -ve
set -o noclobber

mkdir -p /users/k1930241/testing/11/logs
ARCH=x86_64/intel/haswell
export EESSI_PILOT_VERSION=2021.12
EESSI_TMPDIR=/tmp/eessi
JOBID=18fa2650-5cd1-11ec-89c7-a0e0f4a35775

mkdir -p ${EESSI_TMPDIR}/software
cp -R /users/k1930241/buildscripts/software-layer ${EESSI_TMPDIR}
cp /users/k1930241/buildscripts/software-layer/EESSI-pilot-install-software-easystack.sh ${EESSI_TMPDIR}/software-layer
cp /users/k1930241/testing/11/softwarelist.yaml ${EESSI_TMPDIR}/software/easystack.yml
cd ${EESSI_TMPDIR}/software-layer

echo $PWD

./build_container.sh run ${EESSI_TMPDIR} ./run_in_compat_layer_env.sh ./EESSI-pilot-install-software-easystack.sh
if [ $? -eq 0 ]; then
    # right now the ARCH seems to be set to Haswell, which is wrong as we are on Zen2
    # So we simply set that here to zen2
    ARCH="x86_64/amd/zen2"
    TARBALL=${EESSI_TMPDIR}/eessi-${EESSI_PILOT_VERSION}-software-linux-${ARCH////-}-$(date +'%s').tar.gz
echo ${ARCH}
    ./build_container.sh run ${EESSI_TMPDIR} ./create_tarball.sh ${EESSI_TMPDIR} ${EESSI_PILOT_VERSION} ${ARCH} ${TARBALL}
    cp ${TARBALL} /users/k1930241/testing/11
fi
