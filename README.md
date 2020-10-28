# pyCRTM - python interface to CRTM.

## Bryan M. Karpowicz, Ph.D. - USRA/GESTAR/NASA 610.1 Global Modeling and Assimilation Office, with Contributions from Patrick Stegmann, Dr.-Ing. - JCSDA
## Additional configuration infomation for the crtm-bundle (github.com/JCSDA/crtm-bundle) provided by Benjamin Johnson, Ph.D. 

This is a basic python interface to CRTM v2.4.0. 

The user interface is designed to be very similar to the python RTTOV interface. So, the user sets profiles, passes them to an object for a desired sensor, runs either the forward model/K-matrix, and pulls the brightness temperature/Jacobian/transmission/emissivity out of the object.  


This `README` has 4 parts:

1. Installation -- installing this library
2. Test/Examples -- describing test in testCases subdirectory
3. Python path etc -- how to use this library in a project.
4. Using the interface -- HOWTO/run through on how to use this interface

- Bryan Karpowicz -- October 23, 2020
---------------------------------------------------------------------------------------- 

## 1. Installation:
 
Done via the `setup_pycrtm.py` script  

Usage:
```
usage: setup_pycrtm.py [-h] --install INSTALL --repos RTPATH --coef COEF
                       --ncpath NCPATH --h5path H5PATH --jproc JPROC
                       [--arch ARCH] [--inplace]
the following arguments are required: --install, --repos, --coef, --ncpath, --h5path, --jproc
```

### Required:
* `--install` -  Install path to crtm library or where the user would like the crtm install directory (e.g., /home/user/ if you want crtm_v2.4.0 to install in /home/user/crtm_v2.4.0)
* `--repos`   -  Path to CRTM git checkout (e.g. crtm_v2.4.0) 
* `--coef`    -  Path where the crtm coefficients are stored under subdirectory crtm_coef_pycrtm
* `--ncpath`   -  Path to netcdf library (root path e.g. /usr/local/Cellar/netcdf/4.7.4_1, where lib and include are subdirectories underneath) 
* `--h5path`   -  Path to hdf5 library (root path e.g. /usr/local/Cellar/hdf5/1.12.0_1, where lib and include are subdirectories underneath) 
* `--jproc`   -  The number of threads to pass compiler

### Optional:
* `--arch` select compiler/environment gfortran (gcc), ifort (intel) have been tested along with openmp enabled equiavalents (gfortran-openmp, ifort-openmp). Default gfortran-openmp
* `--inplace` this will skip the building of CRTM, but instead just compile pycrtm interface and link to the install path (e.g.,--install /home/user/, if you have previously installed to /home/user/crtm_v2.4.0)`.

Assuming the following structure in `crtm-bundle`:
```
crtm-bundle/crtm
crtm-bundle/pycrtm
crtm-bundle/crtm_v2.4.0/ 
```


Example to install CRTM in this directory under a subdirectory under the CRTM git checkout, and place the coefficients in this diectory`
```
./setup_pycrtm.py  --install $PWD/../ --repos $PWD/../crtm/ --jproc 1 --coef $PWD --ncpath /usr/local/ --h5path /usr/local/ --arch gfortran --inplace

./setup_pycrtm.py  --install $PWD/../crtm_v2.4.0/ --repos $PWD/../crtm_v2.4.0 --jproc 1 --coef $PWD --ncpath /usr/local/Cellar/netcdf/4.7.4_1 --h5path /usr/local/Cellar/hdf5/1.12.0_1 --arch gfortran-openmp
```


Once completed:

* `$PWD/pycrtm.cpython-37m-PLATFORM.so` <-- (will always reside here) f2py interface compiled by setup 
* `$PWD/crtm.cfg`                       <-- Path where the CRTM coefficients are stored 
* `$PWD/pycrtm.stde`                    <-- standard error captured from compilation
* `$PWD/pycrtm.stdo`                    <-- standard output captured from compilation 
* `$PWD/sgnFile.pyf`                    <-- automatically generated f2py interface file

Following the example the CRTM will be installed here:

* `$PWD/../crtm_v2.4.0/config.log`                        <-- usual config associated with CRTM
* `$PWD/../crtm_v2.4.0/crtm_v2.4.0/include`               <-- path to all compiled fortran modules
* `$PWD/../crtm_v2.4.0/crtm_v2.4.0/lib/libcrtm.a`         <-- usual crtm static library
* `$PWD/crtm_coef_pycrtm`                               <-- path to crtm_coefficients

