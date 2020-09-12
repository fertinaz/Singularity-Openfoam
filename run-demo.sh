#!/bin/bash
set -euxo pipefail

# Choose OpenFOAM version: 7 | 1912 | 2006
export OFVRS=2006

if [[ $OFVRS == "7" ]] ; then
    export OFSHA="87a06205d8f66a4d3c2391e1a8eed8358e85de63588682e398fa81eded65d417"
elif [[ $OFVRS == "1912" ]] ; then
    export OFSHA="b4bba6b2a2513317eba6678b0090ebf044a54edc223216a2f62da944fb3a6562"
elif [[ $OFVRS == "2006" ]] ; then
    export OFSHA="9d1f8880ddd64717bcbbcb88ca6542e1a74fc3d2367d12122412fb34fb85c72f"
else
  echo "Please select one of the versions provided above."
  exit 1 # There is no point to continue if the version is wrong.
fi

export IMAGE_NAME=of-${OFVRS}
export IMAGE_TAG=sha256.$OFSHA
export IMAGE_SIF=of-${OFVRS}_sha256.$OFSHA.sif

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

export REPODIR=$HOME/github.com/fertinaz/Singularity-Openfoam
export DEMODIR=$REPODIR/demo

export CASENAME=motorBike

export RUNDIR=$HOME/singularity/singularity-3.5-images

export TIMESTAMP=$(date "+%Y%m%d%H%M")

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

cd $RUNDIR

if [[ -f "$IMAGE_SIF" ]] ; then
    rm -f $IMAGE_SIF
fi

singularity pull library://fertinaz-hpc/openfoam/$IMAGE_NAME:$IMAGE_TAG

# mv of-${OFVRS}_sha256.$OFSHA.sif $IMAGE_NAME

singularity verify $IMAGE_SIF

sleep 3
singularity run $IMAGE_SIF

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# cd $RUNDIR

### Each motorBike-of-version has a compressed motorBike folder whose contents can slightly differ
cp $DEMODIR/$CASENAME-of-$OFVRS.tar.gz .
tar xf $CASENAME-of-$OFVRS.tar.gz && rm -f $CASENAME-of-$OFVRS.tar.gz
mv $CASENAME $CASENAME-$TIMESTAMP && cd $CASENAME-$TIMESTAMP

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

restore0Dir() {
    case "$1" in
    -processor | -processors)
        echo "Restore 0/ from 0.orig/ for processor directories"
        [ -d 0.orig ] || echo "    Warning: no 0.orig/ found"

        # do nonetheless
        \ls -d processor* | xargs -I {} \rm -rf ./{}/0
        \ls -d processor* | xargs -I {} \cp -r 0.orig ./{}/0 > /dev/null 2>&1

        # Remove '#include' directives from field dictionaries
        # for collated format
        if [ "$1" = "-processors" ]
        then
        (
            echo "Filter #include directives in processors/0:"
            \cd processors/0 2>/dev/null || exit 0
            for file in $(grep -l "#include" * 2>/dev/null)
            do
                foamDictionary "$file" > "$file.$$." && mv "$file.$$." "$file"
                echo "    $file"
            done | tr -d '\n'
            echo
        )
        fi
        ;;

    *)
        echo "Restore 0/ from 0.orig/"
        if [ -d 0.orig ]
        then
            \rm -rf 0
            \cp -r 0.orig 0 2>/dev/null
        else
            echo "    Warning: no 0.orig/ found"
        fi
        ;;
    esac
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# ./Allrun

singularity exec $RUNDIR/$IMAGE_SIF surfaceFeatureExtract 2>&1 | tee log.surfaceFeatureExtract
singularity exec $RUNDIR/$IMAGE_SIF blockMesh 2>&1 | tee log.blockMesh
singularity exec $RUNDIR/$IMAGE_SIF decomposePar 2>&1 | tee log.decomposePar

mpirun -np 4 singularity exec $RUNDIR/$IMAGE_SIF snappyHexMesh -overwrite -parallel
mpirun -np 4 singularity exec $RUNDIR/$IMAGE_SIF topoSet -parallel

restore0Dir -processor
# singularity exec $RUNDIR/$IMAGE_NAME restore0Dir -processor

mpirun -np 4 singularity exec $RUNDIR/$IMAGE_SIF potentialFoam -parallel
mpirun -np 4 singularity exec $RUNDIR/$IMAGE_SIF simpleFoam -parallel

singularity exec $RUNDIR/$IMAGE_SIF reconstructParMesh -constant
singularity exec $RUNDIR/$IMAGE_SIF reconstructPar -latestTime

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #