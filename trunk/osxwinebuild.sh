#!/bin/bash
#
# Compile and install Wine and many prerequisites in a self-contained directory.
#
# Copyright (C) 2009,2010 Ryan Woodsmall <rwoodsmall@gmail.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
#

# fail_and_exit
#   first function defined since it will be called if there are failures
function fail_and_exit {
	echo "${@} - exiting"
	exit 1
}

# usage
#   defined early; may be called if "--help" or a bunk option is passed
function usage {
	echo "usage: $(basename ${0}) [--help] [--stable] [--devel] [--crossover] [--cxgames] [--no-clean-prefix] [--no-clean-source] [--no-rebuild] [--no-reconfigure]"
	echo ""
	echo "  Informational option(s):"
	echo "    --help: display this help message"
	echo ""
	echo "  Build type options (mutually exclusive):"
	echo "    --stable: build the stable version of Wine (default)"
	echo "    --devel: build the development version of Wine"
	echo "    --crossover: build Wine using CrossOver sources"
	echo "    --cxgames: build Wine using CrossOver Games sources"
	echo ""
	echo "  Common build options:"
	echo "    --no-clean-prefix: do not move and create a new prefix if one already exists"
	echo "    --no-clean-source: do not remove/extract source if already done"
	echo "    --no-rebuild: do not rebuild packages, just reinstall"
	echo "    --no-reconfigure: do not re-run 'configure' for any packages"
	echo ""
}

# options
#   set Wine build type to zero, handle below using flags
BUILDSTABLE=0
BUILDDEVEL=0
BUILDCROSSOVER=0
BUILDCXGAMES=0
#   use this flag to track which Wine we're building
BUILDFLAG=0
#   we remove and rebuild everything in a new prefix by default
NOCLEANPREFIX=0
NOCLEANSOURCE=0
NOREBUILD=0
NORECONFIGURE=0
#   cycle through options and set appropriate vars
if [ ${#} -gt 0 ] ; then
	until [ -z ${1} ] ; do
		case ${1} in
			--stable)
				if [ ${BUILDFLAG} -ne 1 ] ; then
					BUILDFLAG=$((${BUILDFLAG}+1))
				fi
				shift ;;
			--devel)
				if [ ${BUILDFLAG} -ne 10 ] ; then
					BUILDFLAG=$((${BUILDFLAG}+10))
				fi
				shift ;;
			--crossover)
				if [ ${BUILDFLAG} -ne 100 ] ; then
					BUILDFLAG=$((${BUILDFLAG}+100))
				fi
				shift ;;
			--cxgames)
				if [ ${BUILDFLAG} -ne 1000 ] ; then
					BUILDFLAG=$((${BUILDFLAG}+1000))
				fi
				shift ;;
			--no-clean-prefix)
				NOCLEANPREFIX=1
				echo "found --no-clean-prefix option, will install to existing prefix if it exists" ; shift ;;
			--no-clean-source)
				NOCLEANSOURCE=1
				echo "found --no-clean-source option, will not remove/rextract existing source directories" ; shift ;;
			--no-rebuild)
				NOREBUILD=1
				echo "found --no-rebuild option, will not re-run 'make' on existing source directories" ; shift ;;
			--no-reconfigure)
				NORECONFIGURE=1
				echo "found --no-reconfigure option, will not re-run 'configure' on existing source directories" ; shift ;;
			--help)
				usage ; exit 0 ;;
			*)
				usage ; exit 1 ;;
		esac
	done
fi

# wine version
#   a tag we'll use later
WINETAG=""
#   stable
WINESTABLEVERSION="1.2.1"
WINESTABLESHA1SUM="02df427698de8a6d937e722923c8ac1cf886ca27"
#   devel
WINEDEVELVERSION="1.3.8"
WINEDEVELSHA1SUM="d36e7d8c0d8d5e2f86d47b175e197e9623660495"
#   CrossOver Wine
CROSSOVERVERSION="9.2.0"
CROSSOVERSHA1SUM="99511c601f89ab03025d8c34a81811bda6799647"
#   CrossOver Games Wine
CXGAMESVERSION="9.2.0"
CXGAMESSHA1SUM="8a1ea0a0e87127b2c2cd9ed819760432897b3b19"

# check our build flag and pick the right version
if [ ${BUILDFLAG} -eq 1 ] || [ ${BUILDFLAG} -eq 0 ] ; then
	BUILDSTABLE=1
	WINEVERSION="${WINESTABLEVERSION}"
	WINESHA1SUM="${WINESTABLESHA1SUM}"
	WINETAG="Wine ${WINEVERSION}"
	echo "found --stable option or no option specified, will build Wine stable version"
elif [ ${BUILDFLAG} -eq 10 ] ; then
	BUILDDEVEL=1
	WINEVERSION="${WINEDEVELVERSION}"
	WINESHA1SUM="${WINEDEVELSHA1SUM}"
	WINETAG="Wine ${WINEVERSION}"
	echo "found --devel option, will build Wine devel version"
elif [ ${BUILDFLAG} -eq 100 ] ; then
	BUILDCROSSOVER=1
	WINEVERSION="${CROSSOVERVERSION}"
	WINESHA1SUM="${CROSSOVERSHA1SUM}"
	WINETAG="CrossOver Wine ${WINEVERSION}"
	echo "found --crossover option, will build Wine from CrossOver sources"
elif [ ${BUILDFLAG} -eq 1000 ] ; then
	BUILDCXGAMES=1
	WINEVERSION="${CXGAMESVERSION}"
	WINESHA1SUM="${CXGAMESSHA1SUM}"
	WINETAG="CrossOver Games Wine ${WINEVERSION}"
	echo "found --cxgames option, will build Wine from CrossOver Games sources"
else
	BUILDSTABLE=1
	BUILDDEVEL=0
	BUILDCROSSOVER=0
	BUILDCXGAMES=0
	WINEVERSION="${WINESTABLEVERSION}"
	WINESHA1SUM="${WINESTABLESHA1SUM}"
	WINETAG="Wine ${WINEVERSION}"
	echo "found multiple build types, defaulting to Wine stable"
fi

# what are we building?
echo "building ${WINETAG}"

# set our file name, Wine source directory name and URL correctly
if [ ${BUILDSTABLE} -eq 1 ] || [ ${BUILDDEVEL} -eq 1 ] ; then
	WINEFILE="wine-${WINEVERSION}.tar.bz2"
	WINEURL="http://downloads.sourceforge.net/wine/${WINEFILE}"
	WINEDIR="wine-${WINEVERSION}"
elif [ ${BUILDCROSSOVER} -eq 1 ] || [ ${BUILDCXGAMES} -eq 1 ] ; then
	if [ ${BUILDCROSSOVER} -eq 1 ] ; then
		WINEFILE="crossover-sources-${WINEVERSION}.tar.gz"
	elif [ ${BUILDCXGAMES} -eq 1 ] ; then
		WINEFILE="crossover-games-sources-${WINEVERSION}.tar.gz"
	fi
	WINEURL="http://media.codeweavers.com/pub/crossover/source/${WINEFILE}"
	WINEDIR="wine"
fi

# set gecko version from build type
if [ ${BUILDDEVEL} -eq 1 ] ; then
	GECKOVERSION="1.1.0"
	GECKOSHA1SUM="1b6c637207b6f032ae8a52841db9659433482714"
else
	GECKOVERSION="1.0.0"
	GECKOSHA1SUM="afa22c52bca4ca77dcb9edb3c9936eb23793de01"
fi

# timestamp
export TIMESTAMP=$(date '+%Y%m%d%H%M%S')

# wine dir
#   where everything lives - ~/wine by default
export WINEBASEDIR="${HOME}/wine"
#   make the base dir if it doesn't exist
if [ ! -d ${WINEBASEDIR} ] ; then
	mkdir -p ${WINEBASEDIR} || fail_and_exit "could not create ${WINEBASEDIR}"
fi

# installation path
#   ~/wine/wine-X.Y.Z for standard Wine
#   if we're doing a CrossOver build, set the proper directory name
WINEINSTALLDIRPREPEND=""
if [ ${BUILDCROSSOVER} -eq 1 ] ; then
	WINEINSTALLDIRPREPEND="crossover-"
elif [ ${BUILDCXGAMES} -eq 1 ] ; then
	WINEINSTALLDIRPREPEND="crossover-games-"
fi
export WINEINSTALLPATH="${WINEBASEDIR}/${WINEINSTALLDIRPREPEND+${WINEINSTALLDIRPREPEND}}wine-${WINEVERSION}"

echo "${WINETAG} will be installed into ${WINEINSTALLPATH}"

# wine source path
#   ~/wine/source
export WINESOURCEPATH="${WINEBASEDIR}/source"
if [ ! -d ${WINESOURCEPATH} ] ; then
	mkdir -p ${WINESOURCEPATH} || fail_and_exit "could not create ${WINESOURCEPATH}"
fi

# build path
#   ~/wine/build
export WINEBUILDPATH="${WINEBASEDIR}/build"
if [ ! -d ${WINEBUILDPATH} ] ; then
	mkdir -p ${WINEBUILDPATH} || fail_and_exit "could not create ${WINEBUILDPATH}"
fi

# binary path
#   ~/wine/wine-X.Y.Z/bin
export WINEBINPATH="${WINEINSTALLPATH}/bin"

# include path
#   ~/wine/wine-X.Y.Z/include
export WINEINCLUDEPATH="${WINEINSTALLPATH}/include"

# lib path
#  ~/wine/wine-X.Y.Z/lib
export WINELIBPATH="${WINEINSTALLPATH}/lib"

# darwin/os x major version
#   10.6 = Darwin 10
#   10.5 = Darwin 9
#   ...
export DARWINMAJ=$(uname -r | awk -F. '{print $1}')

# 16-bit code flag
#   enable by default, disable on 10.5
#   XXX - should be checking Xcode version
#   2.x can build 16-bit code, works on 10.4, 10.5, 10.6
#   3.0,3.1 CANNOT build 16-bit code, work on 10.5+
#     XXX - patched ld/ld64 on 10.5 can be used
#   3.2 can build 16-bit code, works only on 10.6
export WIN16FLAG="enable"
if [ ${DARWINMAJ} -eq 9 ] ; then
	export WIN16FLAG="disable"
fi

# os x min version and sdk settings
#   Mac OS X Tiger/10.4
#export OSXVERSIONMIN="10.4"
#   Mac OS X Leopard/10.5
#export OSXVERSIONMIN="10.5"
#   Mac OS X Snow Leopard/10.6
#export OSXVERSIONMIN="10.6"
#   only set SDK version and deployment target env vars if a min version is set
if [ ! -z "${OSXVERSIONMIN}" ] ; then
	if [ ${OSXVERSIONMIN} == "10.4" ] ; then
		export SDKADDITION="u"
	fi
	export OSXSDK="/Developer/SDKs/MacOSX${OSXVERSIONMIN}${SDKADDITION+${SDKADDITION}}.sdk"
	export MACOSX_DEPLOYMENT_TARGET=${OSXVERSIONMIN}
fi

# x11
#   these need to be changed for Xquartz and the like...
#   default is to use OS-provided /usr/X11
export DEFAULTX11DIR="/usr/X11"
export X11DIR="${DEFAULTX11DIR}"
# check for XQuartz in /opt/X11 on 10.6+
if [ ${DARWINMAJ} -ge 10 ] ; then
	# check for the XQuartz launchd entry
	launchctl list | grep -i startx | grep -i xquartz >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		echo "XQuartz launchd startup found, checking for installation"
		# check that directory /opt/X11 exists and use it
		if [ -d /opt/X11 ] ; then
			echo "using XQuartz installed in /opt/X11"
			export X11DIR="/opt/X11"
		else
			echo "XQuartz launchd startup found, but no /opt/X11; reinstall XQuartz?"
		fi
	else
		echo "no XQuartz launchd startup found, assuming system X11 in ${DEFAULTX11DIR}"
	fi
fi
echo "X11 installation set to: \$X11DIR = ${X11DIR}"
export X11BIN="${X11DIR}/bin"
export X11INC="${X11DIR}/include"
export X11LIB="${X11DIR}/lib"