To make things a bit simpler some installer scripts and scripts to load modules on the NASA NCCS discover cluster have been included:
* `discover_install_gfortran_openmp.sh`     <-- will install using gfortran and OpenMP if you checkout the CRTM repository at ../crtm_v2.4.0 
* `discover_install_ifort_openmp.sh`        <-- will install using ifort and OpenMP if you checkout the CRTM repository at ../crtm_v2.4.0
* `discover_modules_gfortran_openmp.sh`	    <-- load the necessary modules whenever you want to run pycrtm using gfortran/OpenMP on discover
* `discover_modules_ifort_openmp.sh`        <-- load the necessary modules whenever you want to run pycrtm using ifort/OpenMP on discover

Note you will have to add the following to your .basrc (if you use bash):
```bash
export OPT='/discover/swdev/jcsda/modules'
module use $OPT/modulefiles
```
If you use cshell you will need to add the following lines to your .cshrc:
```csh
setenv OPT /discover/swdev/jcsda/modules
module use $OPT/modulefiles
```
For those on a Mac and use homebrew some installer scripts have been included:
* `homebrew_install.sh`                     <-- will install on standard homebrew install using gfortran/OpenMP if you checkout the CRTM repository at ../crtm_v2.4.0
* `homebrew_install_userdir.sh`             <-- will install on homebrew install configured to run in the user's directory using gfortran/OpenMP if you checkout the CRTM repository at ../crtm_v2.4.0

---------------------------------------------------------------------------------------- 

## 2. Tests/Examples:

A few test cases have been developed using input/output grabbed from the CRTM test program.
Two basic scripts which will perform cases 1-4 (stored in $PWD/testCases/data/case[n].h5) from the CRTM test program on 4 OpenMP threads: 
* `$PWD/testCases/test_atms.py`
* `$PWD/testCases/test_cris.py`
These *should* just say Yay, and not produce any plots if successful. 

The following scripts will run CRTM without aerosols or clouds:
* `$PWD/testCases/test_atms_no_clouds.py`
* `$PWD/testCases/test_cris_no_clouds.py`

For those Jupyter notebook fans, there is even Jupyter notebook example simulating ATMS:
* `$PWD/testCases/test_atms.ipynb`

## 3. Python path etc - needs work, but works for me at the moment: 

Right now things aren't setup to install into a user's Python path. What I typically plan on doing is set this as a git submodule, and bring it into a project and import the module using something like:
```Python
from pycrtm.pyCRTM import profilesCreate, pyCRTM
```
Or, do something like is done in the testCases scripts and insert the path, then import.
```Python
pycrtmDir = [this directory]
sys.path.insert(0,pycrtmDir)
from pyCRTM import pyCRTM, profilesCreate
```
---------------------------------------------------------------------------------------- 

## 4. Using the interface (designed to be pretty much like the RTTOV equivalent python library):

Create a profiles data structure using `profilesCreate(nprofiles, nlayers)` which will generate an object with user specified number of profiles, and number of layers in the profiles provided.
```Python
profiles = profilesCreate(4, 92) # will generate an empty object with 4 profiles each with 92 layers. 
```
Once initialized, the user will need to provide values for the desired profiles (see example scripts). Next, the user initializes a crtm instance, set desired parameters, and passes profiles to the CRTM:

```Python
crtmOb = pyCRTM()
crtmOb.coefficientPath = pathInfo['CRTM']['coeffs_dir']
crtmOb.sensor_id = sensor_id
crtmOb.nThreads = 1
crtmOb.profiles = profiles
```

Next, the instrument is loaded/number of channels in the output structure are initialized:

```Python
crtmOb.loadInst()
```

Next, the user can run either the forward model (runDirect), or the K-matrix (runK) 
```Python
crtmOb.runDirect()
crtmOb.runK()
```
Finally, the user can pull out desired parameters such as brightness temperatures, Jacobians, or Transmission along path (TauLevels - the derivative will be the weighting function):
```Python
# brightness temperature (nprofiles, nchan):
brightnessTemperature = crtmOb.Bt 

#Transmission (to compute weighting functions) ( nprofiles, nchan, nlayers)
Tau = crtmOb.TauLevels 

#Temperature, Water Vapo[u]r, and Ozone Jacobians ( npforfiles, nchan, nlayers)
O3_Jacobian = crtmOb.O3K
Water_Vapor_Jacobian = crtmOb.QK
Temperature_Jacobian = crtm.TK

#Emissivity (nprofiles, nchan)
Emissivity = crtmOb.surfEmisRefl
```
---------------------------------------------------------------------------------------- 

