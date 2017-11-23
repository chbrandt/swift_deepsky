#!/bin/bash
set -e

# Label for this script messages
PKGSTP="HEASoft"

# ====================================================================
# Variables we may *declare* in the environment this script runs.
# These variables modify the defaults, as listed below:
#
# <variable>           <default>
# HEASOFT_VERSION    : 6.22.1
# HEASOFT_TMPDIR     : /tmp/heasoft
# HEASOFT_INSTALLDIR : /usr/local/heasoft
# ====================================================================

# Package info.. what to download, basically
H=$(cd `dirname $BASH_SOURCE`; pwd)
[ -f ${H}/heasoft_version.sh ] && source ${H}/heasoft_version.sh
VERSION="${HEASOFT_VERSION:-6.22.1}"
PACKAGE="heasoft-${VERSION}"
TARBALL="${PACKAGE}src.tar.gz"

echo HEASoft version: $HEASOFT_VERSION 

# Temp dir; basically for download
TMPDIR="${HEASOFT_TMPDIR:-/tmp/heasoft}"
unset HEASOFT_TMPDIR

# Where to install the package
INSTALLDIR="${HEASOFT_INSTALLDIR:-/usr/local/heasoft}"
unset HEASOFT_INSTALLDIR

if [ -d $INSTALLDIR ]; then
    1>&2 echo "WARNING: '$INSTALLDIR' already exist."
    1>&2 echo "         Please, remove it or change the location (value) pointed by 'HEASOFT_INSTALLDIR'."
    1>&2 echo "         Otherwise, '$INSTALLDIR' will be overwritten."
fi

# What to download.
# The following will download the necessary for "swift" setup:
#HEASCOMP=(BUILD_DIR attitude ftools/BUILD_DIR ftools/bin.perl ftools/ftools.par ftools/help heacore heagen heatools tcltk)
# If you want to download the entire heasoft package, just define
HEASCOMP='full'
# If you want the minimal (ftools) set of packages, define
# HEASCOMP=(BUILD_DIR ftools heacore heagen tcltk)

# From where to download the package(s) if necessary
#URL="ftp://heasarc.gsfc.nasa.gov/software/lheasoft/release"
URL="ftp://heasarc.gsfc.nasa.gov/software/lheasoft/lheasoft${VERSION}/"
#URL="file:///tmp/heasoft/"

# Calibration database location
CALDB="${INSTALLDIR}/caldb"

# Where to unpack the source code..
#BROWSE='yes'
if [ "$BROWSE" == 'yes' ]; then
  UNPACKDIR="$INSTALLDIR"
else
  UNPACKDIR="${TMPDIR}/${VERSION}"
fi

# There is a build package dir, keep it there..
BUILDDIR="${UNPACKDIR}/BUILD_DIR"

# Where to save environment/login settings
BASHRC='/etc/bashrc'

# This is Centos/RedHat dependent. Nevertheless, adapt it
# to other linux distro (e.g, Ubuntu) should be straightforward.
function install_dependencies() {
  echo "$PKGSTP step: installing dependencies.."
  yum -y groupinstall "Development Tools"   &&\
  yum -y install  ncurses-devel libXt-devel \
                  gcc gcc-c++ gcc-gfortran  \
                  compat-gcc-34-g77         \
                  perl-ExtUtils-MakeMaker   \
                  python-devel              &&\
  yum -y install  libpng-devel              &&\
  yum -y install  vim tar wget which git curl bc
  sts=$?
  yum clean all
  return $sts
}

# Download function is execute if there is no "$TARBALL"
# file inside "$TMPDIR"
function download() {
  echo "$PKGSTP step: downloading $TARBALL .."
  if [ "$HEASCOMP" = "full" ]
  then
    wget -q "${URL}/${TARBALL}"
  else
    for i in ${HEASCOMP[*]}
    do
      wget --mirror -nH --cut-dirs=3 --no-parent --preserve-permissions ${URL}/${PACKAGE}/${i}
    done
    tar -czf $TARBALL $PACKAGE
  fi
  return $?
}

