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
spack install intel-oneapi-mpi@2021.13.1
export ONEAPIPATH=`ls -ld /opt/spack-stack/spack/opt/spack/linux-ubuntu22.04-*/gcc-11.4.0/intel-oneapi-compilers-2024.2.1-*/compiler/latest/bin/`
spack compiler add `spack location -i intel-oneapi-compilers` $ONEAPIPATH

tee /opt/spack-stack/configs/sites/tier2/linux.default/compilers.yaml <<EOF
compilers:
- compiler:
    spec: oneapi@2024.2.1
    paths:
      cc: /opt/spack-stack/spack/opt/spack/linux-ubuntu22.04-sapphirerapids/gcc-11.4.0/intel-oneapi-compilers-2024.2.1-j3owv3rsoh7igqvwmvp7ez6i3ozeayvs/compiler/latest/bin/icx
      cxx: /opt/spack-stack/spack/opt/spack/linux-ubuntu22.04-sapphirerapids/gcc-11.4.0/intel-oneapi-compilers-2024.2.1-j3owv3rsoh7igqvwmvp7ez6i3ozeayvs/compiler/latest/bin/icpx
      f77: /opt/spack-stack/spack/opt/spack/linux-ubuntu22.04-sapphirerapids/gcc-11.4.0/intel-oneapi-compilers-2024.2.1-j3owv3rsoh7igqvwmvp7ez6i3ozeayvs/compiler/latest/bin/ifort
      fc: /opt/spack-stack/spack/opt/spack/linux-ubuntu22.04-sapphirerapids/gcc-11.4.0/intel-oneapi-compilers-2024.2.1-j3owv3rsoh7igqvwmvp7ez6i3ozeayvs/compiler/latest/bin/ifort
    flags: {}
    operating_system: ubuntu22.04
    target: x86_64
    modules:
    - intel-oneapi/2024.2.1
    environment:
      prepend_path:
        MODULEPATH: '/opt/modulefiles'
    extra_rpaths: []
      #modules:
      #- spack-managed-x86-64_v3
      #- intel-oneapi-compilers/2024.2.1
      #    environment:
      #      set:
      #        # https://github.com/ufs-community/ufs-weather-model/issues/2015#issuecomment-1864438186
      #        I_MPI_EXTRA_FILESYSTEM: 'ON'
      #        # override system module settings for FC and F77 (they're set to ifx)
      #        F77: '/apps/spack-managed-x86_64_v3-v1.0/gcc-11.3.1/intel-oneapi-compilers-2024.2.1-podbez65l57ms4uba527kg7pomxk5y3m/compiler/2024.2/bin/ifort'
      #        FC: '/apps/spack-managed-x86_64_v3-v1.0/gcc-11.3.1/intel-oneapi-compilers-2024.2.1-podbez65l57ms4uba527kg7pomxk5y3m/compiler/2024.2/bin/ifort'
      #      prepend_path:
      #        PATH: /usr/bin
      #        LD_LIBRARY_PATH: /usr/lib:/usr/lib64
      #        CPATH: '/usr/include/c++/11:/usr/include/c++/11/x86_64-redhat-linux'
      #    extra_rpaths: []

EOF

tee /opt/spack-stack/configs/sites/tier2/linux.default/modules.yaml <<EOF
modules:
  default:
    enable::
    - lmod
    lmod:
      include:
      # List of packages for which we need modules that are blacklisted by default
      - python
      - openssl
EOF

tee /opt/spack-stack/configs/sites/tier2/linux.default/packages.yaml <<EOF
packages:
  # For addressing https://github.com/JCSDA/spack-stack/issues/1355
  #   Use system zlib instead of spack-built zlib-ng 
  autoconf:
    externals:
    - spec: autoconf@2.71
      prefix: /usr
  automake:
    externals:
    - spec: automake@1.16.5
      prefix: /usr
# Don't use issues with openssl
#curl:
#  externals:
#  - spec: curl@7.76.1+gssapi+ldap+nghttp2
#    prefix: /usr
  gawk:
    externals:
    - spec: gawk@5.1.0
      prefix: /usr
  gettext:
    externals:
    - spec: gettext@0.21
      prefix: /usr
  git:
    externals:
    - spec: git@2.34.1
      prefix: /usr
  git-lfs:
    externals:
    - spec: git-lfs@3.0.2
      prefix: /usr
  gmake:
    externals:
    - spec: gmake@4.3
      prefix: /usr
  grep:
    externals:
    - spec: grep@3.7
      prefix: /usr
  groff:
    externals:
    - spec: groff@1.22.4
      prefix: /usr
# Don't use, incomplete installation!
#libtool:
#  externals:
#  - spec: libtool@2.4.6
#    prefix: /usr
  m4:
    externals:
    - spec: m4@1.4.18
      prefix: /usr
  openssl:
    externals:
    - spec: openssl@3.0.2
      prefix: /usr
  perl:
    externals:
    - spec: perl@5.34
      prefix: /usr
  sed:
    externals:
    - spec: sed@4.8
      prefix: /usr
#tar:
#  externals:
#  - spec: tar@1.34
#    prefix: /usr
  wget:
    externals:
    - spec: wget@1.21.2
      prefix: /usr
EOF

tee /opt/spack-stack/configs/sites/tier2/linux.default/packages_oneapi.yaml <<EOF
packages:
  all:
    compiler:: [oneapi@2024.2.1]
    providers:
      mpi:: [intel-oneapi-mpi@2021.13]
      # Remove the next three lines to switch to intel-oneapi-mkl
      blas:: [openblas]
      fftw-api:: [fftw]
      lapack:: [openblas]
  mpi:
    buildable: False
  intel-oneapi-mpi:
    buildable: False
    externals:
    - spec: intel-oneapi-mpi@2021.13.1
      modules:
      - intel-oneapi-mpi/2021.13.1
      environment:
      prepend_path:
        MODULEPATH: '/opt/modulefiles'
      prefix: /opt/spack-stack/spack/opt/spack/linux-ubuntu22.04-sapphirerapids/gcc-11.4.0/intel-oneapi-mpi-2021.13.1-5l7irsoye6le4sudsuovujk4k4i47hwe
      
  ectrans:
    require::
    - '@1.5.0 ~mkl +fftw'
  gsibec:
    require::
    - '@1.2.1 ~mkl'
  py-numpy:
    require::
    - '@1.26'
    - '^openblas'
  py-scipy:
    require:
      '%gcc'
EOF

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
    - [\$packages]
    - [\$compilers]
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
    root: \$spack/bootstrap
    sources:
    - name: github-actions-v0.6
      metadata: \$spack/share/spack/bootstrap/github-actions-v0.6
    - name: github-actions-v0.5
      metadata: \$spack/share/spack/bootstrap/github-actions-v0.5
    - name: spack-install
      metadata: \$spack/share/spack/bootstrap/spack-install
    trusted:
    # By default we trust bootstrapping from sources and from binaries
    # produced on Github via the workflow
      github-actions-v0.6: true
      github-actions-v0.5: true
      spack-install: true
EOF

cd /opt/spack-stack/envs/ue-oneapi-2024.2.1
spack env activate -p .
spack concretize 2>&1 | tee log.concretize
spack install --verbose --fail-fast --show-log-on-error --no-check-signature 2>&1 | tee log.install

spack module lmod refresh -y
spack stack setup-meta-modules