# compiler and preprocessor flags
#   default - set to GCC
: ${CC:="gcc"}
: ${CXX:="g++"}
export CC
export CXX
echo "C compiler set to: \$CC = \"${CC}\""
echo "C++ compiler set to: \$CXX = \"${CXX}\""
#   preprocessor/compiler flags
export CPPFLAGS="-I${WINEINCLUDEPATH} ${OSXSDK+-isysroot $OSXSDK} -I${X11INC}"

# some extra flags based on CPU features
export CPUFLAGS=""
# XXX - no distcc,clang,llvm support yet!
# XXX - this is way complicated.  I might just do MMX+SSE+common SSEx stuff
# some gcc-specific flags
# a note:
#   all versions of GCC running on Darwin x86/x86_64 10.4+ require GCC 4.0+
#   all versions *should* have support for the P4 "nocona" mtune option
#   all *real* Mac hardware should support SSE3 or better
#   all of the above are true for the dev kit up to the most recent Macs
#   that said, don't know how much "optimization" below is going to help
export USINGGCC=$(echo ${CC} | egrep "(^|/)gcc" | wc -l | tr -d " ")
if [ ${USINGGCC} -eq 1 ] ; then
	# gcc versions
	export GCCVER=$(${CC} --version | head -1 | awk '{print $3}')
	export GCCMAJVER=$(echo ${GCCVER} | cut -d\. -f 1)
	export GCCMINVER=$(echo ${GCCVER} | cut -d\. -f 2)
	# grab all SSE & MMX flags from the CPU feature set
	export CPUFLAGS+=$(sysctl -n machdep.cpu.features | tr "[:upper:]" "[:lower:]" | tr " " "\n" | sed s#^#-m#g | egrep -i "(sse|mmx)" | sort -u | xargs echo)
	# this should always be true, but being paranoid never hurt anyone
	if echo $CPUFLAGS | grep \\-msse >/dev/null 2>&1
	then
		export CPUFLAGS+=" -mfpmath=sse"
	fi
	# set the mtune on GCC based on version
	# should never need to check for GCC <4, but why not?
	if [ ${GCCMAJVER} -eq 4 ] ; then
		# use p4/nocona on GCC 4.0... ugly
		if [ ${GCCMINVER} -eq 0 ] ; then
			export CPUFLAGS+=" -mtune=nocona"
			# no SSE4+ w/4.0
			export CPUFLAGS=$(echo ${CPUFLAGS} | tr " " "\n" | sort -u | grep -vi sse4 | xargs echo)
			# and no SSSE3 on Xcode 2.5; should be gcc 4.0, builds in the 53xx series
			${CC} --version | grep -i "build 53" >/dev/null 2>&1
			if [ $? == 0 ] ; then
				export CPUFLAGS=$(echo ${CPUFLAGS} | tr " " "\n" | sort -u | grep -vi ssse3 | xargs echo)
			fi
		fi
		# use native on 4.2+
		if [ ${GCCMINVER} -ge 2 ] ; then
			export CPUFLAGS+=" -mtune=native"
		fi
	fi
fi
# set our CFLAGS to something useful, and specify we should be using 32-bit
export CFLAGS="-g -O2 -arch i386 -m32 ${CPUFLAGS} ${OSXSDK+-isysroot $OSXSDK} ${OSXVERSIONMIN+-mmacosx-version-min=$OSXVERSIONMIN} ${CPPFLAGS}"
export CXXFLAGS=${CFLAGS}

# linker flags
#   always prefer our Wine install path's lib dir
#   set the sysroot if need be
export LDFLAGS="-L${WINELIBPATH} ${OSXSDK+-isysroot $OSXSDK} -L${X11LIB} -framework CoreServices -lz -L${X11LIB} -lGL -lGLU"

# pkg-config config
#   system and stuff we build only
export PKG_CONFIG_PATH="${WINELIBPATH}/pkgconfig:/usr/lib/pkgconfig:${X11LIB}/pkgconfig"

# aclocal/automake
#   include custom, X11, other system stuff
export ACLOCAL="aclocal -I ${WINEINSTALLPATH}/share/aclocal -I ${X11DIR}/share/aclocal -I /usr/share/aclocal"

# make
#   how many jobs do we run concurrently?
#   core count + 1
export MAKE="make"
export MAKEJOBS=$((`sysctl -n machdep.cpu.core_count | tr -d " "`+1))
export CONCURRENTMAKE="${MAKE} -j${MAKEJOBS}"

# configure
#   use a common prefix
#   disable static libs by default
export CONFIGURE="./configure"
export CONFIGURECOMMONPREFIX="--prefix=${WINEINSTALLPATH}"
export CONFIGURECOMMONLIBOPTS="--enable-shared=yes --enable-static=no"

# SHA-1 sum program
#   openssl is available everywhere
export SHA1SUM="openssl dgst -sha1"

# downloader program
#   curl's avail everywhere!
export CURL="curl"
export CURLOPTS="-kL"
echo "base downloader command: ${CURL} ${CURLOPTS}"

# extract commands
#   currently we only have gzip/bzip2 tar files
export TARGZ="tar -zxvf"
export TARBZ2="tar -jxvf"

# git needs these?
#   not using Git yet, but we will in the future
#   apparently these have to be set or Git will try to use Fink/MacPorts
#   so much smarter than us, Git
export NO_FINK=1
export NO_DARWIN_PORTS=1

# path
#   pull out fink, macports, gentoo - what about homebrew?
#   set our Wine install dir's bin and X11 bin before everything else
export PATH=$(echo $PATH | tr ":" "\n" | egrep -v ^"(/opt/local|/sw|/opt/gentoo)" | xargs echo  | tr " " ":")
export PATH="${WINEBINPATH}:${X11BIN}:${PATH}"

#
# helpers
#

#
# compiler_check
#   output a binary and run it
#
function compiler_check {
	if [ ! -d ${WINEBUILDPATH} ] ; then
		mkdir -p ${WINEBUILDPATH} || fail_and_exit "build directory ${WINEBUILDPATH} doesn't exist and cannot be created"
	fi
	cat > ${WINEBUILDPATH}/$$_compiler_check.c << EOF
#include <stdio.h>
int main(void)
{
  printf("hello\n");
  return(0);
}
EOF
	${CC} ${CFLAGS} ${WINEBUILDPATH}/$$_compiler_check.c -o ${WINEBUILDPATH}/$$_compiler_check || fail_and_exit "compiler cannot output executables"
	${WINEBUILDPATH}/$$_compiler_check | grep hello >/dev/null 2>&1 || fail_and_exit "source compiled fine, but unexpected output was encountered"
	echo "compiler works fine for a simple test"
	rm -f ${WINEBUILDPATH}/$$_compiler_check.c ${WINEBUILDPATH}/$$_compiler_check
}

#
# get_file
#   receives a filename, directory and url
#
function get_file {
	FILE=${1}
	DIRECTORY=${2}
	URL=${3}
	if [ ! -d ${DIRECTORY} ] ; then
		mkdir -p ${DIRECTORY} || fail_and_exit "could not create directory ${DIRECTORY}"
	fi
	pushd . >/dev/null 2>&1
	cd ${DIRECTORY} || fail_and_exit "could not cd to ${DIRECTORY}"
	if [ ! -f ${FILE} ] ; then
		echo "downloading file ${URL} to ${DIRECTORY}/${FILE}"
		${CURL} ${CURLOPTS} -o ${FILE} ${URL}
	else
		echo "${DIRECTORY}/${FILE} already exists - not fetching"
		popd >/dev/null 2>&1
		return
	fi
	if [ $? != 0 ] ; then
		fail_and_exit "could not download ${URL}"
	else
		echo "successfully downloaded ${URL} to ${DIRECTORY}/${FILE}"
	fi
	popd >/dev/null 2>&1
}

#
# check_sha1sum
#   receives a filename a SHA sum to compare
#
function check_sha1sum {
	FILE=${1}
	SHASUM=${2}
	if [ ! -e ${FILE} ] ; then
		fail_and_exit "${FILE} doesn't seem to exist"
	fi
	FILESUM=$(${SHA1SUM} < ${FILE})
	if [ "${SHASUM}x" != "${FILESUM}x" ] ; then
		fail_and_exit "failed to verify ${FILE}"
	else
		echo "successfully verified ${FILE}"
	fi
}

#
# clean_source_dir
#   cleans up a source directory - receives base dir + source dir
#
function clean_source_dir {
	SOURCEDIR=${1}
	BASEDIR=${2}
	if [ ${NOCLEANSOURCE} -eq 1 ] ; then
		echo "--no-clean-source set, not cleaning ${BASEDIR}/${SOURCEDIR}"
		return
	fi
	if [ -d ${BASEDIR}/${SOURCEDIR} ] ; then
		pushd . >/dev/null 2>&1
		echo "cleaning up ${BASEDIR}/${SOURCEDIR} for fresh compile"
		cd ${BASEDIR} || fail_and_exit "could not cd into ${BASEDIR}"
		rm -rf ${SOURCEDIR} || fail_and_exit "could not clean up ${BASEDIR}/${SOURCEDIR}"
		popd >/dev/null 2>&1
	fi
}

#
# extract_file
#   receives an extract command, a file and a directory
#
function extract_file {
	EXTRACTCMD=${1}
	EXTRACTFILE=${2}
	EXTRACTDIR=${3}
	SOURCEDIR=${4}
	if [ ${NOCLEANSOURCE} -eq 1 ] ; then
		if [ -d ${EXTRACTDIR}/${SOURCEDIR} ] ; then
			echo "--no-clean-source set, not extracting ${EXTRACTFILE}"
			return
		fi
	fi
	echo "extracting ${EXTRACTFILE} to ${EXTRACTDIR} with '${EXTRACTCMD}'"
	if [ ! -d ${EXTRACTDIR} ] ; then
		mkdir -p ${EXTRACTDIR} || fail_and_exit "could not create ${EXTRACTDIR}"
	fi
	pushd . >/dev/null 2>&1
	cd ${EXTRACTDIR} || fail_and_exit "could not cd into ${EXTRACTDIR}"
	${EXTRACTCMD} ${EXTRACTFILE} || fail_and_exit "could not extract ${EXTRACTFILE}"
	echo "successfully extracted ${EXTRACTFILE}"
	popd >/dev/null 2>&1
}

#
# configure_package
#   receives a configure command and a directory in which to run it.
#
function configure_package {
	CONFIGURECMD=${1}
	SOURCEDIR=${2}
	CONFIGUREDFILE="${SOURCEDIR}/.$(basename ${0})-configured"
	if [ ! -d ${SOURCEDIR} ] ; then
		fail_and_exit "could not find ${SOURCEDIR}"
	fi
	if [ ${NORECONFIGURE} -eq 1 ] ; then
		if [ -f ${CONFIGUREDFILE} ] ; then
			echo "--no-reconfigure set, not reconfiguring in ${SOURCEDIR}"
			return
		fi
	fi
	echo "running '${CONFIGURECMD}' in ${SOURCEDIR}"
	pushd . >/dev/null 2>&1
	cd ${SOURCEDIR} || fail_and_exit "source directory ${SOURCEDIR} does not seem to exist"
	${CONFIGURECMD} || fail_and_exit "could not run configure command '${CONFIGURECMD}' in ${SOURCEDIR}"
	touch ${CONFIGUREDFILE} || fail_and_exit "could not touch ${CONFIGUREDFILE}"
	echo "successfully ran configure in ${SOURCEDIR}"
	popd >/dev/null 2>&1
}

#
# build_package
#   receives a build command line and a directory
#
function build_package {
	BUILDCMD=${1}
	BUILDDIR=${2}
	BUILTFILE="${BUILDDIR}/.$(basename ${0})-built"
	if [ ! -d ${BUILDDIR} ] ; then
		fail_and_exit "${BUILDDIR} does not exist"
	fi
	if [ ${NOREBUILD} -eq 1 ] ; then
		if [ -f ${BUILTFILE} ] ; then
			echo "--no-rebuild set, not rebuilding in ${BUILDDIR}"
			return
		fi
	fi
	pushd . >/dev/null 2>&1
	cd ${BUILDDIR} || fail_and_exit "build directory ${BUILDDIR} does not seem to exist"
	${BUILDCMD} || fail_and_exit "could not run '${BUILDCMD}' in ${BUILDDIR}"
	touch ${BUILTFILE} || fail_and_exit "could not touch ${BUILTFILE}"
	echo "successfully ran '${BUILDCMD}' in ${BUILDDIR}"
	popd >/dev/null 2>&1
}

#
# install_package
#   receives an install command line and a directory to run it in
#
function install_package {
	INSTALLCMD=${1}
	INSTALLDIR=${2}
	if [ ! -d ${INSTALLDIR} ] ; then
		fail_and_exit "${INSTALLDIR} does not exist"
	fi
	echo "installing with '${INSTALLCMD}' in ${INSTALLDIR}"
	pushd . >/dev/null 2>&1
	cd ${INSTALLDIR} || fail_and_exit "directory ${INSTALLDIR} does not seem to exist"
	${INSTALLCMD}
	if [ $? != 0 ] ; then
		echo "some items may have failed to install! check above for errors."
	else
		echo "succesfully ran '${INSTALLCMD}' in ${INSTALLDIR}'"
	fi
	popd >/dev/null 2>&1
}

#
# package functions
#   common steps for (pretty much) each source build
#     clean
#     get
#     check
#     extract
#     configure
#     build
#     install
#

#
# pkg-config
#
PKGCONFIGVER="0.25"
PKGCONFIGFILE="pkg-config-${PKGCONFIGVER}.tar.gz"
PKGCONFIGURL="http://pkgconfig.freedesktop.org/releases/${PKGCONFIGFILE}"
PKGCONFIGSHA1SUM="8922aeb4edeff7ed554cc1969cbb4ad5a4e6b26e"
PKGCONFIGDIR="pkg-config-${PKGCONFIGVER}"
function clean_pkgconfig {
	clean_source_dir "${PKGCONFIGDIR}" "${WINEBUILDPATH}"
}
function get_pkgconfig {
	get_file "${PKGCONFIGFILE}" "${WINESOURCEPATH}" "${PKGCONFIGURL}"
}
function check_pkgconfig {
	check_sha1sum "${WINESOURCEPATH}/${PKGCONFIGFILE}" "${PKGCONFIGSHA1SUM}"
}
function extract_pkgconfig {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${PKGCONFIGFILE}" "${WINEBUILDPATH}" "${PKGCONFIGDIR}"
}
function configure_pkgconfig {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${PKGCONFIGDIR}"
}
function build_pkgconfig {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${PKGCONFIGDIR}"
}
function install_pkgconfig {
	clean_pkgconfig
	extract_pkgconfig
	configure_pkgconfig
	build_pkgconfig
	install_package "${MAKE} install" "${WINEBUILDPATH}/${PKGCONFIGDIR}"
}

#
# gettext
#
GETTEXTVER="0.18.1.1"
GETTEXTFILE="gettext-${GETTEXTVER}.tar.gz"
GETTEXTURL="http://ftp.gnu.org/pub/gnu/gettext/${GETTEXTFILE}"
GETTEXTSHA1SUM="5009deb02f67fc3c59c8ce6b82408d1d35d4e38f"
GETTEXTDIR="gettext-${GETTEXTVER}"
function clean_gettext {
	clean_source_dir "${GETTEXTDIR}" "${WINEBUILDPATH}"
}
function get_gettext {
	get_file "${GETTEXTFILE}" "${WINESOURCEPATH}" "${GETTEXTURL}"
}
function check_gettext {
	check_sha1sum "${WINESOURCEPATH}/${GETTEXTFILE}" "${GETTEXTSHA1SUM}"
}
function extract_gettext {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${GETTEXTFILE}" "${WINEBUILDPATH}" "${GETTEXTDIR}"
}
function configure_gettext {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --disable-java --disable-native-java --without-emacs --without-git" "${WINEBUILDPATH}/${GETTEXTDIR}"
}
function build_gettext {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${GETTEXTDIR}"
}
function install_gettext {
	clean_gettext
	extract_gettext
	configure_gettext
	build_gettext
	install_package "${MAKE} install" "${WINEBUILDPATH}/${GETTEXTDIR}"
}

#
# jpeg
#
JPEGVER="8b"
JPEGFILE="jpegsrc.v${JPEGVER}.tar.gz"
JPEGURL="http://www.ijg.org/files/${JPEGFILE}"
JPEGSHA1SUM="15dc1939ea1a5b9d09baea11cceb13ca59e4f9df"
JPEGDIR="jpeg-${JPEGVER}"
function clean_jpeg {
	clean_source_dir "${JPEGDIR}" "${WINEBUILDPATH}"
}
function get_jpeg {
	get_file "${JPEGFILE}" "${WINESOURCEPATH}" "${JPEGURL}"
}
function check_jpeg {
	check_sha1sum "${WINESOURCEPATH}/${JPEGFILE}" "${JPEGSHA1SUM}"
}
function extract_jpeg {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${JPEGFILE}" "${WINEBUILDPATH}" "${JPEGDIR}"
}
function configure_jpeg {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${JPEGDIR}"
}
function build_jpeg {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${JPEGDIR}"
}
function install_jpeg {
	clean_jpeg
	extract_jpeg
	configure_jpeg
	build_jpeg
	install_package "${MAKE} install" "${WINEBUILDPATH}/${JPEGDIR}"
}

#
# jbigkit
#
JBIGKITVER="2.0"
JBIGKITMAJOR=$(echo ${JBIGKITVER} | awk -F\. '{print $1}')
JBIGKITFILE="jbigkit-${JBIGKITVER}.tar.gz"
JBIGKITURL="http://www.cl.cam.ac.uk/~mgk25/download/${JBIGKITFILE}"
JBIGKITSHA1SUM="cfb7d3121f02a74bfb229217858a0d149b6589ef"
JBIGKITDIR="jbigkit"
function clean_jbigkit {
	clean_source_dir "${JBIGKITDIR}" "${WINEBUILDPATH}"
}
function get_jbigkit {
	get_file "${JBIGKITFILE}" "${WINESOURCEPATH}" "${JBIGKITURL}"
}
function check_jbigkit {
	check_sha1sum "${WINESOURCEPATH}/${JBIGKITFILE}" "${JBIGKITSHA1SUM}"
}
function extract_jbigkit {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${JBIGKITFILE}" "${WINEBUILDPATH}" "${JBIGKITDIR}"
}
function build_jbigkit {
	pushd . >/dev/null 2>&1
	echo "now building in ${WINEBUILDPATH}/${JBIGKITDIR}"
	cd ${WINEBUILDPATH}/${JBIGKITDIR}/libjbig || fail_and_exit "could not cd to the JBIG source directory"
	BUILTFILE="${WINEBUILDPATH}/${JBIGKITDIR}/.$(basename ${0})-built"
	if [ ${NOREBUILD} -eq 1 ] ; then
		if [ -f ${BUILTFILE} ] ; then
			echo "--no-rebuild set, not rebuilding in ${WINEBUILDPATH}/${JBIGKITDIR}/libjbig"
			return
		fi
	fi
	JBIGKITOBJS=""
	for JBIGKITSRC in jbig jbig_ar ; do
		rm -f ${JBIGKITSRC}.o
		echo "${CC} ${CFLAGS} -O2 -Wall -I. -dynamic -ansi -pedantic -c ${JBIGKITSRC}.c -o ${JBIGKITSRC}.o"
		${CC} ${CFLAGS} -O2 -Wall -I. -dynamic -ansi -pedantic -c ${JBIGKITSRC}.c -o ${JBIGKITSRC}.o || fail_and_exit "failed building jbigkit's ${JBIGKITSRC}.c"
		JBIGKITOBJS+="${JBIGKITSRC}.o "
	done
	echo "creating libjbig shared library with libtool"
	libtool -dynamic -v -o libjbig.${JBIGKITVER}.dylib -install_name ${WINELIBPATH}/libjbig.${JBIGKITVER}.dylib -compatibility_version ${JBIGKITVER} -current_version ${JBIGKITVER} -lc ${JBIGKITOBJS} || fail_and_exit "failed to build jbigkit shared library"
	touch ${BUILTFILE} || fail_and_exit "could not touch ${BUILTFILE}"
	popd >/dev/null 2>&1
}
function install_jbigkit {
	clean_jbigkit
	extract_jbigkit
	build_jbigkit
	pushd . >/dev/null 2>&1
	cd ${WINEBUILDPATH}/${JBIGKITDIR}/libjbig || fail_and_exit "could not cd to the JBIG source directory"
	echo "installing libjbig shared library and symbolic links"
	install -m 755 libjbig.${JBIGKITVER}.dylib ${WINELIBPATH}/libjbig.${JBIGKITVER}.dylib || fail_and_exit "could not install libjbig dynamic library"
	# XXX - remove manual cleanup? 'ln -Ffs' should manage this for us
	if [ ${NOCLEANPREFIX} -eq 1 ] ; then
		echo "--no-clean-prefix, manually removing libjbig symlinks"
		if [ -L ${WINELIBPATH}/libjbig.${JBIGKITMAJOR}.dylib ] ; then
			unlink ${WINELIBPATH}/libjbig.${JBIGKITMAJOR}.dylib || fail_and_exit "could not remove existing libjbig symbolic link"
		fi
		if [ -L ${WINELIBPATH}/libjbig.dylib ] ; then
			unlink ${WINELIBPATH}/libjbig.dylib || fail_and_exit "could not remove existing libjbig symbolic link"
		fi
	fi
	ln -Ffs libjbig.${JBIGKITVER}.dylib ${WINELIBPATH}/libjbig.${JBIGKITMAJOR}.dylib || fail_and_exit "could not create libjbig symlink"
	ln -Ffs libjbig.${JBIGKITVER}.dylib ${WINELIBPATH}/libjbig.dylib || fail_and_exit "could not create libjbig symlink"
	echo "installing libjbig header files"
	for JBIGKITHDR in jbig.h jbig_ar.h ; do
		install -m 644 ${JBIGKITHDR} ${WINEINCLUDEPATH}/${JBIGKITHDR} || fail_and_exit "could not install JBIG header ${JBIGKITHDR}"
	done
	popd >/dev/null 2>&1
}

#
# tiff
#
TIFFVER="3.9.4"
TIFFFILE="tiff-${TIFFVER}.tar.gz"
TIFFURL="http://download.osgeo.org/libtiff/${TIFFFILE}"
TIFFSHA1SUM="a4e32d55afbbcabd0391a9c89995e8e8a19961de"
TIFFDIR="tiff-${TIFFVER}"
function clean_tiff {
	clean_source_dir "${TIFFDIR}" "${WINEBUILDPATH}"
}
function get_tiff {
	get_file "${TIFFFILE}" "${WINESOURCEPATH}" "${TIFFURL}"
}
function check_tiff {
	check_sha1sum "${WINESOURCEPATH}/${TIFFFILE}" "${TIFFSHA1SUM}"
}
function extract_tiff {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${TIFFFILE}" "${WINEBUILDPATH}" "${TIFFDIR}"
}
function configure_tiff {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --with-jpeg-include-dir=${WINEINCLUDEPATH} --with-jbig-include-dir=${WINEINCLUDEPATH} --with-jpeg-lib-dir=${WINELIBPATH} --with-jbig-lib-dir=${WINELIBPATH} --with-apple-opengl-framework" "${WINEBUILDPATH}/${TIFFDIR}"
}
function build_tiff {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${TIFFDIR}"
}
function install_tiff {
	clean_tiff
	extract_tiff
	configure_tiff
	build_tiff
	install_package "${MAKE} install" "${WINEBUILDPATH}/${TIFFDIR}"
}

#
# libpng12
#
LIBPNG12VER="1.2.44"
LIBPNG12SHA1SUM="776bb8e42d86bd71ae58e0d96f85472c1d63beeb"
LIBPNG12FILE="libpng-${LIBPNG12VER}.tar.gz"
LIBPNG12URL="http://downloads.sourceforge.net/libpng/${LIBPNG12FILE}"
LIBPNG12DIR="libpng-${LIBPNG12VER}"
function clean_libpng12 {
	clean_source_dir "${LIBPNG12DIR}" "${WINEBUILDPATH}"
}
function get_libpng12 {
	get_file "${LIBPNG12FILE}" "${WINESOURCEPATH}" "${LIBPNG12URL}"
}
function check_libpng12 {
	check_sha1sum "${WINESOURCEPATH}/${LIBPNG12FILE}" "${LIBPNG12SHA1SUM}"
}
function extract_libpng12 {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${LIBPNG12FILE}" "${WINEBUILDPATH}" "${LIBPNG12DIR}"
}
function configure_libpng12 {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${LIBPNG12DIR}"
}
function build_libpng12 {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBPNG12DIR}"
}
function install_libpng12 {
	clean_libpng12
	extract_libpng12
	configure_libpng12
	build_libpng12
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBPNG12DIR}"
}

