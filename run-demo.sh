#!/bin/bash
set -euo pipefail

# Choose OpenFOAM version: 7 | 1912
export OFVRS=7

if [[ $OFVRS == "7" ]] ; then
    export OFSHA="87a06205d8f66a4d3c2391e1a8eed8358e85de63588682e398fa81eded65d417"
elif [[ $OFVRS == "1912" ]] ; then
    export OFSHA="b4bba6b2a2513317eba6678b0090ebf044a54edc223216a2f62da944fb3a6562"
else
  echo "Please select one of the versions provided above."
  exit 1 # There is no point to continue if the version is wrong.
fi

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

export REPODIR=$HOME/github.com/fertinaz/Singularity-Openfoam
export DEMODIR=$REPODIR/demo

export CASENAME=motorBike

export TIMESTAMP=$(date "+%Y%m%d%H%M")

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

cd $DEMODIR

tar xf $CASENAME.tar.gz && mv $CASENAME $CASENAME-$TIMESTAMP
cd $CASENAME-$TIMESTAMP

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

singularity pull library://fertinaz-hpc/openfoam/of-$OFVRS.sif:sha256.$OFSHA

export IMAGE_NAME=of-$OFVRS.sif

mv of-$OFVRS.sif_sha256.$OFSHA.sif $IMAGE_NAME

singularity verify $IMAGE_NAME

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# ./Allrun

singularity exec $IMAGE_NAME surfaceFeatures 2>&1 | tee log.surfaceFeatures
singularity exec $IMAGE_NAME blockMesh 2>&1 | tee log.blockMesh
singularity exec $IMAGE_NAME decomposePar -copyZero 2>&1 | tee log.decomposePar

mpirun -np 4 singularity exec $IMAGE_NAME snappyHexMesh -overwrite parallel
mpirun -np 4 singularity exec $IMAGE_NAME potentialFoam -parallel
mpirun -np 4 singularity exec $IMAGE_NAME simpleFoam -parallel

singularity exec $IMAGE_NAME reconstructParMesh -constant
singularity exec $IMAGE_NAME reconstructPar -latestTime

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #