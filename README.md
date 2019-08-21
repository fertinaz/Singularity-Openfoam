## Singularity
This recipe compiles and installs OpenFOAM-6 and its prerequisites from their source.
Entire build may take up to 3-4 hours.

## Singularity-2.5 installation
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

Note: I keep installation instructions for version 2.5, however you should not use 2.x versions anymore. 

## Singularity-3 installation
Singularity release 3 requires GO. Therefore one has to start with installing GO version, 
preferably from a prebuilt binary. To do so, you can use following procedure:
```
# Change desired version and path -- no need to touch the rest
export GOVRS=1.12.9
export OS=linux 
export ARCH=amd64 

wget https://dl.google.com/go/go${GOVRS}.${OS}-${ARCH}.tar.gz
sudo tar -C /usr/local -xzf go${GOVRS}.${OS}-${ARCH}.tar.gz

export GOPATH=$HOME/go
```
GO should be installed to a location in the root folder, /usr/local is a good practise.

Don't forget to update your environment with:
```
# Update environment
export GOROOT="/usr/local/go"
export GOBIN=${GOROOT}/bin
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
```
Warning: I highly recommend you to add those paths to the sudo environment as well. 

Now you can build Singularity-3:
```
mkdir -p ${GOPATH}/src/github.com/sylabs
cd ${GOPATH}/src/github.com/sylabs
git clone https://github.com/sylabs/singularity.git
cd singularity
git checkout v3.3.0

### Compile Singularity
./mconfig
cd builddir
make
sudo make install
```

## Usage of the OpenFOAM-6 recipe
One option is to run:
```bash
sudo singularity build openfoam-6.sif Singularity.openfoam6
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
This will execute the shell from the image which is located in the singularity-hub collections.

## Usage of the OpenFOAM-7 recipe
Run command: 
``` sudo singularity build openfoam-7.sif of7.def ```

This recipe install prerequisites using package manager, however compiles OpenFOAM-7 from its source.
