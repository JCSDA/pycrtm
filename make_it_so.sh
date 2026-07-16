#!/bin/sh
export SEL=$1
set --
if [[ ${SEL} == 'apple_silicon' ]]; then
    mkdir -p ~/miniconda3
    curl https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh -o ~/miniconda3/miniconda.sh
    zsh ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3 
    rm ~/miniconda3/miniconda.sh
    source ~/miniconda3/bin/activate
    conda init --all
elif [[ ${SEL} == 'apple_intel' ]]; then
    mkdir -p ~/miniconda3
    curl https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh -o ~/miniconda3/miniconda.sh
    bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
    rm ~/miniconda3/miniconda.sh
    source ~/miniconda3/bin/activate
    conda init --all
elif [[ ${SEL} == 'linux' ]]; then
    mkdir -p ~/miniconda3
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
    bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
    rm ~/miniconda3/miniconda.sh
    source ~/miniconda3/bin/activate
    conda init --all
elif [[ ${SEL} == 'skip_install' || ${SEL} == 'skip_create' || ${SEL} == 'skip_crtm_download' ]]; then

    echo "Skipping miniconda install. Already installed."    
    if [[ -f "$HOME/miniconda3/bin/activate" ]]; then
        source $HOME/miniconda3/bin/activate
    fi

else
    echo "Unknown option selected:${1}"
	exit 1
fi


export CONDA_VENV='pycrtm'

if [ ${SEL} == 'skip_create' ] || [ ${SEL} == 'skip_crtm_download' ]; then
  echo "using current conda environment: ${CONDA_VENV}"
  echo "Skipping conda create."
  conda activate ${CONDA_VENV}
else 
  # Add conda-forge, necessary to get netcdf-fortran
  conda config --add channels conda-forge

  conda create --name ${CONDA_VENV} python scikit-build h5py netcdf4 gfortran libnetcdf netcdf-fortran meson cmake matplotlib wget
  conda activate ${CONDA_VENV}
  conda init
  echo $CONDA_PREFIX
fi


export PWDOLD=${PWD}
export CHECKOUT_PATH="${PWD}/ext"
export PYCRTM_PATH="${PWD}"
export CRTM_VERSION="3.x"

# checkout and build/test CRTM
mkdir ${CHECKOUT_PATH}
echo ${CHECKOUT_PATH}
cd ${CHECKOUT_PATH}
echo ${PWD}

if [ ${CRTM_VERSION} == "2.x" ] && [ ${SEL} != 'skip_crtm_download' ]; then
  wget https://github.com/ecmwf/ecbuild/archive/refs/tags/3.10.0.tar.gz
  tar -xvf 3.10.0.tar.gz
  export PATH=${PWD}/ecbuild-3.10.0/bin:$PATH

  wget https://github.com/JCSDA/crtm/archive/refs/tags/v2.4.1-jedi.1.tar.gz
  tar -xvf v2.4.1-jedi.1.tar.gz
  if [ -d "${CHECKOUT_PATH}/crtm" ]; then
    rm -r crtm
  fi
  mv crtm-2.4.1-jedi.1 crtm   
  cd crtm
elif [[ ${CRTM_VERSION} == "2.x" ]]; then
  echo "Skipping CRTM download."
  export PATH=${PWD}/ecbuild-3.10.0/bin:$PATH
  cd crtm
fi

if [ ${CRTM_VERSION} == "3.x" ] && [ ${SEL} != 'skip_crtm_download' ]; then
  wget https://github.com/JCSDA/CRTMv3/archive/refs/tags/v3.1.1+build1.tar.gz
  tar -xvf v3.1.1+build1.tar.gz
  if [ -d "${CHECKOUT_PATH}/CRTMv3" ]; then
    rm -r CRTMv3
  fi
  mv CRTMv3-3.1.1-build1 CRTMv3
  cd CRTMv3
elif [[ ${CRTM_VERSION} == "3.x" ]]; then
  echo "Skipping CRTM download."
  cd CRTMv3
fi

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
if [ ${CRTM_VERSION} == "2.x" ] && [ ${SEL} != 'skip_crtm_download' ]; then
  chmod +x Get_CRTM_Binary_Files.sh
  ./Get_CRTM_Binary_Files.sh
fi

mkdir build 
cd build

if [[ ${CRTM_VERSION} == "2.x" ]]; then
  if [[ -d "${CHECKOUT_PATH}/crtm/fix_REL-2.4.1_20221109/" ]]; then
    cd ..
    rm -rf build
    mkdir build
    cd build
  fi
  ecbuild ../
  make -j8 
  ctest -j8
  cd lib
  rm libcrtm.*
  mv libcrtm_static.a libcrtm.a
fi
 

if [[ ${CRTM_VERSION} == "3.x" ]]; then
  if [[ -d "${CHECKOUT_PATH}/CRTMv3/build/test_data/3.1.1/fix_REL-3.1.1.2/" ]]; then
    mv ${CHECKOUT_PATH}/CRTMv3/build/test_data/ ../
    cd ..
    rm -rf build
    mkdir build
    mv test_data build
    cd build
  fi
  cmake -DBUILD_SHARED_LIBS=OFF ../
  make -j8 
  make install 
  ctest -j8
fi
 

cd ${PYCRTM_PATH}

rm setup.cfg
printf "[Setup]\n">>setup.cfg
printf "# Specify the location of the crtm install\n">>setup.cfg 

if [[ ${CRTM_VERSION} == "2.x" ]]; then
  printf "crtm_install =${CHECKOUT_PATH}/crtm/build/\n" >> setup.cfg
fi
if [[ ${CRTM_VERSION} == "3.x" ]]; then
  printf "crtm_install =${CHECKOUT_PATH}/CRTMv3/build/\n" >> setup.cfg
fi

printf "link_from_source_to_path_used = True\n" >> setup.cfg
printf "[Coefficients]\n" >> setup.cfg
printf "# source specify coefficient directory will grab little endian binary coefficients and netcdf and link them to path_used\n">>setup.cfg

if [[ ${CRTM_VERSION} == "2.x" ]]; then
  printf "source_path =${CHECKOUT_PATH}/crtm/build/test_data/\n" >> setup.cfg 
fi

if [[ ${CRTM_VERSION} == "3.x" ]]; then
  printf "source_path =${CHECKOUT_PATH}/CRTMv3/build/test_data/\n" >> setup.cfg 
fi

printf "# path used by pycrtm to read coefficients\n" >> setup.cfg 
printf "path_used =${CHECKOUT_PATH}/crtm_coefficients\n" >> setup.cfg 

export NetCDF_ROOT=${CONDA_PREFIX}/

pip install . 

cd testCases
if [[ $SEL == 'apple_intel' ]]; then
    export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH}:${CHECKOUT_PATH}/CRTMv3/build/lib/" 
elif [[ ${SEL:0:4} == 'skip' ]]; then
    export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH}:${CHECKOUT_PATH}/CRTMv3/build/lib/" 
fi
python3 test_atms.py 
cd $PWDOLD 
