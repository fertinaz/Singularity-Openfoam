# Singularity
This recipe compiles and installs OpenFOAM/6 and its prerequisites from source.
Entire build may take up to 3-4 hours.

If Singularity is not installed in your environment, you can run following commands:
```bash
# Package details
base=$HOME/singularity
pkg=singularity-src

# Go to source code
cd $base/$pkg

# Configure
./autogen.sh
./configure --prefix=/usr/local 2>&1 | tee log.configure

# Compile and install 
make 2>&1 | tee log.make
sudo make install 2>&1 | tee log.make.install
```
Procedure above assumes Singularity source is cloned from its repository. 
Also, you may have to update root's $PATH since "/usr/local/bin" is not a part of it.