#
# libpng14
#
LIBPNG14VER="1.4.4"
LIBPNG14SHA1SUM="245490b22086a6aff8964b7d32383a17814d8ebf"
LIBPNG14FILE="libpng-${LIBPNG14VER}.tar.gz"
LIBPNG14URL="http://downloads.sourceforge.net/libpng/${LIBPNG14FILE}"
LIBPNG14DIR="libpng-${LIBPNG14VER}"
function clean_libpng14 {
	clean_source_dir "${LIBPNG14DIR}" "${WINEBUILDPATH}"
}
function get_libpng14 {
	get_file "${LIBPNG14FILE}" "${WINESOURCEPATH}" "${LIBPNG14URL}"
}
function check_libpng14 {
	check_sha1sum "${WINESOURCEPATH}/${LIBPNG14FILE}" "${LIBPNG14SHA1SUM}"
}
function extract_libpng14 {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${LIBPNG14FILE}" "${WINEBUILDPATH}" "${LIBPNG14DIR}"
}
function configure_libpng14 {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${LIBPNG14DIR}"
}
function build_libpng14 {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBPNG14DIR}"
}
function install_libpng14 {
	clean_libpng14
	extract_libpng14
	configure_libpng14
	build_libpng14
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBPNG14DIR}"
}

#
# libxml
#
LIBXML2VER="2.7.8"
LIBXML2FILE="libxml2-${LIBXML2VER}.tar.gz"
LIBXML2URL="ftp://xmlsoft.org/libxml2/${LIBXML2FILE}"
LIBXML2SHA1SUM="859dd535edbb851cc15b64740ee06551a7a17d40"
LIBXML2DIR="libxml2-${LIBXML2VER}"
function clean_libxml2 {
	clean_source_dir "${LIBXML2DIR}" "${WINEBUILDPATH}"
}
function get_libxml2 {
	get_file "${LIBXML2FILE}" "${WINESOURCEPATH}" "${LIBXML2URL}"
}
function check_libxml2 {
	check_sha1sum "${WINESOURCEPATH}/${LIBXML2FILE}" "${LIBXML2SHA1SUM}"
}
function extract_libxml2 {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${LIBXML2FILE}" "${WINEBUILDPATH}" "${LIBXML2DIR}"
}
function configure_libxml2 {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --without-python" "${WINEBUILDPATH}/${LIBXML2DIR}"
}
function build_libxml2 {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBXML2DIR}"
}
function install_libxml2 {
	clean_libxml2
	extract_libxml2
	configure_libxml2
	build_libxml2
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBXML2DIR}"
}

