## Singularity and OpenFOAM
This repo contains information about `Singularity` containers and focuses on `OpenFOAM` usage.

### Singularity-3.5 installation
To get going, we need to start with installing `Singularity`. However, to install `Singularity` there are some dependencies we need to install first.

Assuming that running on `Ubuntu`, we need the following prerequisites:
```
sudo apt-get update 
sudo apt-get install -y build-essential uuid-dev \
    libgpgme-dev squashfs-tools  libseccomp-dev  \
    wget  pkg-config  git  cryptsetup-bin
```

Install `GO`
```
vrs=1.14.4 # Change version as needed
os=linux
arch=amd64

out=go${vrs}.${os}-${arch}.tar.gz

curl https://dl.google.com/go/$out -o $out
sudo tar -C /usr/local -xzf $out

export PATH=/usr/local/go/bin:$PATH
```

Now we can install `Singularity` from a release source:
```
vrs=3.5.2 
archive=singularity-${vrs}.tar.gz

wget https://github.com/sylabs/singularity/releases/download/v${vrs}/$archive
tar -xzf singularity-${vrs}.tar.gz
cd singularity

./mconfig
make -C ./builddir
sudo make -C ./builddir install
```

### Singularity-3 installation
`Singularity` release 3 requires `GO`. Therefore one has to start with installing `GO` version, 
preferably from a prebuilt binary. To do so, you can use following procedure:
```
# Change desired version and path
export GOVRS=1.12.9
export OS=linux 
export ARCH=amd64 

wget https://dl.google.com/go/go${GOVRS}.${OS}-${ARCH}.tar.gz
sudo tar -C /usr/local -xzf go${GOVRS}.${OS}-${ARCH}.tar.gz

export GOPATH=$HOME/go
```
`GO` should be installed to a location in the root folder, `/usr/local` is a good practise.

Don't forget to update your environment with:
```
# Update environment
export GOROOT=/usr/local/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
```
Warning: I highly recommend you to add those paths to the `sudo` environment as well. 

Now you can build `Singularity-3`:
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


### Singularity-2.5 installation
This is no longer supported. It is highly recommended to follow the `Singularity-3.x` versions and ignore this section. I keep these notes for archiving purposes and will remove them at some point.

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

## OpenFOAM usage
Since we have `Singularity` ready in our environment, we can now start with the `OpenFOAM` images.

### OpenFOAM recipes: OF-7
You can build this image by running the following command:
```
sudo singularity build of-7.sif of-7.def 
```
Since build takes considerable amount of time, I pushed this image to the singularity hub which can be pulled by:
```
singularity pull --arch amd64 library://fertinaz-hpc/openfoam/of-7.sif:latest
```

The prerequisites installed using package manager, then `OpenFOAM-7` is compiled from its source. Recipe uses `gcc-4.8` and `openmpi-3.1.3` during the compilation. You can access `mpi` related directories such as `bin` and `lib` using environment variables `MPI_BIN` and `MPI_LIB`. Note that the `MPI` version you have on your `HOST` machine should match the version inside the container. 

To install `openmpi-3.1.3` on the host machine, you can use the following snippet:
```
mkdir -p /opt/openmpi-3.1.3
wget https://download.open-mpi.org/release/open-mpi/v3.1/openmpi-3.1.3.tar.gz
tar xf openmpi-3.1.3.tar.gz
rm -f openmpi-3.1.3.tar.gz
cd openmpi-3.1.3
./configure --prefix=/opt/openmpi-3.1.3
sudo make all install

# Update env
export MPI_DIR=/opt/openmpi-3.1.3
export MPI_BIN=$MPI_DIR/bin
export MPI_LIB=$MPI_DIR/lib
export MPI_INC=$MPI_DIR/include
export PATH=$MPI_BIN:$PATH
export LD_LIBRARY_PATH=$MPI_LIB:$LD_LIBRARY_PATH
```

After we make sure that correct `OpenMPI` version is installed on the host machine, we can run the container. First let's try if it works:
```
$ singularity run of-7.sif 

OpenFOAM installation is available under /opt/OpenFOAM/OpenFOAM-7
```
which states that `OpenFOAM` installation resides under the `/opt/OpenFOAM/OpenFOAM-7` directory as expected. `etc/bashrc` is sourced when container runtime is initiated, therefore you can directly access `OpenFOAM` functionality.

