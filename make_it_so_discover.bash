#!/usr/bin/env bash
module purge
export SEL=${1}
if [[ ${SEL} == 'gcc' ]]; then
    export MOD_SET='gcc-12.3.0'
fi
if [[ ${SEL} == 'intel' ]]; then
    export MOD_SET='intel-2021.10.0'
fi


module load anaconda
if [[ ${SEL} == 'gcc' ]]; then
  module use /discover/swdev/gmao_SIteam/modulefiles-SLES15
fi
module use /gpfsm/dswdev/jcsda/spack-stack/scu17/spack-stack-1.9.0/envs/ue-${MOD_SET}/install/modulefiles/Core

if [[ ${SEL} == 'gcc' ]]; then
  module load stack-gcc/12.3.0
  module load stack-openmpi
fi

if [[ ${SEL} == 'intel' ]]; then
  module load stack-intel
  module load stack-intel-oneapi-mpi
fi

module load git
module load git-lfs
module load netcdf-c
module load netcdf-cxx4
module load netcdf-fortran
export CONDA_VENV="pycrtm_${MOD_SET}_modern"
conda create --name ${CONDA_VENV} python=3.11 cmake 
conda activate ${CONDA_VENV}

export PWDOLD=${PWD}
export CHECKOUT_PATH="${PWD}/.local"
export PYCRTM_PATH="${PWD}"



#load modules here so have netcdf env variables in conda
if [[ ${SEL} == 'gcc' ]]; then
  module load stack-gcc/12.3.0
fi
module load netcdf-c
module load netcdf-cxx4
module load netcdf-fortran
# Activate the environment
# adjust this to your own tastes


export FPIC="-fPIC"
# make sure -fPIC is set before CRTM is built, add to FFLAGS
if [[ -z "$FFLAGS" ]]; then
  export FFLAGS="${FPIC}"
  echo "Environment variable FFLAGS not found. Setting it to '${FPIC}'."
elif [[ ! "$!FFLAGS" =~ (^|[[:space:]])"${FPIC}"($|[[:space:]]) ]]; then
  export FFLAGS="${FFLAGS} ${FPIC}"
  echo "Flag '${FPIC}' not found in FFLAGS. Appending it."
else
  echo "Flag '${FPIC}' is already set in FFLAGS."
fi

#make sure -fPIC is set before CRTM is build, add to FORTRANFLAGS
if [[ -z "$FORTRANFLAGS" ]]; then
  export FORTRANFLAGS="${FPIC}"
  echo "Environment variable FORTRANFLAGS not found. Setting it to '${FPIC}'."
elif [[ ! "$!FORTRANFLAGS" =~ (^|[[:space:]])"${FPIC}"($|[[:space:]]) ]]; then
  export FORTRANFLAGS="${FORTRANFLAGS} ${FPIC}"
  echo "Flag '${FPIC}' not found in FORTRANFLAGS. Appending it."
else
  echo "Flag '${FPIC}' is already set in FORTRANFLAGS."
fi


# checkout and buildtest CRTM
mkdir $CHECKOUT_PATH
echo ${CHECKOUT_PATH}
cd ${CHECKOUT_PATH}
echo $PWD
git clone git@github.com:JCSDA/CRTMv3.git
cd CRTMv3
git checkout v3.1.1+build1
conda list
mkdir build 
cd build
cmake -DBUILD_SHARED_LIBS=OFF ../
make -j8 
make install 
ctest -j8 
cd $CHECKOUT_PATH

cd ${PYCRTM_PATH}
#git clone git@github.com:JCSDA/pycrtm.git
#git checkout feature/prepCRTMv3
rm setup.cfg
printf "[Setup]\n">>setup.cfg
printf "# Specify the location of the crtm install\n">>setup.cfg 
printf "crtm_install =${CHECKOUT_PATH}/CRTMv3/build/\n" >> setup.cfg
printf "link_from_source_to_path_used = True\n" >> setup.cfg
printf "[Coefficients]\n" >> setup.cfg
printf "# source specify coefficient directory will grab little endian binary coefficients and netcdf and link them to path_used\n">>setup.cfg
printf "source_path =${CHECKOUT_PATH}/CRTMv3/build/test_data/\n" >> setup.cfg 
printf "# path used by pycrtm to read coefficients\n" >> setup.cfg 
printf "path_used =${CHECKOUT_PATH}/crtm_coefficients\n" >> setup.cfg 

#export FORCE_CMAKE=1
#pip install --upgrade cmake
mkdir $PWD/tmp 
export TMPDIR=$PWD/tmp
python -m pip install matplotlib netcdf4 h5py
python -m pip install . -v --no-cache-dir
conda env config vars set LD_LIBRARY_PATH=${LD_LIBRARY_PATH}
cd testCases
for bar in *py; do foo=$(realpath $bar); echo "STARTING python3 $foo"; python3 $foo 2>&1 ; echo "$foo COMPLETE"; done

cd $PWDOLD 