#
# libxslt
#
LIBXSLTVER="1.1.26"
LIBXSLTFILE="libxslt-${LIBXSLTVER}.tar.gz"
LIBXSLTURL="ftp://xmlsoft.org/libxml2/${LIBXSLTFILE}"
LIBXSLTSHA1SUM="69f74df8228b504a87e2b257c2d5238281c65154"
LIBXSLTDIR="libxslt-${LIBXSLTVER}"
function clean_libxslt {
	clean_source_dir "${LIBXSLTDIR}" "${WINEBUILDPATH}"
}
function get_libxslt {
	get_file "${LIBXSLTFILE}" "${WINESOURCEPATH}" "${LIBXSLTURL}"
}
function check_libxslt {
	check_sha1sum "${WINESOURCEPATH}/${LIBXSLTFILE}" "${LIBXSLTSHA1SUM}"
}
function extract_libxslt {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${LIBXSLTFILE}" "${WINEBUILDPATH}" "${LIBXSLTDIR}"
}
function configure_libxslt {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --with-libxml-prefix=${WINEINSTALLPATH} --without-crypto --without-python" "${WINEBUILDPATH}/${LIBXSLTDIR}"
}
function build_libxslt {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBXSLTDIR}"
}
function install_libxslt {
	clean_libxslt
	extract_libxslt
	configure_libxslt
	build_libxslt
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBXSLTDIR}"
}

#
# glib
#
GLIBBASEVER="2.26"
GLIBVER="${GLIBBASEVER}.1"
GLIBFILE="glib-${GLIBVER}.tar.bz2"
GLIBURL="ftp://ftp.gtk.org/pub/glib/${GLIBBASEVER}/${GLIBFILE}"
GLIBSHA1SUM="8d35d5cf41d681dd6480a16be39f7d3cffbd29f0"
GLIBDIR="glib-${GLIBVER}"
function clean_glib {
	clean_source_dir "${GLIBDIR}" "${WINEBUILDPATH}"
}
function get_glib {
	get_file "${GLIBFILE}" "${WINESOURCEPATH}" "${GLIBURL}"
}
function check_glib {
	check_sha1sum "${WINESOURCEPATH}/${GLIBFILE}" "${GLIBSHA1SUM}"
}
function extract_glib {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${GLIBFILE}" "${WINEBUILDPATH}" "${GLIBDIR}"
}
function configure_glib {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${GLIBDIR}"
}
function build_glib {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${GLIBDIR}"
}
function install_glib {
	clean_glib
	extract_glib
	configure_glib
	build_glib
	install_package "${MAKE} install" "${WINEBUILDPATH}/${GLIBDIR}"
}


#
# mpg123
#
MPG123VER="1.12.5"
MPG123FILE="mpg123-${MPG123VER}.tar.bz2"
MPG123URL="http://downloads.sourceforge.net/mpg123/${MPG123FILE}"
MPG123SHA1SUM="476cb47a9b6570684b5af536beedf2026522e5f8"
MPG123DIR="mpg123-${MPG123VER}"
function clean_mpg123 {
	clean_source_dir "${MPG123DIR}" "${WINEBUILDPATH}"
}
function get_mpg123 {
	get_file "${MPG123FILE}" "${WINESOURCEPATH}" "${MPG123URL}"
}
function check_mpg123 {
	check_sha1sum "${WINESOURCEPATH}/${MPG123FILE}" "${MPG123SHA1SUM}"
}
function extract_mpg123 {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${MPG123FILE}" "${WINEBUILDPATH}" "${MPG123DIR}"
}
function configure_mpg123 {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --with-cpu=x86" "${WINEBUILDPATH}/${MPG123DIR}"
}
function build_mpg123 {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${MPG123DIR}"
}
function install_mpg123 {
	export PRECC=${CC}
	export CC="${CC} -read_only_relocs suppress ${CFLAGS}"
	clean_mpg123
	extract_mpg123
	configure_mpg123
	build_mpg123
	install_package "${MAKE} install" "${WINEBUILDPATH}/${MPG123DIR}"
	export CC=${PRECC}
}

#
# gsm
#
GSMVER="1.0"
GSMMAJOR=$(echo ${GSMVER} | awk -F\. '{print $1}')
GSMPL="13"
GSMFILE="gsm-${GSMVER}.${GSMPL}.tar.gz"
GSMURL="http://osxwinebuilder.googlecode.com/files/${GSMFILE}"
GSMSHA1SUM="668b0a180039a50d379b3d5a22e78da4b1d90afc"
GSMDIR="gsm-${GSMVER}-pl${GSMPL}"
function clean_gsm {
	clean_source_dir "${GSMDIR}" "${WINEBUILDPATH}"
}
function get_gsm {
	get_file "${GSMFILE}" "${WINESOURCEPATH}" "${GSMURL}"
}
function check_gsm {
	check_sha1sum "${WINESOURCEPATH}/${GSMFILE}" "${GSMSHA1SUM}"
}
function extract_gsm {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${GSMFILE}" "${WINEBUILDPATH}" "${GSMDIR}"
}
function build_gsm {
	pushd . >/dev/null 2>&1
	cd ${WINEBUILDPATH}/${GSMDIR} || fail_and_exit "could not cd to the GSM source directory"
	BUILTFILE="${WINEBUILDPATH}/${GSMDIR}/.$(basename ${0})-built"
	if [ ${NOREBUILD} -eq 1 ] ; then
		if [ -f ${BUILTFILE} ] ; then
			echo "--no-rebuild set, not rebuilding in ${WINEBUILDPATH}/${GSMDIR}"
			return
		fi
	fi
	GSMOBJS=""
	for GSMSRC in add code debug decode long_term lpc preprocess rpe gsm_destroy gsm_decode gsm_encode gsm_explode gsm_implode gsm_create gsm_print gsm_option short_term table ; do
		rm -f src/${GSMSRC}.o
		GSMCC="${CC} ${CFLAGS} -dynamic -ansi -pedantic -c -O2 -Wall -DNeedFunctionPrototypes=1 -DSASR -DWAV49 -I./inc"
		echo "${GSMCC} src/${GSMSRC}.c -o src/${GSMSRC}.o"
		${GSMCC} src/${GSMSRC}.c -o src/${GSMSRC}.o || fail_and_exit "failed compiling GSM source file ${GSMSRC}.c"
		GSMOBJS+="src/${GSMSRC}.o "
	done
	rm -f lib/libgsm.${GSMVER}.${GSMPL}.dylib
	echo "creating libgsm dynamic library"
	libtool -dynamic -v -o lib/libgsm.${GSMVER}.${GSMPL}.dylib -install_name ${WINELIBPATH}/libgsm.${GSMVER}.${GSMPL}.dylib -compatibility_version ${GSMVER}.${GSMPL} -current_version ${GSMVER}.${GSMPL} -lc ${GSMOBJS} || fail_and_exit "failed creating GSM shared library"
	touch ${BUILTFILE} || fail_and_exit "could not touch ${BUILTFILE}"
	popd >/dev/null 2>&1
}
function install_gsm {
	clean_gsm
	extract_gsm
	build_gsm
	pushd . >/dev/null 2>&1
	cd ${WINEBUILDPATH}/${GSMDIR} || fail_and_exit "could not cd to the GSM source directory"
	echo "installing libgsm shared library and symbolic links"
	install -m 755 lib/libgsm.${GSMVER}.${GSMPL}.dylib ${WINELIBPATH}/libgsm.${GSMVER}.${GSMPL}.dylib || fail_and_exit "could not install the libgsm dynamic library"
	# XXX - remove manual cleanup? 'ln -Ffs' should manage this for us
	if [ ${NOCLEANPREFIX} -eq 1 ] ; then
		echo "--no-clean-prefix, manually removing libgsm symlinks"
		if [ -L ${WINELIBPATH}/libgsm.${GSMMAJOR}.dylib ] ; then
			unlink ${WINELIBPATH}/libgsm.${GSMMAJOR}.dylib || fail_and_exit "could not remove existing libgsm symbolic link"
		fi
		if [ -L ${WINELIBPATH}/libgsm.dylib ] ; then
			unlink ${WINELIBPATH}/libgsm.dylib || fail_and_exit "could not remove existing libgsm symbolic link"
		fi
	fi
	ln -Ffs libgsm.${GSMVER}.${GSMPL}.dylib ${WINELIBPATH}/libgsm.${GSMMAJOR}.dylib || fail_and_exit "could not create a libgsm symbolic link"
	ln -Ffs libgsm.${GSMVER}.${GSMPL}.dylib ${WINELIBPATH}/libgsm.dylib || fail_and_exit "could not create a libgsm symbolic link"
	echo "installing libgsm header file"
	install -m 644 inc/gsm.h ${WINEINCLUDEPATH}/gsm.h || fail_and_exit "could not install the GSM gsm.h header file"
	popd >/dev/null 2>&1
}