Following example shows running a sample `OpenFOAM` command:
```
$ singularity exec of-7.sif simpleFoam -help

Usage: simpleFoam [OPTIONS]
options:
  -case <dir>       specify alternate case directory, default is the cwd
  -fileHandler <handler>
                    override the fileHandler
  -hostRoots <(((host1 dir1) .. (hostN dirN))>
                    slave root directories (per host) for distributed running
  -libs <(lib1 .. libN)>
                    pre-load libraries
  -listFunctionObjects
                    List functionObjects
  -listFvOptions    List fvOptions
  -listRegisteredSwitches
                    List switches registered for run-time modification
  -listScalarBCs    List scalar field boundary conditions (fvPatchField<scalar>)
  -listSwitches     List switches declared in libraries but not set in
                    etc/controlDict
  -listTurbulenceModels
                    List turbulenceModels
  -listUnsetSwitches
                    List switches declared in libraries but not set in
                    etc/controlDict
  -listVectorBCs    List vector field boundary conditions (fvPatchField<vector>)
  -noFunctionObjects
                    do not execute functionObjects
  -parallel         run in parallel
  -postProcess      Execute functionObjects only
  -roots <(dir1 .. dirN)>
                    slave root directories for distributed running
  -srcDoc           display source code in browser
  -doc              display application documentation in browser
  -help             print the usage

Using: OpenFOAM-7 (see https://openfoam.org)
Build: 7
```

Let's run a test case using for instance `blockMesh`:
```
~/recipes/motorBike$ ll
total 32
drwxrwxr-x 6 vagrant vagrant 4096 Jun 12 03:13 ./
drwxrwxr-x 3 vagrant vagrant 4096 Jun 12 03:13 ../
drwxrwxr-x 3 vagrant vagrant 4096 Jun 12 03:13 0/
-rwxrwxr-x 1 vagrant vagrant  437 Jun 12 03:13 Allclean*
-rwxrwxr-x 1 vagrant vagrant  644 Jun 12 03:13 Allrun*
drwxrwxr-x 3 vagrant vagrant 4096 Jun 12 03:13 constant/
drwxrwxr-x 4 vagrant vagrant 4096 Jun 12 03:13 .svn/
drwxrwxr-x 2 vagrant vagrant 4096 Jun 12 03:13 system/
```
As it is seen above, I prepared the tutorial case `motorBike` on my local machine and even this is done one a `Vagrant` session. Now I execute `blockMesh` using the container:
```
~/recipes/motorBike$ singularity exec ~/recipes/of-7.sif blockMesh
```
You can see its output
```
/*---------------------------------------------------------------------------*\
  =========                 |
  \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox
   \\    /   O peration     | Website:  https://openfoam.org
    \\  /    A nd           | Version:  7
     \\/     M anipulation  |
\*---------------------------------------------------------------------------*/
Build  : 7
Exec   : blockMesh
Date   : Jun 12 2020
Time   : 03:14:19
Host   : "vagrant"
PID    : 21791
I/O    : uncollated
Case   : /home/vagrant/recipes/motorBike
nProcs : 1
sigFpe : Enabling floating point exception trapping (FOAM_SIGFPE).
fileModificationChecking : Monitoring run-time modified files using timeStampMaster (fileModificationSkew 10)
allowSystemOperations : Allowing user-supplied system call operations

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //
Create time

Creating block mesh from
    "/home/vagrant/recipes/motorBike/system/blockMeshDict"
Creating block edges
No non-planar block faces defined
Creating topology blocks
Creating topology patches

Creating block mesh topology

Check topology

	Basic statistics
		Number of internal faces : 0
		Number of boundary faces : 6
		Number of defined boundary faces : 6
		Number of undefined boundary faces : 0
	Checking patch -> block consistency

Creating block offsets
Creating merge list .

Creating polyMesh from blockMesh
Creating patches
Creating cells
Creating points with scale 1
    Block 0 cell size :
        i : 1
        j : 1
        k : 1

There are no merge patch pairs edges

Writing polyMesh
----------------
Mesh Information
----------------
  boundingBox: (-5 -4 0) (15 4 8)
  nPoints: 1701
  nCells: 1280
  nFaces: 4224
  nInternalFaces: 3456
----------------
Patches
----------------
  patch 0 (start: 3456 size: 320) name: frontAndBack
  patch 1 (start: 3776 size: 64) name: inlet
  patch 2 (start: 3840 size: 64) name: outlet
  patch 3 (start: 3904 size: 160) name: lowerWall
  patch 4 (start: 4064 size: 160) name: upperWall

End
```

Let's finally try a parallel execution using:
```
mpirun -np 4 singularity exec ~/recipes/of-7.sif simpleFoam -parallel
```

### OpenFOAM recipes: OF-6
Please ignore this section as well. These are written for `Singularity-2.5` which is not supported anymore. You can follow the guidelines written for `OpenFOAM-7` above. I keep these notes for archiving purposes and will remove them at some point.

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