#!/bin/bash

source $TRAVIS_BUILD_DIR/.travis/common.sh
set -e

if [ ! -z "$USE_SYSTEM_GCC_VERSION" ]; then
	sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y
	sudo apt update
	sudo apt install -y gcc-${USE_SYSTEM_GCC_VERSION} g++-${USE_SYSTEM_GCC_VERSION}
fi

# Getting the conda environment
start_section "environment.conda" "Setting up basic ${YELLOW}conda environment${NC}"

mkdir -p $BASE_PATH
./conda-get.sh $CONDA_PATH
hash -r
end_section "environment.conda"

$SPACER

# Output some useful info
start_section "info.conda.env" "Info on ${YELLOW}conda environment${NC}"
./conda-env.sh info
end_section "info.conda.env"

start_section "info.conda.config" "Info on ${YELLOW}conda config${NC}"
./conda-env.sh config --show
end_section "info.conda.config"

start_section "info.conda.package" "Info on ${YELLOW}conda package${NC}"
./conda-env.sh render --no-source $CONDA_BUILD_ARGS || true
end_section "info.conda.package"

$SPACER

start_section "conda.copy" "${GREEN}Copying package...${NC}"
mkdir -p /tmp/conda/$PACKAGE
cp -vRL $PACKAGE/* /tmp/conda/$PACKAGE/
cd /tmp/conda/
end_section "conda.copy"

$SPACER

start_section "conda.download" "${GREEN}Downloading..${NC}"
./conda-env.sh build --source $CONDA_BUILD_ARGS || true
end_section "conda.download"