#
# freetype
#
FREETYPEVER="2.4.3"
FREETYPEFILE="freetype-${FREETYPEVER}.tar.bz2"
FREETYPEURL="http://downloads.sourceforge.net/freetype/freetype2/${FREETYPEFILE}"
FREETYPESHA1SUM="16e5ba0ff23b2de372149a790b7245a762022912"
FREETYPEDIR="freetype-${FREETYPEVER}"
function clean_freetype {
	clean_source_dir "${FREETYPEDIR}" "${WINEBUILDPATH}"
}
function get_freetype {
	get_file "${FREETYPEFILE}" "${WINESOURCEPATH}" "${FREETYPEURL}"
}
function check_freetype {
	check_sha1sum "${WINESOURCEPATH}/${FREETYPEFILE}" "${FREETYPESHA1SUM}"
}
function extract_freetype {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${FREETYPEFILE}" "${WINEBUILDPATH}" "${FREETYPEDIR}"
}
function configure_freetype {
	# set subpixel rendering flag
	export FT_CONFIG_OPTION_SUBPIXEL_RENDERING=1
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${FREETYPEDIR}"
	echo "attempting to enable FreeType's subpixel rendering and bytecode interpretter in ${WINEBUILDPATH}/${FREETYPEDIR}"
	pushd . >/dev/null 2>&1
	cd ${WINEBUILDPATH}/${FREETYPEDIR} || fail_and_exit "could not cd to ${FREETYPEDIR} for patching"
	if [ ! -f include/freetype/config/ftoption.h.bytecode_interpreter ] ; then
		sed -i.bytecode_interpreter \
			's#/\* \#define TT_CONFIG_OPTION_BYTECODE_INTERPRETER \*/#\#define TT_CONFIG_OPTION_BYTECODE_INTERPRETER#g' \
			include/freetype/config/ftoption.h || fail_and_exit "could not conifgure TT_CONFIG_OPTION_BYTECODE_INTERPRETER for freetype"
	fi
	if [ ! -f include/freetype/config/ftoption.h.subpixel_rendering ] ; then
		sed -i.subpixel_rendering \
			's#/\* \#define FT_CONFIG_OPTION_SUBPIXEL_RENDERING \*/#\#define FT_CONFIG_OPTION_SUBPIXEL_RENDERING#g' \
			include/freetype/config/ftoption.h || fail_and_exit "could not conifgure FT_CONFIG_OPTION_SUBPIXEL_RENDERING for freetype"
	fi
	echo "successfully configured and patched FreeType in ${WINEBUILDPATH}/${FREETYPEDIR}"
	popd >/dev/null 2>&1
}
function build_freetype {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${FREETYPEDIR}"
}
function install_freetype {
	export PRECC=${CC}
	export CC="${CC} ${CFLAGS}"
	clean_freetype
	extract_freetype
	configure_freetype
	build_freetype
	install_package "${MAKE} install" "${WINEBUILDPATH}/${FREETYPEDIR}"
	export CC=${PRECC}
}

#
# fontconfig
#
FONTCONFIGVER="2.8.0"
FONTCONFIGFILE="fontconfig-${FONTCONFIGVER}.tar.gz"
FONTCONFIGURL="http://fontconfig.org/release/${FONTCONFIGFILE}"
FONTCONFIGSHA1SUM="570fb55eb14f2c92a7b470b941e9d35dbfafa716"
FONTCONFIGDIR="fontconfig-${FONTCONFIGVER}"
function clean_fontconfig {
	clean_source_dir "${FONTCONFIGDIR}" "${WINEBUILDPATH}"
}
function get_fontconfig {
	get_file "${FONTCONFIGFILE}" "${WINESOURCEPATH}" "${FONTCONFIGURL}"
}
function check_fontconfig {
	check_sha1sum "${WINESOURCEPATH}/${FONTCONFIGFILE}" "${FONTCONFIGSHA1SUM}"
}
function extract_fontconfig {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${FONTCONFIGFILE}" "${WINEBUILDPATH}" "${FONTCONFIGDIR}"
}
function configure_fontconfig {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --with-default-fonts=${X11LIB}/X11/fonts --with-confdir=${WINELIBPATH}/fontconfig --with-cache-dir=${X11DIR}/var/cache/fontconfig" "${WINEBUILDPATH}/${FONTCONFIGDIR}"
}
function build_fontconfig {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${FONTCONFIGDIR}"
}
function install_fontconfig {
	clean_fontconfig
	extract_fontconfig
	configure_fontconfig
	build_fontconfig
	install_package "${MAKE} install" "${WINEBUILDPATH}/${FONTCONFIGDIR}"
}

#
# lcms
#
LCMSVER="1.19"
LCMSFILE="lcms-${LCMSVER}.tar.gz"
LCMSURL="http://downloads.sourceforge.net/lcms/${LCMSFILE}"
LCMSSHA1SUM="d5b075ccffc0068015f74f78e4bc39138bcfe2d4"
LCMSDIR="lcms-${LCMSVER}"
function clean_lcms {
	clean_source_dir "${LCMSDIR}" "${WINEBUILDPATH}"
}
function get_lcms {
	get_file "${LCMSFILE}" "${WINESOURCEPATH}" "${LCMSURL}"
}
function check_lcms {
	check_sha1sum "${WINESOURCEPATH}/${LCMSFILE}" "${LCMSSHA1SUM}"
}
function extract_lcms {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${LCMSFILE}" "${WINEBUILDPATH}" "${LCMSDIR}"
}
function configure_lcms {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --without-python --with-jpeg --with-tiff --with-zlib" "${WINEBUILDPATH}/${LCMSDIR}"
}
function build_lcms {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LCMSDIR}"
}
function install_lcms {
	clean_lcms
	extract_lcms
	configure_lcms
	build_lcms
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LCMSDIR}"
}

#
# lzo
#
LZOVER="2.04"
LZOFILE="lzo-${LZOVER}.tar.gz"
LZOURL="http://www.oberhumer.com/opensource/lzo/download/${LZOFILE}"
LZOSHA1SUM="f5bf5c7ae4116e60513e5788d156ef78946677e7"
LZODIR="lzo-${LZOVER}"
function clean_lzo {
	clean_source_dir "${LZODIR}" "${WINEBUILDPATH}"
}
function get_lzo {
	get_file "${LZOFILE}" "${WINESOURCEPATH}" "${LZOURL}"
}
function check_lzo {
	check_sha1sum "${WINESOURCEPATH}/${LZOFILE}" "${LZOSHA1SUM}"
}
function extract_lzo {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${LZOFILE}" "${WINEBUILDPATH}" "${LZODIR}"
}
function configure_lzo {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --disable-asm" "${WINEBUILDPATH}/${LZODIR}"
}
function build_lzo {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LZODIR}"
}
function install_lzo {
	export PRECC=${CC}
	export CC="${CC} ${CFLAGS}"
	clean_lzo
	extract_lzo
	configure_lzo
	build_lzo
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LZODIR}"
	export CC=${PRECC}
}

#
# libgpg-error
#
LIBGPGERRORVER="1.10"
LIBGPGERRORFILE="libgpg-error-${LIBGPGERRORVER}.tar.bz2"
LIBGPGERRORURL="ftp://ftp.gnupg.org/gcrypt/libgpg-error/${LIBGPGERRORFILE}"
LIBGPGERRORSHA1SUM="95b324359627fbcb762487ab6091afbe59823b29"
LIBGPGERRORDIR="libgpg-error-${LIBGPGERRORVER}"
function clean_libgpgerror {
	clean_source_dir "${LIBGPGERRORDIR}" "${WINEBUILDPATH}"
}
function get_libgpgerror {
	get_file "${LIBGPGERRORFILE}" "${WINESOURCEPATH}" "${LIBGPGERRORURL}"
}
function check_libgpgerror {
	check_sha1sum "${WINESOURCEPATH}/${LIBGPGERRORFILE}" "${LIBGPGERRORSHA1SUM}"
}
function extract_libgpgerror {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${LIBGPGERRORFILE}" "${WINEBUILDPATH}" "${LIBGPGERRORDIR}"
}
function configure_libgpgerror {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${LIBGPGERRORDIR}"
}
function build_libgpgerror {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBGPGERRORDIR}"
}
function install_libgpgerror {
	clean_libgpgerror
	extract_libgpgerror
	configure_libgpgerror
	build_libgpgerror
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBGPGERRORDIR}"
}

#
# libgcrypt
#
LIBGCRYPTVER="1.4.6"
LIBGCRYPTFILE="libgcrypt-${LIBGCRYPTVER}.tar.bz2"
LIBGCRYPTURL="ftp://ftp.gnupg.org/gcrypt/libgcrypt/${LIBGCRYPTFILE}"
LIBGCRYPTSHA1SUM="445b9e158aaf91e24eae3d1040c6213e9d9f5ba6"
LIBGCRYPTDIR="libgcrypt-${LIBGCRYPTVER}"
function clean_libgcrypt {
	clean_source_dir "${LIBGCRYPTDIR}" "${WINEBUILDPATH}"
}
function get_libgcrypt {
	get_file "${LIBGCRYPTFILE}" "${WINESOURCEPATH}" "${LIBGCRYPTURL}"
}
function check_libgcrypt {
	check_sha1sum "${WINESOURCEPATH}/${LIBGCRYPTFILE}" "${LIBGCRYPTSHA1SUM}"
}
function extract_libgcrypt {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${LIBGCRYPTFILE}" "${WINEBUILDPATH}" "${LIBGCRYPTDIR}"
}
function configure_libgcrypt {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --with-gpg-error-prefix=${WINEINSTALLPATH}" "${WINEBUILDPATH}/${LIBGCRYPTDIR}"
}
function build_libgcrypt {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBGCRYPTDIR}"
}
function install_libgcrypt {
	clean_libgcrypt
	extract_libgcrypt
	configure_libgcrypt
	build_libgcrypt
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBGCRYPTDIR}"
}

#
# gnutls
#
GNUTLSVER="2.10.3"
GNUTLSFILE="gnutls-${GNUTLSVER}.tar.bz2"
GNUTLSURL="ftp://ftp.gnu.org/pub/gnu/gnutls/${GNUTLSFILE}"
GNUTLSSHA1SUM="b17b23d462ecf829f3b9aff3248d25d4979ebe4f"
GNUTLSDIR="gnutls-${GNUTLSVER}"
function clean_gnutls {
	clean_source_dir "${GNUTLSDIR}" "${WINEBUILDPATH}"
}
function get_gnutls {
	get_file "${GNUTLSFILE}" "${WINESOURCEPATH}" "${GNUTLSURL}"
}
function check_gnutls {
	check_sha1sum "${WINESOURCEPATH}/${GNUTLSFILE}" "${GNUTLSSHA1SUM}"
}
function extract_gnutls {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${GNUTLSFILE}" "${WINEBUILDPATH}" "${GNUTLSDIR}"
}
function configure_gnutls {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --with-libgcrypt-prefix=${WINEINSTALLPATH} --with-included-libcfg --with-included-libtasn1 --with-lzo" "${WINEBUILDPATH}/${GNUTLSDIR}"
}
function build_gnutls {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${GNUTLSDIR}"
}
function install_gnutls {
	clean_gnutls
	extract_gnutls
	configure_gnutls
	build_gnutls
	install_package "${MAKE} install" "${WINEBUILDPATH}/${GNUTLSDIR}"
}

