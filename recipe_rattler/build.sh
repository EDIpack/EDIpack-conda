#!/bin/bash

# Set compilers
export FC=${PREFIX}/bin/mpif90
export CC=${PREFIX}/bin/mpicc
export CXX=${PREFIX}/bin/mpicxx


SYSROOT_DIR="${CONDA_BUILD_SYSROOT:-$(${CC:-gcc} -print-sysroot)}"
echo "Sysroot dir: ${SYSROOT_DIR}"
echo "FC: ${FC}"

# Export sysroot flags for linux
if [[ "$OSTYPE" == "linux"* ]]; then
  export LDFLAGS="-L${SYSROOT_DIR}/usr/lib -Wl,--dynamic-linker=${SYSROOT_DIR}/lib/ld-linux-x86-64.so.2"
  export CPPFLAGS="-I${SYSROOT_DIR}/usr/include"
  export CFLAGS="-I${SYSROOT_DIR}/usr/include"
  export CXXFLAGS="-I${SYSROOT_DIR}/usr/include"
  export FCFLAGS="-I${SYSROOT_DIR}/usr/include"
fi

# Create pkg-config directory, if it doesn't exist
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
cmake .. \
  -DLONG_PREFIX=Off \
  -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  -DCMAKE_SYSROOT="${SYSROOT_DIR}" \
  -DCMAKE_FIND_ROOT_PATH="${SYSROOT_DIR}" \
  -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
  -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
  -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY
make -j
make install
cd ../../

# Cleanup
mv ${PREFIX}/etc/scifor.pc ${PREFIX}/lib/pkgconfig/
rm -rf ${PREFIX}/etc/modules/scifor ${PREFIX}/etc/scifor*.sh
rmdir ${PREFIX}/etc/modules


# Clone and build EDIpack
git clone https://github.com/edipack/edipack.git edipack
cd edipack
mkdir build
cd build
cmake .. -DLONG_PREFIX=Off -DCMAKE_INSTALL_PREFIX=${PREFIX} -DCMAKE_SYSROOT="${SYSROOT_DIR}" 
make -j
make install
cd ../../

# Cleanup
mv ${PREFIX}/etc/edipack*.pc ${PREFIX}/lib/pkgconfig/
rm -rf ${PREFIX}/etc/modules/edipack ${PREFIX}/etc/edipack*.sh
rmdir ${PREFIX}/etc/modules

#Remove problematic linking string on Linux
if [[ "$OSTYPE" == "linux"* ]]; then
    sed -i 's|-L/usr/lib/x86_64-linux-gnu||g' "${PREFIX}/lib/pkgconfig/scifor.pc"
fi


# Install edipack2py
git clone https://github.com/edipack/edipack2py.git edipack2py
cd edipack2py
$PYTHON -m pip install . --prefix=${PREFIX} --no-deps --ignore-installed --no-build-isolation
