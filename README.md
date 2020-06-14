## Singularity and OpenFOAM
This repo contains information about `Singularity` containers and focuses on `OpenFOAM` usage.

### Singularity-3.5 installation
To get going, we need to start with installing `Singularity`. However, to install `Singularity` there are some dependencies we need to install first.

Assuming that running on `CentOS`, we need the following prerequisites [*]:
```
$ sudo yum update -y
$ sudo yum groupinstall -y 'Development Tools' 
$ sudo yum install -y openssl-devel libuuid-devel \
    libseccomp-devel wget squashfs-tools cryptsetup
```
[*]: Singularity Container Documentation, p. 12
https://sylabs.io/guides/3.5/admin-guide.pdf

Now we should install `GO`
```
vrs=1.14.4 # Change version as needed
os=linux
arch=amd64

out=go${vrs}.${os}-${arch}.tar.gz

curl https://dl.google.com/go/$out -o $out
sudo tar -C /usr/local -xzf $out

export PATH=/usr/local/go/bin:$PATH
```
If everything goes fine, you should be able to see a similar output to the following:
```
$ which go && go version
/usr/local/go/bin/go
go version go1.14.4 linux/amd64
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

To check the `singularity` command we can run `help`. Output should similar to this:
```
$ singularity help

Linux container platform optimized for High Performance Computing (HPC) and
Enterprise Performance Computing (EPC)

Usage:
  singularity [global options...]

Description:
  Singularity containers provide an application virtualization layer enabling
  mobility of compute via both application and environment portability. With
  Singularity one is capable of building a root file system that runs on any 
  other Linux system where Singularity is installed.
```

Now we are done with the `Singularity` installation and can proceed to `OpenFOAM` containerization.

### OpenFOAM usage
Since we have `Singularity` ready in our environment, we can now start with the `OpenFOAM` images.

#### OpenFOAM recipes: OF-7
This section explains how to use our `of-7` image file starting from scratch.

##### Build image
You can build `of-7` image by running the following command:
```
$ sudo singularity build of-7.sif of-7.def 
```

##### Pull image
Build takes considerable amount of time, therefore I pushed this image to the singularity hub which can be pulled by:
```
$ singularity pull library://fertinaz-hpc/openfoam/of-7.sif:sha256.87a06205d8f66a4d3c2391e1a8eed8358e85de63588682e398fa81eded65d417
```
Normally you shouldn't need the hash, but I've experienced some issues and could not pull it successfully. Specifying the hash resolves that problem, also makes it sure that we pull the right image. 

You can the rename the image by:
```
$ mv of-7.sif_sha256.87a06205d8f66a4d3c2391e1a8eed8358e85de63588682e398fa81eded65d417.sif of-7.sif
```
Verify the image:
```
$ singularity verify of-7.sif
Container is signed by 1 key(s):

Verifying signature F: 0E10907267D8661988B4CB8266054C750D4C26CF:
[REMOTE]  Fatih Ertinaz <fertinaz@gmail.com>
[OK]      Data integrity verified

INFO:    Container verified: of-7.sif

```

##### MPI on host
Due to a hanging problem in the `openmpi` (see https://github.com/hpcng/singularity/issues/2590), I've manually installed `openmpi-4.0.4` inside the container. Since it is highly suggested to use the same `mpi` version on the host, we need to apply the same installation. You can use the following snippet:
```
vrs=4.0.4
wget https://download.open-mpi.org/release/open-mpi/v4.0/openmpi-${vrs}.tar.gz
tar xf openmpi-${vrs}.tar.gz && rm -f openmpi-${vrs}.tar.gz
cd openmpi-${vrs}
./configure --prefix=/opt/openmpi-${vrs}  # Change this path as you wish
sudo make all install

export MPI_DIR=/opt/openmpi-${vrs}
export MPI_BIN=$MPI_DIR/bin
export MPI_LIB=$MPI_DIR/lib
export MPI_INC=$MPI_DIR/include

export PATH=$MPI_BIN:$PATH
export LD_LIBRARY_PATH=$MPI_LIB:$LD_LIBRARY_PATH
```

##### Run image
After we make sure that correct `OpenMPI` version is installed on the host machine, we can run the container. First let's try if it works:
```
$ singularity run of-7.sif 

OpenFOAM installation is available under /opt/OpenFOAM/OpenFOAM-7
```
which states that `OpenFOAM` installation resides under the `/opt/OpenFOAM/OpenFOAM-7` directory as expected. `etc/bashrc` is sourced when container runtime is initiated, therefore you can directly access `OpenFOAM` functionality.

##### Execute using the container
Following example shows how to execute a sample `OpenFOAM` command using the container image:
```
$ singularity exec of-7.sif simpleFoam -help

Usage: simpleFoam [OPTIONS]

Using: OpenFOAM-7 (see https://openfoam.org)
Build: 7
```

Let's run a test case using for instance `blockMesh`:
```
~/demo/motorBike$ ll
total 32
drwxrwxr-x 6 vagrant vagrant 4096 Jun 12 03:13 ./
drwxrwxr-x 3 vagrant vagrant 4096 Jun 12 03:13 ../
drwxrwxr-x 3 vagrant vagrant 4096 Jun 12 03:13 0/
-rwxrwxr-x 1 vagrant vagrant  437 Jun 12 03:13 Allclean*
-rwxrwxr-x 1 vagrant vagrant  644 Jun 12 03:13 Allrun*
drwxrwxr-x 3 vagrant vagrant 4096 Jun 12 03:13 constant/
drwxrwxr-x 2 vagrant vagrant 4096 Jun 12 03:13 system/
```
As it is seen above, I prepared the tutorial case `motorBike` on my local machine and even this is done one a `Vagrant` session. Now I execute `blockMesh` using the container:
```
~/demo/motorBike$ singularity exec ~/recipes/of-7.sif blockMesh
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
So we've successfully executed an `OpenFOAM` command using our container.

##### Parallel execution using the container
Let's finally try a parallel execution using:
```
~/demo/motorBike$ mpirun -np 4 singularity exec ~/recipes/of-7.sif simpleFoam -parallel
```

Parallel `simpleFoam` is successfully executed with this command.