#
# unixodbc
#
UNIXODBCVER="2.3.0"
UNIXODBCFILE="unixODBC-${UNIXODBCVER}.tar.gz"
UNIXODBCURL="http://www.unixodbc.org/${UNIXODBCFILE}"
UNIXODBCSHA1SUM="b2839b5210906e3ee286a4b621f177db9c7be7a8"
UNIXODBCDIR="unixODBC-${UNIXODBCVER}"
function clean_unixodbc {
	clean_source_dir "${UNIXODBCDIR}" "${WINEBUILDPATH}"
}
function get_unixodbc {
	get_file "${UNIXODBCFILE}" "${WINESOURCEPATH}" "${UNIXODBCURL}"
}
function check_unixodbc {
	check_sha1sum "${WINESOURCEPATH}/${UNIXODBCFILE}" "${UNIXODBCSHA1SUM}"
}
function extract_unixodbc {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${UNIXODBCFILE}" "${WINEBUILDPATH}" "${UNIXODBCDIR}"
}
function configure_unixodbc {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --enable-gui=no" "${WINEBUILDPATH}/${UNIXODBCDIR}"
}
function build_unixodbc {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${UNIXODBCDIR}"
}
function install_unixodbc {
	clean_unixodbc
	extract_unixodbc
	configure_unixodbc
	build_unixodbc
	install_package "${MAKE} install" "${WINEBUILDPATH}/${UNIXODBCDIR}"
}

#
# libexif
#
LIBEXIFVER="0.6.19"
LIBEXIFFILE="libexif-${LIBEXIFVER}.tar.bz2"
LIBEXIFURL="http://downloads.sourceforge.net/libexif/${LIBEXIFFILE}"
LIBEXIFSHA1SUM="820f07ff12a8cc720a6597d46277f01498c8aba4"
LIBEXIFDIR="libexif-${LIBEXIFVER}"
function clean_libexif {
	clean_source_dir "${LIBEXIFDIR}" "${WINEBUILDPATH}"
}
function get_libexif {
	get_file "${LIBEXIFFILE}" "${WINESOURCEPATH}" "${LIBEXIFURL}"
}
function check_libexif {
	check_sha1sum "${WINESOURCEPATH}/${LIBEXIFFILE}" "${LIBEXIFSHA1SUM}"
}
function extract_libexif {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${LIBEXIFFILE}" "${WINEBUILDPATH}" "${LIBEXIFDIR}"
}
function configure_libexif {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${LIBEXIFDIR}"
}
function build_libexif {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBEXIFDIR}"
}
function install_libexif {
	clean_libexif
	extract_libexif
	configure_libexif
	build_libexif
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBEXIFDIR}"
}

#
# libusb
#
LIBUSBVER="1.0.8"
LIBUSBFILE="libusb-${LIBUSBVER}.tar.bz2"
LIBUSBURL="http://downloads.sourceforge.net/libusb/${LIBUSBFILE}"
LIBUSBSHA1SUM="5484397860f709c9b51611d224819f8ed5994063"
LIBUSBDIR="libusb-${LIBUSBVER}"
function clean_libusb {
	clean_source_dir "${LIBUSBDIR}" "${WINEBUILDPATH}"
}
function get_libusb {
	get_file "${LIBUSBFILE}" "${WINESOURCEPATH}" "${LIBUSBURL}"
}
function check_libusb {
	check_sha1sum "${WINESOURCEPATH}/${LIBUSBFILE}" "${LIBUSBSHA1SUM}"
}
function extract_libusb {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${LIBUSBFILE}" "${WINEBUILDPATH}" "${LIBUSBDIR}"
}
function configure_libusb {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${LIBUSBDIR}"
}
function build_libusb {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBUSBDIR}"
}
function install_libusb {
	clean_libusb
	extract_libusb
	configure_libusb
	build_libusb
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBUSBDIR}"
}

#
# libusb-compat
#
LIBUSBCOMPATVER="0.1.3"
LIBUSBCOMPATFILE="libusb-compat-${LIBUSBCOMPATVER}.tar.bz2"
LIBUSBCOMPATURL="http://downloads.sourceforge.net/libusb/${LIBUSBCOMPATFILE}"
LIBUSBCOMPATSHA1SUM="d5710d5bc4b67c5344e779475b76168c7ccc5e69"
LIBUSBCOMPATDIR="libusb-compat-${LIBUSBCOMPATVER}"
function clean_libusbcompat {
	clean_source_dir "${LIBUSBCOMPATDIR}" "${WINEBUILDPATH}"
}
function get_libusbcompat {
	get_file "${LIBUSBCOMPATFILE}" "${WINESOURCEPATH}" "${LIBUSBCOMPATURL}"
}
function check_libusbcompat {
	check_sha1sum "${WINESOURCEPATH}/${LIBUSBCOMPATFILE}" "${LIBUSBCOMPATSHA1SUM}"
}
function extract_libusbcompat {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${LIBUSBCOMPATFILE}" "${WINEBUILDPATH}" "${LIBUSBCOMPATDIR}"
}
function configure_libusbcompat {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${LIBUSBCOMPATDIR}"
}
function build_libusbcompat {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBUSBCOMPATDIR}"
}
function install_libusbcompat {
	clean_libusbcompat
	extract_libusbcompat
	configure_libusbcompat
	build_libusbcompat
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBUSBCOMPATDIR}"
}

#
# gd
#
GDVER="2.0.36RC1"
GDFILE="gd-${GDVER}.tar.bz2"
GDURL="http://www.libgd.org/releases/${GDFILE}"
GDSHA1SUM="415300e288348ed0d806fa2f3b7815604d8b5eec"
GDDIR="gd-${GDVER}"
function clean_gd {
	clean_source_dir "${GDDIR}" "${WINEBUILDPATH}"
}
function get_gd {
	get_file "${GDFILE}" "${WINESOURCEPATH}" "${GDURL}"
}
function check_gd {
	check_sha1sum "${WINESOURCEPATH}/${GDFILE}" "${GDSHA1SUM}"
}
function extract_gd {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${GDFILE}" "${WINEBUILDPATH}" "${GDDIR}"
}
function configure_gd {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} --with-png=${WINEINSTALLPATH} --with-freetype=${WINEINSTALLPATH} --with-fontconfig=${WINEINSTALLPATH} --with-jpeg=${WINEINSTALLPATH}" "${WINEBUILDPATH}/${GDDIR}"
}
function build_gd {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${GDDIR}"
}
function install_gd {
	clean_gd
	extract_gd
	configure_gd
	build_gd
	install_package "${MAKE} install" "${WINEBUILDPATH}/${GDDIR}"
}

#
# libgphoto2
#
LIBGPHOTO2VER="2.4.10.1"
LIBGPHOTO2FILE="libgphoto2-${LIBGPHOTO2VER}.tar.bz2"
LIBGPHOTO2URL="http://downloads.sourceforge.net/gphoto/libgphoto/${LIBGPHOTO2FILE}"
LIBGPHOTO2SHA1SUM="2806b147d3cf2c3cfdcb5cb8db8b82c1180d5f36"
LIBGPHOTO2DIR="libgphoto2-${LIBGPHOTO2VER}"
function clean_libgphoto2 {
	clean_source_dir "${LIBGPHOTO2DIR}" "${WINEBUILDPATH}"
}
function get_libgphoto2 {
	get_file "${LIBGPHOTO2FILE}" "${WINESOURCEPATH}" "${LIBGPHOTO2URL}"
}
function check_libgphoto2 {
	check_sha1sum "${WINESOURCEPATH}/${LIBGPHOTO2FILE}" "${LIBGPHOTO2SHA1SUM}"
}
function extract_libgphoto2 {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${LIBGPHOTO2FILE}" "${WINEBUILDPATH}" "${LIBGPHOTO2DIR}"
}
function configure_libgphoto2 {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --with-libexif=auto" "${WINEBUILDPATH}/${LIBGPHOTO2DIR}"
}
function build_libgphoto2 {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBGPHOTO2DIR}"
}
function install_libgphoto2 {
	clean_libgphoto2
	extract_libgphoto2
	configure_libgphoto2
	build_libgphoto2
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBGPHOTO2DIR}"
}

#
# sane-backends
#
SANEBACKENDSVER="1.0.21"
SANEBACKENDSFILE="sane-backends-${SANEBACKENDSVER}.tar.gz"
SANEBACKENDSURL="ftp://ftp.sane-project.org/pub/sane/sane-backends-${SANEBACKENDSVER}/${SANEBACKENDSFILE}"
SANEBACKENDSSHA1SUM="4a2789ea9dae1ece090d016abd14b0f2450d9bdb"
SANEBACKENDSDIR="sane-backends-${SANEBACKENDSVER}"
function clean_sanebackends {
	clean_source_dir "${SANEBACKENDSDIR}" "${WINEBUILDPATH}"
}
function get_sanebackends {
	get_file "${SANEBACKENDSFILE}" "${WINESOURCEPATH}" "${SANEBACKENDSURL}"
}
function check_sanebackends {
	check_sha1sum "${WINESOURCEPATH}/${SANEBACKENDSFILE}" "${SANEBACKENDSSHA1SUM}"
}
function extract_sanebackends {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${SANEBACKENDSFILE}" "${WINEBUILDPATH}" "${SANEBACKENDSDIR}"
}
function configure_sanebackends {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --with-gphoto2 --enable-libusb_1_0" "${WINEBUILDPATH}/${SANEBACKENDSDIR}"
}
function build_sanebackends {
	# 'make -j#' fails for #>1 on OS X <10.6/sane-backends 1.0.21.
	if [ ${DARWINMAJ} -lt 10 ] ; then
		build_package "${MAKE}" "${WINEBUILDPATH}/${SANEBACKENDSDIR}"
	else
		build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${SANEBACKENDSDIR}"
	fi
}
function install_sanebackends {
	clean_sanebackends
	extract_sanebackends
	configure_sanebackends
	build_sanebackends
	install_package "${MAKE} install" "${WINEBUILDPATH}/${SANEBACKENDSDIR}"
}

#
# jasper
#
JASPERVER="1.900.1"
JASPERFILE="jasper-${JASPERVER}.zip"
JASPERURL="http://www.ece.uvic.ca/~mdadams/jasper/software/${JASPERFILE}"
JASPERSHA1SUM="9c5735f773922e580bf98c7c7dfda9bbed4c5191"
JASPERDIR="jasper-${JASPERVER}"
function clean_jasper {
	clean_source_dir "${JASPERDIR}" "${WINEBUILDPATH}"
}
function get_jasper {
	get_file "${JASPERFILE}" "${WINESOURCEPATH}" "${JASPERURL}"
}
function check_jasper {
	check_sha1sum "${WINESOURCEPATH}/${JASPERFILE}" "${JASPERSHA1SUM}"
}
function extract_jasper {
	extract_file "unzip" "${WINESOURCEPATH}/${JASPERFILE}" "${WINEBUILDPATH}" "${JASPERDIR}"
}
function configure_jasper {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${JASPERDIR}"
}
function build_jasper {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${JASPERDIR}"
}
function install_jasper {
	clean_jasper
	extract_jasper
	configure_jasper
	build_jasper
	install_package "${MAKE} install" "${WINEBUILDPATH}/${JASPERDIR}"
}

#
# libicns
#
LIBICNSVER="0.7.1"
LIBICNSFILE="libicns-${LIBICNSVER}.tar.gz"
LIBICNSURL="http://downloads.sourceforge.net/icns/${LIBICNSFILE}"
LIBICNSSHA1SUM="e12a6ca21988929d56320ac1b96a1a059af0fd43"
LIBICNSDIR="libicns-${LIBICNSVER}"
function clean_libicns {
	clean_source_dir "${LIBICNSDIR}" "${WINEBUILDPATH}"
}
function get_libicns {
	get_file "${LIBICNSFILE}" "${WINESOURCEPATH}" "${LIBICNSURL}"
}
function check_libicns {
	check_sha1sum "${WINESOURCEPATH}/${LIBICNSFILE}" "${LIBICNSSHA1SUM}"
}
function extract_libicns {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${LIBICNSFILE}" "${WINEBUILDPATH}" "${LIBICNSDIR}"
}
function configure_libicns {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${LIBICNSDIR}"
}
function build_libicns {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBICNSDIR}"
}
function install_libicns {
	clean_libicns
	extract_libicns
	configure_libicns
	build_libicns
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBICNSDIR}"
}

