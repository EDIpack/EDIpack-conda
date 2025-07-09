#!/bin/bash
set -eux

# Set compilers
export FC=$(which mpif90)
export CC=$(which mpicc)
export CXX=$(which mpicxx)

SYSROOT_DIR="${CONDA_BUILD_SYSROOT:-$(${CC:-gcc} -print-sysroot)}"
echo "Sysroot dir: ${SYSROOT_DIR}"

#Create pkg-config directory, if it doesn't exist
mkdir -p ${PREFIX}/lib/pkgconfig

# Ensure the unlink.d directory exists and copy post-uninstall script
mkdir -p ${PREFIX}/etc/conda/unlink.d
chmod +x ${RECIPE_DIR}/post-unlink.sh
cp ${RECIPE_DIR}/post-unlink.sh ${PREFIX}/etc/conda/unlink.d/

# Clone and build SciFortran
git clone https://github.com/SciFortran/SciFortran.git scifor
cd scifor
mkdir build
cd build
cmake .. -DLONG_PREFIX=Off -DCMAKE_INSTALL_PREFIX=${PREFIX} -DCMAKE_SYSROOT="${SYSROOT_DIR}" 
make -j
make install
cd ../../

mv ${PREFIX}/etc/scifor.pc ${PREFIX}/lib/pkgconfig/
rm -rf ${PREFIX}/etc/modules ${PREFIX}/etc/scifor*.sh


# Clone and build EDIpack
git clone https://github.com/edipack/edipack.git edipack
cd edipack
mkdir build
cd build
cmake .. -DLONG_PREFIX=Off -DCMAKE_INSTALL_PREFIX=${PREFIX} -DCMAKE_SYSROOT="${SYSROOT_DIR}" 
make -j
make install
cd ../../


mv ${PREFIX}/etc/edipack*.pc ${PREFIX}/lib/pkgconfig/
rm -rf ${PREFIX}/etc/modules ${PREFIX}/etc/edipack*.sh

#Remove linking string
if [[ "$OSTYPE" == "linux"* ]]; then
    sed -i 's|-L/usr/lib/x86_64-linux-gnu||g' "${PREFIX}/lib/pkgconfig/scifor.pc"
fi


#Install edipack2py
git clone https://github.com/edipack/edipack2py.git edipack2py
cd edipack2py
$PYTHON -m pip install . --prefix=${PREFIX} --no-deps --ignore-installed --no-build-isolation
