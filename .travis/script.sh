#!/bin/bash

source .travis/common.sh
set -e

$SPACER

start_section "info.conda.package" "Info on ${YELLOW}conda package${NC}"
$TRAVIS_BUILD_DIR/conda-env.sh render $CONDA_BUILD_ARGS
end_section "info.conda.package"

$SPACER

start_section "conda.check" "${GREEN}Checking...${NC}"
$TRAVIS_BUILD_DIR/conda-env.sh build --check $CONDA_BUILD_ARGS || true
end_section "conda.check"

$SPACER

start_section "conda.build" "${GREEN}Building..${NC}"
$CONDA_PATH/bin/python $TRAVIS_BUILD_DIR/.travis-output.py /tmp/output.log $TRAVIS_BUILD_DIR/conda-env.sh build $CONDA_BUILD_ARGS
end_section "conda.build"

$SPACER

# Remove trailing ';' and split CONDA_OUT into array of packages
IFS=';' read -r -a PACKAGES <<< "${CONDA_OUT%?}"

start_section "conda.build" "${GREEN}Installing..${NC}"
for element in "${PACKAGES[@]}"
do
	$TRAVIS_BUILD_DIR/conda-env.sh install $element
done
end_section "conda.build"

$SPACER

start_section "conda.du" "${GREEN}Disk usage..${NC}"

for element in "${PACKAGES[@]}"
do
	du -h $element
done

end_section "conda.du"

$SPACER

start_section "conda.clean" "${GREEN}Cleaning up..${NC}"
#conda clean -s --dry-run
end_section "conda.clean"

$SPACER