function unpack() {
  echo "$PKGSTP step: extracting $TARBALL .."
  [ -z "$1" ] && return 1 || PKG="$1"
  tar -xzf "$PKG" --strip-components=1
  return $?
}

function build() {
  echo "$PKGSTP step: building heasoft.."
  echo '..configure..'
  ./configure --prefix="$INSTALLDIR"  > ${TMPDIR}/config.log 2>&1
  echo '..make..'
  ./hmake                             > ${TMPDIR}/build.log 2>&1
  echo '..install..'
  ./hmake install                     > ${TMPDIR}/install.log 2>&1
  echo '..done.'
  LIBC=$(ldd --version | head -n1 | awk '{print $NF}')
  echo "export HEADAS=${INSTALLDIR}/x86_64-unknown-linux-gnu-libc${LIBC}" >> $BASHRC
  echo 'source $HEADAS/headas-init.sh' >> $BASHRC
  echo "..heasoft built."
  cp ${TMPDIR}/*.log ${INSTALLDIR}/.
}

function caldb() {
  echo "$PKGSTP step: setting up caldb.."
  [ ! -d "$CALDB" ] && mkdir -p "$CALDB"
  echo "Downloading caldb.."
  wget -q https://heasarc.gsfc.nasa.gov/FTP/caldb/software/tools/caldb_setup_files.tar.Z
  echo "..done"
  tar -xzf caldb_setup_files.tar.Z -C ${CALDB}
  [ "$?" != "0" ] && return 1
  CALDBINIT="$CALDB/software/tools/caldbinit.sh"
  CALDBURL='ftp://legacy.gsfc.nasa.gov/caldb'
  echo "export CALDB=$CALDBURL" > $CALDBINIT
  echo "export CALDBCONFIG=$CALDB/software/tools/caldb.config" >> $CALDBINIT
  echo "export CALDBALIAS=$CALDB/software/tools/alias_config.fits" >> $CALDBINIT
  echo "export CALDB=$CALDB" >> $BASHRC
  echo "source $CALDBINIT" >> $BASHRC
  echo "..caldb setup."
}

function exit_error() {
  echo "error: $1"
  echo "Ending setup process."
  return 1
}

function clean() {
  echo "$PKGSTP: cleaning heasoft.."
  ( cd $BUILDDIR &&
    make clean > /dev/null 2>&1 && \
    make distclean > /dev/null 2>&1
  )
  rm -rf $UNPACKDIR
  rm -rf $TMPDIR
}

function install() {
  echo "$PKGSTP: configuring heasoft.."
  install_dependencies || exit_error "dependencies failed to install."

  # Default compilers; IF those variables are not defined yet!
  CC=${CC:-gcc}
  CXX=${CXX:-g++}
  FC=${FC:-gfortran}
  PERL=${PERL:-perl}
  PYTHON=${PYTHON:-python}
#  [ -z "$CC" -o -z "$CXX" -o -z "$FC" -o -z "$PERL" -o -z "$PYTHON" ] && exit 1
  export CC CXX FC PERL PYTHON

  INITDIR=$PWD

  [ -d "$TMPDIR" ] || mkdir -p $TMPDIR
  (
    echo "Entering in $TMPDIR"
    cd $TMPDIR
    if [ ! -f "$TARBALL" ]; then
      download || exit_error "download failed."
    fi
  )

  [ -d "$UNPACKDIR" ] || mkdir -p $UNPACKDIR
  (
    echo "Entering in $UNPACKDIR"
    cd $UNPACKDIR
    unpack ${TMPDIR}/${TARBALL} || exit_error 'not able to unpack?!'
  )

  (
    echo "Entering in $BUILDDIR"
    cd $BUILDDIR
    env > ${TMPDIR}/build_environment.log

    build && caldb

    [ "$?" != "0" ] && exit_error "build failed."
    clean
  )
  echo "Looks like heasoft setup worked like a charm ;)"
  echo "Finished."
  return 0
}
