#!/bin/bash
set -euo pipefail

export REPODIR=$HOME/github.com/fertinaz/Singularity-Openfoam
export DEMODIR=$REPODIR/DEMODIR

export CASENAME=motorBike

export TIMESTAMP=$(date "+%Y%m%d%H%M")

cd $DEMODIR

tar xf $CASENAME.tar.gz && mv $CASENAME $CASENAME-$TIMESTAMP
cd $CASENAME-$TIMESTAMP

./Allrun