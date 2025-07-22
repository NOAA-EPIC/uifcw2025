#!/bin/bash
mkdir -p /opt/build 
mkdir -p /opt/dist
DEBIAN_FRONTEND=noninteractive apt-get update -yq --allow-unauthenticated 
DEBIAN_FRONTEND=noninteractive apt-get -yq upgrade
DEBIAN_FRONTEND=noninteractive apt install -y gcc g++ gfortran gdb
DEBIAN_FRONTEND=noninteractive apt install -y build-essential
DEBIAN_FRONTEND=noninteractive apt install -y libkrb5-dev
DEBIAN_FRONTEND=noninteractive apt install -y m4
DEBIAN_FRONTEND=noninteractive apt install -y git
DEBIAN_FRONTEND=noninteractive apt install -y git-lfs
DEBIAN_FRONTEND=noninteractive apt install -y bzip2
DEBIAN_FRONTEND=noninteractive apt install -y unzip
DEBIAN_FRONTEND=noninteractive apt install -y automake
DEBIAN_FRONTEND=noninteractive apt install -y autopoint
DEBIAN_FRONTEND=noninteractive apt install -y gettext
DEBIAN_FRONTEND=noninteractive apt install -y texlive
DEBIAN_FRONTEND=noninteractive apt install -y libcurl4-openssl-dev
DEBIAN_FRONTEND=noninteractive apt install -y libssl-dev
DEBIAN_FRONTEND=noninteractive apt install -y lua5.3
DEBIAN_FRONTEND=noninteractive apt install -y liblua5.3-dev
DEBIAN_FRONTEND=noninteractive apt install -y lua-posix

# install cmake
cd /opt/build 
curl -LO https://github.com/Kitware/CMake/releases/download/v3.27.9/cmake-3.27.9-linux-x86_64.sh && /bin/bash cmake-3.27.9-linux-x86_64.sh --prefix=/usr/local --skip-license
# install lmod
wget https://sourceforge.net/projects/lmod/files/Lmod-8.7.tar.bz2
tar vxjf Lmod-8.7.tar.bz2
cd Lmod-8.7
./configure --prefix=/usr/share && make install
ln -s /usr/share/lmod/lmod/init/profile /etc/profile.d/z00_lmod.sh
echo "dash dash/sh boolean false" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash
ls -l /bin/sh
DEBIAN_FRONTEND=noninteractive apt-get update -yq --allow-unauthenticated
#rm /etc/profile.d/modules.sh
#dpkg -S /etc/profile.d/modules.sh
cd /opt
git clone -b release/1.9.0 --recurse-submodules https://github.com/jcsda/spack-stack.git
cd spack-stack
. ./setup.sh
spack compiler find
spack compiler rm gcc@12.3.0
spack install intel-oneapi-compilers@2024.2.1
spack install intel-oneapi-mpi@2021.14.0
spack compiler add `spack location -i intel-oneapi-compilers`/opt/spack-stack/spack/opt/spack/linux-ubuntu22.04-*/gcc-11.4.0/intel-oneapi-compilers-2024.2.1-*/compiler/latest/bin
spack stack create env --site linux.default --template unified-dev --name ue-oneapi-2024.2.1 --compiler oneapi 
tee /opt/spack-stack/envs/ue-oneapi-2024.2.1/spack.yaml <<EOF
# spack-stack hash: 261cfcc
# spack hash: f1be100187
spack:
  concretizer:
    unify: when_possible

  view: false
  include:
  - site
  - common

  definitions:
  - compilers:
    - '%oneapi'
  - packages:
    - ufs-srw-app-env       ^esmf@=8.8.0 ^crtm@=3.1.1-build1
    - ufs-weather-model-env ^esmf@=8.8.0 ^crtm@=3.1.1-build1
    - crtm@3.1.1-build1
    - mapl@2.53.4 ^esmf@8.8.0
    - esmf@=8.8.0 snapshot=none
  specs:
  - matrix:
    - [$packages]
    - [$compilers]
    exclude:
    # Don't build ai-env and jedi-tools-env with Intel or oneAPI,
    # some packages don't build (e.g., py-torch in ai-env doesn't
    # build with Intel, and there are constant problems concretizing
    # the environment
    - ai-env%intel
    - ai-env%oneapi
    - jedi-tools-env%intel
    - jedi-tools-env%oneapi
  packages:
    all:
      prefer: ['%oneapi']
  modules:
    default:
      lmod:
        core_compilers:
        - gcc@=11.4.0
  bootstrap:
    enable: true
    root: $spack/bootstrap
    sources:
    - name: github-actions-v0.6
      metadata: $spack/share/spack/bootstrap/github-actions-v0.6
    - name: github-actions-v0.5
      metadata: $spack/share/spack/bootstrap/github-actions-v0.5
    - name: spack-install
      metadata: $spack/share/spack/bootstrap/spack-install
    trusted:
    # By default we trust bootstrapping from sources and from binaries
    # produced on Github via the workflow
      github-actions-v0.6: true
      github-actions-v0.5: true
      spack-install: true
EOF

cd /opt/spack-stack/envs/ue-oneapi-2024.2.1
spack env activate -p .
cd /opt/spack-stack
. ./setup.sh 
spack concretize 2>&1 | tee log.concretize
spack install --verbose --fail-fast --show-log-on-error --no-check-signature 2>&1 | tee log.install
tee /opt/spack-stack/envs/ue-oneapi-2024.2.1/site/modules.yaml <<EOF1
modules:
  default:
    enable::
    - lmod
    tcl:
      include:
      # List of packages for which we need modules that are blacklisted by default
      - openmpi
      - mpich
      - python
EOF1

cp /root/.spack/linux/compilers.yaml /opt/spack-stack/envs/ue-oneapi-2024.2.1/site 
cd /opt/spack-stack
. ./setup.sh && source /usr/share/lmod/lmod/init/bash
cd /opt/spack-stack/envs/ue-oneapi-2024.2.1
spack env activate -p .
spack module lmod refresh -y
spack stack setup-meta-modules
