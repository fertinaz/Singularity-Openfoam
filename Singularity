Bootstrap: docker
From: centos:7

%help
    This recipe compiles and installs OpenFOAM/6 and required Third-Party tools from source.

%labels
    CREATOR: Fatih Ertinaz

%post
    yum clean all
    yum groupinstall -y 'Development Tools' 
    yum install -y zlib-devel libXext-devel libGLU-devel libXt-devel \
                   libXrender-devel libXinerama-devel wget  \
                   libpng-devel libXrandr-devel libXi-devel \
                   libXft-devel libjpeg-turbo-devel libXcursor-devel \
                   readline-devel ncurses-devel python python-devel  \
                   cmake qt-devel qt-assistant mpfr-devel gmp-devel
    yum -y upgrade

    ### Work in /opt/OpenFOAM
    cd /opt
    mkdir -p OpenFOAM 
    cd OpenFOAM

    ### Variables
    base=/opt/OpenFOAM
    pkg=OpenFOAM
    thp=ThirdParty
    vrs=6

    ### Download OpenFOAM    
    wget -O - http://dl.openfoam.org/source/6 | tar xz
    mv OpenFOAM-6-version-6 ${pkg}-${vrs}
    cd ${pkg}-${vrs}

    ### Change MPI version
    sed -i 's/export WM_MPLIB=SYSTEMOPENMPI/export WM_MPLIB=OPENMPI/g' etc/bashrc 

    ### Get rid of unset and unalias
    sed -i 's/alias wmUnset/#alias wmUnset/' etc/config.sh/aliases
    sed -i 's/unalias wmRefresh/#unalias wmRefresh/' etc/config.sh/aliases
    sed -i '77s/else/#else/' etc/config.sh/aliases

    ### Change compilers
    # sed -i "s/export WM_CC='gcc'/export WM_CC='mpicc'/" etc/config.sh/settings
    # sed -i "s/export WM_CXX='g++'/export WM_CXX='mpicxx'/" etc/config.sh/settings

    ### Change compilers in wmake as well
    # sed -i 's/cc          = gcc -m64/cc          = mpicc -m64/' wmake/rules/linux64Gcc/c
    # sed -i 's/CC          = g++ -std=c++11 -m64/CC          = mpicxx -std=c++11 -m64/' wmake/rules/linux64Gcc/c++
 
    ### Download ThirdParty
    cd ${base}
    wget -O - http://dl.openfoam.org/third-party/6 | tar xz
    mv ThirdParty-6-version-6 ${thp}-${vrs}
    cd ${thp}-${vrs}

    ### Download additional packages
    mkdir download
    wget -P download https://www.cmake.org/files/v3.9/cmake-3.9.0.tar.gz
    wget -P download https://sourceforge.net/projects/boost/files/boost/1.55.0/boost_1_55_0.tar.bz2
    wget -P download https://github.com/CGAL/cgal/releases/download/releases%2FCGAL-4.10/CGAL-4.10.tar.xz
    wget -P download https://www.open-mpi.org/software/ompi/v2.1/downloads/openmpi-2.1.1.tar.bz2
 
    ### Extract them
    tar -xzf download/cmake-3.9.0.tar.gz
    tar -xjf download/boost_1_55_0.tar.bz2
    tar -xJf download/CGAL-4.10.tar.xz
    tar -xjf download/openmpi-2.1.1.tar.bz2
 
    ### Update Boost and CGAL versions
    cd ${base}/${pkg}-${vrs}
    sed -i -e 's/\(boost_version=\)boost-system/\1boost_1_55_0/' etc/config.sh/CGAL
    sed -i -e 's/\(cgal_version=\)cgal-system/\1CGAL-4.10/' etc/config.sh/CGAL

    ### Source OpenFOAM-6
    . ${base}/${pkg}-${vrs}/etc/bashrc WM_LABEL_SIZE=32 WM_MPLIB=OPENMPI FOAMY_HEX_MESH=yes

    ### Initially install third party tools
    cd ${base}/${thp}-${vrs}
    
    ### CMake
    ./makeCmake 2>&1 | tee log.make.cmake
    . ${base}/${pkg}-${vrs}/etc/bashrc 

    ### CGAL
    # ./makeCGAL 2>&1 | tee log.makeCGAL

    ### Entire ThirdParty
    ./Allwmake 2>&1 | tee log.make.thirdparty
    . ${base}/${pkg}-${vrs}/etc/bashrc

    ### Now compile OpenFOAM
    cd ${base}/${pkg}-${vrs}
    nprocs=`cat /proc/cpuinfo | grep "processor" | wc -l`
    ./Allwmake -j ${nprocs} 2>&1 | tee log.allwmake

    ### Add sourcing to the .bashrc
    echo '. /opt/OpenFOAM/OpenFOAM-6/etc/bashrc' >> $SINGULARITY_ENVIRONMENT

%runscript
    icoFoam -help