#
# orc
#
ORCVER="0.4.11"
ORCFILE="orc-${ORCVER}.tar.gz"
ORCURL="http://code.entropywave.com/download/orc/${ORCFILE}"
ORCSHA1SUM="e99f684fc551c2bb3a5cdefe6fa5165174508a5f"
ORCDIR="orc-${ORCVER}"
function clean_orc {
	clean_source_dir "${ORCDIR}" "${WINEBUILDPATH}"
}
function get_orc {
	get_file "${ORCFILE}" "${WINESOURCEPATH}" "${ORCURL}"
}
function check_orc {
	check_sha1sum "${WINESOURCEPATH}/${ORCFILE}" "${ORCSHA1SUM}"
}
function extract_orc {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${ORCFILE}" "${WINEBUILDPATH}" "${ORCDIR}"
}
function configure_orc {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${ORCDIR}"
}
function build_orc {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${ORCDIR}"
}
function install_orc {
	# XXX - -O2 opt breaks compile
	PRECFLAGS=${CFLAGS}
	export CFLAGS=$(echo ${CFLAGS} | sed s#-O2##g)
	clean_orc
	extract_orc
	configure_orc
	build_orc
	install_package "${MAKE} install" "${WINEBUILDPATH}/${ORCDIR}"
	export CFLAGS=${PRECFLAGS}
}

#
# libogg
#
LIBOGGVER="1.2.0"
LIBOGGFILE="libogg-${LIBOGGVER}.tar.gz"
LIBOGGURL="http://downloads.xiph.org/releases/ogg/${LIBOGGFILE}"
LIBOGGSHA1SUM="135fb812282e08833295c91e005bd0258fff9098"
LIBOGGDIR="libogg-${LIBOGGVER}"
function clean_libogg {
	clean_source_dir "${LIBOGGDIR}" "${WINEBUILDPATH}"
}
function get_libogg {
	get_file "${LIBOGGFILE}" "${WINESOURCEPATH}" "${LIBOGGURL}"
}
function check_libogg {
	check_sha1sum "${WINESOURCEPATH}/${LIBOGGFILE}" "${LIBOGGSHA1SUM}"
}
function extract_libogg {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${LIBOGGFILE}" "${WINEBUILDPATH}" "${LIBOGGDIR}"
}
function configure_libogg {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${LIBOGGDIR}"
}
function build_libogg {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBOGGDIR}"
}
function install_libogg {
	clean_libogg
	extract_libogg
	configure_libogg
	build_libogg
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBOGGDIR}"
}

#
# libvorbis
#
LIBVORBISVER="1.3.2"
LIBVORBISFILE="libvorbis-${LIBVORBISVER}.tar.bz2"
LIBVORBISURL="http://downloads.xiph.org/releases/vorbis/${LIBVORBISFILE}"
LIBVORBISSHA1SUM="4c44da8215d1fc56676fccc1af8dd6b422d9e676"
LIBVORBISDIR="libvorbis-${LIBVORBISVER}"
function clean_libvorbis {
	clean_source_dir "${LIBVORBISDIR}" "${WINEBUILDPATH}"
}
function get_libvorbis {
	get_file "${LIBVORBISFILE}" "${WINESOURCEPATH}" "${LIBVORBISURL}"
}
function check_libvorbis {
	check_sha1sum "${WINESOURCEPATH}/${LIBVORBISFILE}" "${LIBVORBISSHA1SUM}"
}
function extract_libvorbis {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${LIBVORBISFILE}" "${WINEBUILDPATH}" "${LIBVORBISDIR}"
}
function configure_libvorbis {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${LIBVORBISDIR}"
}
function build_libvorbis {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBVORBISDIR}"
}
function install_libvorbis {
	clean_libvorbis
	extract_libvorbis
	configure_libvorbis
	build_libvorbis
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBVORBISDIR}"
}

#
# libtheora
#
LIBTHEORAVER="1.1.1"
LIBTHEORAFILE="libtheora-${LIBTHEORAVER}.tar.bz2"
LIBTHEORAURL="http://downloads.xiph.org/releases/theora/${LIBTHEORAFILE}"
LIBTHEORASHA1SUM="8dcaa8e61cd86eb1244467c0b64b9ddac04ae262"
LIBTHEORADIR="libtheora-${LIBTHEORAVER}"
function clean_libtheora {
	clean_source_dir "${LIBTHEORADIR}" "${WINEBUILDPATH}"
}
function get_libtheora {
	get_file "${LIBTHEORAFILE}" "${WINESOURCEPATH}" "${LIBTHEORAURL}"
}
function check_libtheora {
	check_sha1sum "${WINESOURCEPATH}/${LIBTHEORAFILE}" "${LIBTHEORASHA1SUM}"
}
function extract_libtheora {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${LIBTHEORAFILE}" "${WINEBUILDPATH}" "${LIBTHEORADIR}"
}
function configure_libtheora {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --disable-examples" "${WINEBUILDPATH}/${LIBTHEORADIR}"
}
function build_libtheora {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBTHEORADIR}"
}
function install_libtheora {
	clean_libtheora
	extract_libtheora
	configure_libtheora
	build_libtheora
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBTHEORADIR}"
}

#
# gstreamer
#
GSTREAMERBASEVER="0.10"
GSTREAMERVER="${GSTREAMERBASEVER}.30"
GSTREAMERFILE="gstreamer-${GSTREAMERVER}.tar.bz2"
GSTREAMERURL="http://gstreamer.freedesktop.org/src/gstreamer/${GSTREAMERFILE}"
GSTREAMERSHA1SUM="23e3698dbefd5cfdfe3b40a8cc004cbc09e01e69"
GSTREAMERDIR="gstreamer-${GSTREAMERVER}"
function clean_gstreamer {
	clean_source_dir "${GSTREAMERDIR}" "${WINEBUILDPATH}"
}
function get_gstreamer {
	get_file "${GSTREAMERFILE}" "${WINESOURCEPATH}" "${GSTREAMERURL}"
}
function check_gstreamer {
	check_sha1sum "${WINESOURCEPATH}/${GSTREAMERFILE}" "${GSTREAMERSHA1SUM}"
}
function extract_gstreamer {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${GSTREAMERFILE}" "${WINEBUILDPATH}" "${GSTREAMERDIR}"
}
function configure_gstreamer {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${GSTREAMERDIR}"
}
function build_gstreamer {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${GSTREAMERDIR}"
}
function install_gstreamer {
	clean_gstreamer
	extract_gstreamer
	configure_gstreamer
	build_gstreamer
	install_package "${MAKE} install" "${WINEBUILDPATH}/${GSTREAMERDIR}"
	pushd . >/dev/null 2>&1
	cd ${WINEINCLUDEPATH} || fail_and_exit "could not change into ${WINEINCLUDEPATH}"
	ln -Ffs gstreamer-${GSTREAMERBASEVER}/gst . || fail_and_exit "could not symlink gstreamer-${GSTREAMERBASEVER}/gst to ${WINEINCLUDEPATH}/gst"
	popd
}

#
# gstpluginsbase
#
GSTPLUGINSBASEVER="0.10.30"
GSTPLUGINSBASEFILE="gst-plugins-base-${GSTPLUGINSBASEVER}.tar.bz2"
GSTPLUGINSBASEURL="http://gstreamer.freedesktop.org/src/gst-plugins-base/${GSTPLUGINSBASEFILE}"
GSTPLUGINSBASESHA1SUM="17170bb23278c87bb3f4b299a3e7eaeed178bd31"
GSTPLUGINSBASEDIR="gst-plugins-base-${GSTPLUGINSBASEVER}"
function clean_gstpluginsbase {
	clean_source_dir "${GSTPLUGINSBASEDIR}" "${WINEBUILDPATH}"
}
function get_gstpluginsbase {
	get_file "${GSTPLUGINSBASEFILE}" "${WINESOURCEPATH}" "${GSTPLUGINSBASEURL}"
}
function check_gstpluginsbase {
	check_sha1sum "${WINESOURCEPATH}/${GSTPLUGINSBASEFILE}" "${GSTPLUGINSBASESHA1SUM}"
}
function extract_gstpluginsbase {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${GSTPLUGINSBASEFILE}" "${WINEBUILDPATH}" "${GSTPLUGINSBASEDIR}"
}
function configure_gstpluginsbase {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --disable-examples --enable-experimental" "${WINEBUILDPATH}/${GSTPLUGINSBASEDIR}"
}
function build_gstpluginsbase {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${GSTPLUGINSBASEDIR}"
}
function install_gstpluginsbase {
	clean_gstpluginsbase
	extract_gstpluginsbase
	configure_gstpluginsbase
	build_gstpluginsbase
	install_package "${MAKE} install" "${WINEBUILDPATH}/${GSTPLUGINSBASEDIR}"
}

# 
# XXX - GStreamer support
#   gst-plugins-good - gst-plugins-base, orc, others?
#   gst-plugins-ugly - gst-plugins-base, orc, others?
#   gst-plugins-bad - gst-plugins-base, orc, others?
#   ffmpeg - reqs?
#   gst-ffmpeg - gst-plugins-base, orc, ffmpeg, others?
#

#
# cabextract
#
CABEXTRACTVER="1.3"
CABEXTRACTFILE="cabextract-${CABEXTRACTVER}.tar.gz"
CABEXTRACTURL="http://www.cabextract.org.uk/${CABEXTRACTFILE}"
CABEXTRACTSHA1SUM="112469b9e58497a5cfa2ecb3d9eeb9d3a4151c9f"
CABEXTRACTDIR="cabextract-${CABEXTRACTVER}"
function clean_cabextract {
	clean_source_dir "${CABEXTRACTDIR}" "${WINEBUILDPATH}"
}
function get_cabextract {
	# XXX - cURL downloads broken :\
	export PRECURLOPTS=${CURLOPTS}
	export CURLOPTS="${CURLOPTS} -A 'Mozilla/5.0'"
	get_file "${CABEXTRACTFILE}" "${WINESOURCEPATH}" "${CABEXTRACTURL}"
	export CURLOPTS=${PRECURLOPTS}
}
function check_cabextract {
	check_sha1sum "${WINESOURCEPATH}/${CABEXTRACTFILE}" "${CABEXTRACTSHA1SUM}"
}
function extract_cabextract {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${CABEXTRACTFILE}" "${WINEBUILDPATH}" "${CABEXTRACTDIR}"
}
function configure_cabextract {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX}" "${WINEBUILDPATH}/${CABEXTRACTDIR}"
}
function build_cabextract {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${CABEXTRACTDIR}"
}
function install_cabextract {
	clean_cabextract
	extract_cabextract
	configure_cabextract
	build_cabextract
	install_package "${MAKE} install" "${WINEBUILDPATH}/${CABEXTRACTDIR}"
}

#
# git
#
GITVERSION="1.7.3.2"
GITFILE="git-${GITVERSION}.tar.bz2"
GITURL="http://kernel.org/pub/software/scm/git/${GITFILE}"
GITSHA1SUM="cd8d806752aa6f5716cf193585024a002e098bf4"
GITDIR="git-${GITVERSION}"
function clean_git {
	clean_source_dir "${GITDIR}" "${WINEBUILDPATH}"
}
function get_git {
	get_file "${GITFILE}" "${WINESOURCEPATH}" "${GITURL}"
}
function check_git {
	check_sha1sum "${WINESOURCEPATH}/${GITFILE}" "${GITSHA1SUM}"
}
function extract_git {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${GITFILE}" "${WINEBUILDPATH}" "${GITDIR}"
}
function configure_git {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX}" "${WINEBUILDPATH}/${GITDIR}"
}
function build_git {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${GITDIR}"
}
function install_git {
	clean_git
	extract_git
	configure_git
	build_git
	install_package "${MAKE} install" "${WINEBUILDPATH}/${GITDIR}"
}

#
# gecko
#
GECKOFILE="wine_gecko-${GECKOVERSION}-x86.cab"
GECKOURL="http://downloads.sourceforge.net/wine/${GECKOFILE}"
function get_gecko {
	get_file "${GECKOFILE}" "${WINESOURCEPATH}" "${GECKOURL}"
}
function check_gecko {
	check_sha1sum "${WINESOURCEPATH}/${GECKOFILE}" "${GECKOSHA1SUM}"
}
function install_gecko {
	if [ ! -d  "${WINEINSTALLPATH}/share/wine/gecko" ] ; then
		mkdir -p ${WINEINSTALLPATH}/share/wine/gecko || fail_and_exit "could not create directory for Gecko installation"
	fi
	echo "installing ${GECKOFILE} into ${WINEINSTALLPATH}/share/wine/gecko"
	install -m 644 ${WINESOURCEPATH}/${GECKOFILE} ${WINEINSTALLPATH}/share/wine/gecko/${GECKOFILE} || fail_and_exit "could not put the Wine Gecko cab in the proper location"
}

