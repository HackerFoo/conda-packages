#!/bin/bash

set -e

TARGET=or1k-elf
GCC=$TARGET-newlib-gcc

CONDA_PYTHON=$(conda info --root)/bin/python
${CONDA_PYTHON} ${RECIPE_DIR}/download-extra-sources.py

# Check binutils
$TARGET-as --version
# Check the "nostdc" gcc is already installed
GCC_STAGE1_VERSION=$($TARGET-gcc --version 2>&1 | head -1 | sed -e"s/$TARGET-gcc (GCC) //")
GCC_STAGE2_VERSION=$(echo $PKG_VERSION | sed -e's/-.*//')
if [ "$GCC_STAGE1_VERSION" != "$GCC_STAGE2_VERSION" ]; then
	echo "Stage 1 compiler (nostdc) not the same version as us!"
	echo "nostdc version: $GCC_STAGE1_VERSION"
	echo "  this version: $GCC_STAGE2_VERSION"
 	exit 1
fi

set -x

# Fetch upstream gcc so we can get a git-describe delta
echo $SRC_DIR
echo $PWD

(
	export GIT_DIR=$(${CONDA_PYTHON} ${RECIPE_DIR}/find-git-cache.py)
	if ! git remote get-url upstream > /dev/null 2>&1; then
		git remote add upstream git://gcc.gnu.org/git/gcc.git
		git fetch upstream
	fi
)

git fetch

# Find our current or1k release
OR1K_RELEASE=$(git describe --abbrev=0 --match or1k-*-release)
echo "    or1k release: '$OR1K_RELEASE'"
UPSTREAM_RELEASE=$(echo $OR1K_RELEASE | sed -e's/^or1k-/gcc-/' -e's/\./_/g')
echo "upstream release: '$UPSTREAM_RELEASE'"
GIT_REV=$(git describe --tags --long --match ${UPSTREAM_RELEASE} | sed -e"s/^${UPSTREAM_RELEASE}-//" -e's/-/_/')
echo "  or1k git delta: '$GIT_REV'"

rm -rf libstdc++-v3

cd ..
ls -l

mkdir build-newlib
cd build-newlib
../newlib-*/configure \
        --prefix=$PREFIX \
	--target=$TARGET \


make -j$CPU_COUNT
make install
cd ..

mkdir build-gcc
cd build-gcc
export LDFLAGS=-static
../gcc-*/configure \
	\
	--program-prefix=$TARGET-newlib- \
	\
        --prefix=$PREFIX \
        --with-gmp=$PREFIX \
        --with-mpfr=$PREFIX \
        --with-mpc=$PREFIX \
        --with-isl=$PREFIX \
        --with-cloog=$PREFIX \
	\
	--target=$TARGET \
	--enable-languages="c,c++" \
	--with-newlib \
	--enable-libgcc \


make -j$CPU_COUNT
make install-strip
cd ..

$PREFIX/bin/$GCC --version
$PREFIX/bin/$GCC --version 2>&1 | head -1 | sed -e's/.* //' -e"s/\$/_$GIT_REV/" > ./__conda_version__.txt
touch .buildstamp
TZ=UTC date +%Y%m%d_%H%M%S -r .buildstamp > ../__conda_buildstr__.txt
TZ=UTC date +%Y%m%d%H%M%S  -r .buildstamp > ../__conda_buildnum__.txt