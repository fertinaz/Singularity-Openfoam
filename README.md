## Singularity
This recipe compiles and installs OpenFOAM-6 and its prerequisites from their source.
Entire build may take up to 3-4 hours.

## Singularity installation
If Singularity is not installed in your environment, you can use following commands as a template:
```bash
# Package details -- change according to your environment
base=$HOME/Singularity
pkg=singularity
vrs=X.Y.Z

# Go to source code
cd $base/$pkg-$vrs

# Configure
./autogen.sh
./configure --prefix=/usr/local 2>&1 | tee log.configure

# Compile and install 
make 2>&1 | tee log.make
sudo make install 2>&1 | tee log.make.install
```
Procedure above assumes Singularity source is cloned from its git repository. If you downloaded a source release, rather than cloning the git repo, you probably don't need to run "autogen.sh".

Also, when the installation is completed successfully, you may have to update root $PATH since "/usr/local/bin" may not be a part of it.

## Usage of the OpenFOAM recipe
One option is to run:
```bash
sudo singularity build openfoam-6 Singularity.recipe
```
This command will initially install development libraries for CentOS-7.5. 
It will then compile:
* CMake-3.9
* Boost_1_55
* CGAL-4.10
* OpenMPI-2.1.1
* OpenFOAM-6

Note that this is a very time consuming process and can take up to a few hours depending on the host hardware.

One can also directly invoke shell in the container which will be much faster:
```bash
singularity run shub://fertinaz/Singularity-Openfoam
```