#
# winetricks
#
# always get latest version, install as exectuable
WINETRICKSFILE="winetricks"
WINETRICKSURL="http://www.kegel.com/wine/${WINETRICKSFILE}"
function get_winetricks {
	# always get winetricks
	pushd . >/dev/null 2>&1
	cd ${WINESOURCEPATH} || fail_and_exit "could not cd to the Wine source repo path"
	echo "downloading ${WINETRICKSURL} to ${WINESOURCEPATH}/${WINETRICKSFILE}"
	${CURL} ${CURLOPTS} -o ${WINETRICKSFILE}.${TIMESTAMP} ${WINETRICKSURL}
	if [ $? == 0 ] ; then
		if [ -f ${WINETRICKSFILE} ] ; then
			mv ${WINETRICKSFILE} ${WINETRICKSFILE}.PRE-${TIMESTAMP}
		fi
		mv ${WINETRICKSFILE}.${TIMESTAMP} ${WINETRICKSFILE}
	fi
	popd >/dev/null 2>&1
}
function install_winetricks {
	if [ -f "${WINESOURCEPATH}/${WINETRICKSFILE}" ] ; then
		echo "installing ${WINETRICKSFILE} into ${WINEBINPATH}"
		install -m 755 ${WINESOURCEPATH}/${WINETRICKSFILE} ${WINEBINPATH}/${WINETRICKSFILE} || echo "could not install install winetricks to ${WINEBINPATH}/${WINETRICKSFILE} - not fatal, install manually"
	fi
}

#
# wisotool
#
# always get latest version, install as exectuable
WISOTOOLFILE="wisotool"
WISOTOOLURL="http://winezeug.googlecode.com/svn/trunk/${WISOTOOLFILE}"
function get_wisotool {
	# always get wisotool
	pushd . >/dev/null 2>&1
	cd ${WINESOURCEPATH} || fail_and_exit "could not cd to the Wine source repo path"
	echo "downloading ${WISOTOOLURL} to ${WINESOURCEPATH}/${WISOTOOLFILE}"
	${CURL} ${CURLOPTS} -o ${WISOTOOLFILE}.${TIMESTAMP} ${WISOTOOLURL}
	if [ $? == 0 ] ; then
		if [ -f ${WISOTOOLFILE} ] ; then
			mv ${WISOTOOLFILE} ${WISOTOOLFILE}.PRE-${TIMESTAMP}
		fi
		mv ${WISOTOOLFILE}.${TIMESTAMP} ${WISOTOOLFILE}
	fi
	popd >/dev/null 2>&1
}
function install_wisotool {
	if [ -f "${WINESOURCEPATH}/${WISOTOOLFILE}" ] ; then
		echo "installing ${WISOTOOLFILE} into ${WINEBINPATH}"
		install -m 755 ${WINESOURCEPATH}/${WISOTOOLFILE} ${WINEBINPATH}/${WISOTOOLFILE} || echo "could not install install wisotool to ${WINEBINPATH}/${WISOTOOLFILE} - not fatal, install manually"
	fi
}

#
# build wine, finally
#
function clean_wine {
	clean_source_dir "${WINEDIR}" "${WINEBUILDPATH}"
}
function get_wine {
	get_file "${WINEFILE}" "${WINESOURCEPATH}" "${WINEURL}"
}
function check_wine {
	check_sha1sum "${WINESOURCEPATH}/${WINEFILE}" "${WINESHA1SUM}"
}
function extract_wine {
	if [ ${BUILDSTABLE} -eq 1 ] || [ ${BUILDDEVEL} -eq 1 ] ; then
		extract_file "${TARBZ2}" "${WINESOURCEPATH}/${WINEFILE}" "${WINEBUILDPATH}" "${WINEDIR}"
	elif [ ${BUILDCROSSOVER} -eq 1 ] || [ ${BUILDCXGAMES} -eq 1 ] ; then
		extract_file "${TARGZ}" "${WINESOURCEPATH}/${WINEFILE}" "${WINEBUILDPATH}" "${WINEDIR}"
		# kill the extra source directories
		for CXGAMESEXTRADIR in cxgui freetype loki samba ; do
			if [ -d ${WINEBUILDPATH}/${CXGAMESEXTRADIR} ] ; then
				pushd . >/dev/null 2>&1
				cd ${WINEBUILDPATH}
				rm -rf ${CXGAMESEXTRADIR} || fail_and_exit "could not remove ${WINETAG} extra directory ${WINEBUILDPATH}/${CXGAMESEXTRADIR}"
				popd >/dev/null 2>&1
			fi
		done
	fi
}
function configure_wine {
	EXTRAXMLOPTS=""
	if [ ${BUILDCROSSOVER} -eq 1 ] || [ ${BUILDCXGAMES} -eq 1 ] ; then
		EXTRAXMLOPTS="=native"
	fi
	WINECONFIGUREOPTS=""
	WINECONFIGUREOPTS+="--verbose "
	WINECONFIGUREOPTS+="--${WIN16FLAG}-win16 "
	WINECONFIGUREOPTS+="--disable-win64 "
	WINECONFIGUREOPTS+="--without-capi "
	WINECONFIGUREOPTS+="--without-hal "
	WINECONFIGUREOPTS+="--without-v4l "
	WINECONFIGUREOPTS+="--with-cms "
	WINECONFIGUREOPTS+="--with-coreaudio "
	WINECONFIGUREOPTS+="--with-cups "
	WINECONFIGUREOPTS+="--with-curses "
	WINECONFIGUREOPTS+="--with-fontconfig "
	WINECONFIGUREOPTS+="--with-freetype "
	WINECONFIGUREOPTS+="--with-glu "
	WINECONFIGUREOPTS+="--with-gnutls "
	WINECONFIGUREOPTS+="--with-gphoto "
	WINECONFIGUREOPTS+="--with-gsm "
	WINECONFIGUREOPTS+="--with-jpeg "
	WINECONFIGUREOPTS+="--with-ldap "
	WINECONFIGUREOPTS+="--with-mpg123 "
	WINECONFIGUREOPTS+="--with-openal "
	WINECONFIGUREOPTS+="--with-opengl "
	WINECONFIGUREOPTS+="--with-openssl "
	WINECONFIGUREOPTS+="--with-png "
	WINECONFIGUREOPTS+="--with-pthread "
	WINECONFIGUREOPTS+="--with-sane "
	WINECONFIGUREOPTS+="--with-xml${EXTRAXMLOPTS+${EXTRAXMLOPTS}} "
	WINECONFIGUREOPTS+="--with-xslt "
	WINECONFIGUREOPTS+="--with-x "
	WINECONFIGUREOPTS+="--x-includes=${X11INC} "
	WINECONFIGUREOPTS+="--x-libraries=${X11LIB} "
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${WINECONFIGUREOPTS}" "${WINEBUILDPATH}/${WINEDIR}"
}
function depend_wine {
	build_package "${MAKE} depend" "${WINEBUILDPATH}/${WINEDIR}"
}
function build_wine {
	# CrossOver has some issues building with concurrent make processes for some reason
	if [ ${BUILDSTABLE} -eq 1 ] || [ ${BUILDDEVEL} -eq 1 ] ; then
		build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${WINEDIR}"
	elif [ ${BUILDCROSSOVER} -eq 1 ] || [ ${BUILDCXGAMES} -eq 1 ] ; then
		build_package "${MAKE}" "${WINEBUILDPATH}/${WINEDIR}"
	fi
}
function install_wine {
	clean_wine
	extract_wine
	configure_wine
	#depend_wine
	build_wine
	install_package "${MAKE} install" "${WINEBUILDPATH}/${WINEDIR}"
	if [ ${BUILDCROSSOVER} -eq 1 ] || [ ${BUILDCXGAMES} -eq 1 ] ; then
		ln -Ffs wineloader ${WINEINSTALLPATH}/bin/wine
	fi
}

#
# get_sources
#   fetches all source packages
#
function get_sources {
	get_pkgconfig
	get_gettext
	get_jpeg
	get_jbigkit
	get_tiff
	get_libpng12
	get_libpng14
	get_libxml2
	get_libxslt
	get_glib
	get_mpg123
	get_gsm
	get_freetype
	get_fontconfig
	get_lcms
	get_lzo
	get_libgpgerror
	get_libgcrypt
	get_gnutls
	get_unixodbc
	get_libexif
	get_libusb
	get_libusbcompat
	get_gd
	get_libgphoto2
	get_sanebackends
	get_jasper
	get_libicns
	get_orc
	get_libogg
	get_libvorbis
	get_libtheora
	get_gstreamer
	get_gstpluginsbase
	get_cabextract
	get_git
	get_gecko
	get_winetricks
	get_wisotool
	get_wine
}

#
# check_sources
#   checks all source SHA-1 sums
#
function check_sources {
	check_pkgconfig
	check_gettext
	check_jpeg
	check_jbigkit
	check_tiff
	check_libpng12
	check_libpng14
	check_libxml2
	check_libxslt
	check_glib
	check_mpg123
	check_gsm
	check_freetype
	check_fontconfig
	check_lcms
	check_lzo
	check_libgpgerror
	check_libgcrypt
	check_gnutls
	check_unixodbc
	check_libexif
	check_libusb
	check_libusbcompat
	check_gd
	check_libgphoto2
	check_sanebackends
	check_jasper
	check_libicns
	check_orc
	check_libogg
	check_libvorbis
	check_libtheora
	check_gstreamer
	check_gstpluginsbase
	check_cabextract
	check_git
	check_gecko
	check_wine
}

#
# install prereqs
#   extracts, builds and installs prereqs
#
function install_prereqs {
	install_pkgconfig
	install_gettext
	install_jpeg
	install_jbigkit
	install_tiff
	install_libpng12
	#install_libpng14
	install_libxml2
	install_libxslt
	install_glib
	install_mpg123
	install_gsm
	install_freetype
	install_fontconfig
	install_lcms
	install_lzo
	install_libgpgerror
	install_libgcrypt
	install_gnutls
	install_libexif
	install_libusb
	install_libusbcompat
	install_gd
	install_libgphoto2
	install_sanebackends
	install_jasper
	install_libicns
	install_orc
	install_libogg
	install_libvorbis
	install_libtheora
	install_gstreamer
	install_gstpluginsbase
	install_unixodbc
	install_cabextract
	install_git
	install_winetricks
	install_wisotool
	install_gecko
}

#
# build_complete
#   print out a nice informational message when done
#
function build_complete {
	cat << EOF

Successfully built and installed ${WINETAG}!

The installation base directory is:

  ${WINEINSTALLPATH}

You can set the following environment variables to use the new Wine install:

  export DYLD_FALLBACK_LIBRARY_PATH="${WINELIBPATH}:${X11LIB}:/usr/lib"
  export PATH="${WINEBINPATH}:\${PATH}"

Please see http://osxwinebuilder.googlecode.com for more information.
If you notice any bugs, please file an issue and leave a comment.

EOF
}

#
# now that our helper functions are done, run through the actual install
#

# move the install dir out of the way if it exists
if [ ${NOCLEANPREFIX} -eq 1 ] ; then
	echo "--no-clean-prefix set, not moving existing prefix aside"
else 
	if [ -d ${WINEINSTALLPATH} ] ; then
		echo "moving existing prefix ${WINEINSTALLPATH} to ${WINEINSTALLPATH}.PRE-${TIMESTAMP}"
		mv ${WINEINSTALLPATH}{,.PRE-${TIMESTAMP}}
	fi
fi

# check compiler before anything else
compiler_check

# get all the sources we'll be using
get_sources

# check source SHA-1 sums
check_sources

# install requirements
install_prereqs

# install wine, for real, really really real
install_wine

# we're done
build_complete

# exit nicely
exit 0