#!/bin/bash

set -eu

declare -r workdir="${PWD}"

declare -r revision="$(git rev-parse --short HEAD)"

declare -r gmp_tarball='/tmp/gmp.tar.xz'
declare -r gmp_directory='/tmp/gmp-6.3.0'

declare -r mpfr_tarball='/tmp/mpfr.tar.xz'
declare -r mpfr_directory='/tmp/mpfr-4.2.1'

declare -r mpc_tarball='/tmp/mpc.tar.gz'
declare -r mpc_directory='/tmp/mpc-1.3.1'

declare -r binutils_tarball='/tmp/binutils.tar.xz'
declare -r binutils_directory='/tmp/binutils-2.42'

declare -r lld_tarball='/tmp/lld.tar.xz'

declare -r toolchain_directory='/tmp/atar'

declare gcc_directory=''

function setup_gcc_source() {
	
	local gcc_version=''
	local gcc_url=''
	local gcc_tarball=''
	local tgt="${1}"
	
	declare -r tgt
	
	if [ "${tgt}" = 'hppa' ] || [ "${tgt}" = 'alpha' ] || [ "${tgt}" = 'amd64' ] || [ "${tgt}" = 'i386' ]; then
		gcc_version='14'
		gcc_directory='/tmp/gcc-14.1.0'
		gcc_url='https://ftp.gnu.org/gnu/gcc/gcc-14.1.0/gcc-14.1.0.tar.xz'
	else
		gcc_version='11'
		gcc_directory='/tmp/gcc-11.2.0'
		gcc_url='https://ftp.gnu.org/gnu/gcc/gcc-11.2.0/gcc-11.2.0.tar.xz'
	fi
	
	gcc_tarball="/tmp/gcc-${gcc_version}.tar.xz"
	
	declare -r gcc_version
	declare -r gcc_url
	declare -r gcc_tarball
	
	if ! [ -f "${gcc_tarball}" ]; then
		wget --no-verbose "${gcc_url}" --output-document="${gcc_tarball}"
		tar --directory="$(dirname "${gcc_directory}")" --extract --file="${gcc_tarball}"
	fi
	
	[ -d "${gcc_directory}/build" ] || mkdir "${gcc_directory}/build"
	
	if ! [ -f "${gcc_directory}/patched" ]; then
		if [ "${gcc_version}" = '11' ]; then
			for name in "${workdir}/submodules/openbsd-ports/lang/gcc/11/patches/patch-"*; do
				patch --directory="${gcc_directory}" --strip='0' --input="${name}"
			done
			
			patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/patches/0001-Thats-not-openbsd.patch"
			patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/patches/0001-Add-libversions.patch"
		elif (( gcc_version >= 14 )); then
			patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/patches/0001-Fix-libatomic-build-with-newer-GCC-versions.patch"
			patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/patches/0001-Disable-libfunc-support-for-hppa-unknown-openbsd.patch"
		fi
		
		touch "${gcc_directory}/patched"
	fi
	
}

declare optflags='-Os'
declare -r linkflags='-Wl,-s'

declare -r max_jobs="$(($(nproc) * 17))"

declare build_type="${1}"

if [ -z "${build_type}" ]; then
	build_type='native'
fi

declare is_native='0'

if [ "${build_type}" == 'native' ]; then
	is_native='1'
fi

declare OBGGCC_TOOLCHAIN='/tmp/obggcc-toolchain'
declare CROSS_COMPILE_TRIPLET=''

declare cross_compile_flags=''

if ! (( is_native )); then
	source "./submodules/obggcc/toolchains/${build_type}.sh"
	cross_compile_flags+="--host=${CROSS_COMPILE_TRIPLET}"
fi

if ! [ -f "${gmp_tarball}" ]; then
	wget --no-verbose 'https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz' --output-document="${gmp_tarball}"
	tar --directory="$(dirname "${gmp_directory}")" --extract --file="${gmp_tarball}"
fi

if ! [ -f "${mpfr_tarball}" ]; then
	wget --no-verbose 'https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.1.tar.xz' --output-document="${mpfr_tarball}"
	tar --directory="$(dirname "${mpfr_directory}")" --extract --file="${mpfr_tarball}"
fi

if ! [ -f "${mpc_tarball}" ]; then
	wget --no-verbose 'https://ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz' --output-document="${mpc_tarball}"
	tar --directory="$(dirname "${mpc_directory}")" --extract --file="${mpc_tarball}"
fi

if ! [ -f "${binutils_tarball}" ]; then
	wget --no-verbose 'https://ftp.gnu.org/gnu/binutils/binutils-2.42.tar.xz' --output-document="${binutils_tarball}"
	tar --directory="$(dirname "${binutils_directory}")" --extract --file="${binutils_tarball}"
	
	patch --directory="${binutils_directory}" --strip='1' --input="${workdir}/patches/0001-Revert-gold-Use-char16_t-char32_t-instead-of-uint16_.patch"
	patch --directory="${binutils_directory}" --strip='1' --input="${workdir}/patches/0001-Disable-warning-regarding-exec-stack.patch"
fi

if ! [ -f "${lld_tarball}" ]; then
	[ -d "${toolchain_directory}" ] || mkdir "${toolchain_directory}"
	
	declare target="${build_type}"
	
	if [ "${target}" = 'native' ]; then
		target='x86_64-unknown-linux-gnu'
	fi
	
	wget --no-verbose "https://github.com/AmanoTeam/LLVM-LLD-Builds/releases/latest/download/${target}.tar.xz" --output-document="${lld_tarball}"
	tar --directory="${toolchain_directory}" --extract --strip='1' --file="${lld_tarball}"
fi

[ -d "${gmp_directory}/build" ] || mkdir "${gmp_directory}/build"

cd "${gmp_directory}/build"
rm --force --recursive ./*

../configure \
	--prefix="${toolchain_directory}" \
	--enable-shared \
	--enable-static \
	${cross_compile_flags} \
	CFLAGS="${optflags}" \
	CXXFLAGS="${optflags}" \
	LDFLAGS="${linkflags}"

make all --silent --jobs
make install

[ -d "${mpfr_directory}/build" ] || mkdir "${mpfr_directory}/build"

cd "${mpfr_directory}/build"
rm --force --recursive ./*

../configure \
	--prefix="${toolchain_directory}" \
	--with-gmp="${toolchain_directory}" \
	--enable-shared \
	--enable-static \
	${cross_compile_flags} \
	CFLAGS="${optflags}" \
	CXXFLAGS="${optflags}" \
	LDFLAGS="${linkflags}"

make all --silent --jobs
make install

[ -d "${mpc_directory}/build" ] || mkdir "${mpc_directory}/build"

cd "${mpc_directory}/build"
rm --force --recursive ./*

../configure \
	--prefix="${toolchain_directory}" \
	--with-gmp="${toolchain_directory}" \
	--enable-shared \
	--enable-static \
	${cross_compile_flags} \
	CFLAGS="${optflags}" \
	CXXFLAGS="${optflags}" \
	LDFLAGS="${linkflags}"

make all --silent --jobs
make install

sed -i 's/#include <stdint.h>/#include <stdint.h>\n#include <stdio.h>/g' "${toolchain_directory}/include/mpc.h"

[ -d "${binutils_directory}/build" ] || mkdir "${binutils_directory}/build"

declare -r targets=(
	'armv7'
	'amd64'
	'riscv64'
	'arm64'
	'powerpc64'
	'macppc'
	'sparc64'
	'octeon'
	'loongson'
	'hppa'
	'alpha'
	'i386'
)

for target in "${targets[@]}"; do
	case "${target}" in
		armv7)
			declare triplet='arm-unknown-openbsd';;
		arm64)
			declare triplet='aarch64-unknown-openbsd';;
		macppc)
			declare triplet='powerpc-unknown-openbsd';;
		powerpc64)
			declare triplet='powerpc64-unknown-openbsd';;
		sparc64)
			declare triplet='sparc64-unknown-openbsd';;
		octeon)
			declare triplet='mips64-unknown-openbsd';;
		loongson)
			declare triplet='mips64el-unknown-openbsd';;
		riscv64)
			declare triplet='riscv64-unknown-openbsd';;
		amd64)
			declare triplet='x86_64-unknown-openbsd';;
		i386)
			declare triplet='i386-unknown-openbsd';;
		hppa)
			declare triplet='hppa-unknown-openbsd';;
		alpha)
			declare triplet='alpha-unknown-openbsd';;
	esac
	
	wget --no-verbose "https://mirrors.ucr.ac.cr/pub/OpenBSD/7.0/${target}/base70.tgz" --output-document='/tmp/base.tgz'
	wget --no-verbose "https://mirrors.ucr.ac.cr/pub/OpenBSD/7.0/${target}/comp70.tgz" --output-document='/tmp/comp.tgz'
	
	cd "${binutils_directory}/build"
	rm --force --recursive ./*
	
	declare extra_binutils_flags=''
	declare require_lld='0'
	
	if [ "${target}" = 'armv7' ] || [ "${target}" = 'arm64' ]; then
		require_lld='1'
	fi
	
	if (( require_lld )); then
		extra_binutils_flags+='--disable-ld --disable-gold --disable-lto '
	else
		extra_binutils_flags+='--enable-ld --enable-gold --enable-lto '
	fi
	
	../configure \
		--target="${triplet}" \
		--prefix="${toolchain_directory}" \
		--disable-gprofng \
		--with-static-standard-libraries \
		--with-sysroot="${toolchain_directory}/${triplet}" \
		${extra_binutils_flags} \
		${cross_compile_flags} \
		CFLAGS="${optflags}" \
		CXXFLAGS="${optflags}" \
		LDFLAGS="${linkflags}"
	
	make all --jobs > /dev/null
	make install
	
	cd "${toolchain_directory}/bin"
	
	ln --symbolic './ld.lld' "./${triplet}-ld.lld"
	
	if (( require_lld )); then
		ln --symbolic './ld.lld' "./${triplet}-ld"
	fi
	
	tar --directory="${toolchain_directory}/${triplet}" --strip=2 --extract --file='/tmp/base.tgz' './usr/lib' './usr/include'
	tar --directory="${toolchain_directory}/${triplet}" --strip=2 --extract --file='/tmp/comp.tgz' './usr/lib' './usr/include'
	
	cd "${toolchain_directory}/${triplet}/lib"
	
	while read source; do
		IFS='.' read -ra parts <<< "${source}"
		
		declare name="${parts[1]}"
		declare destination="${name#/}.so"
		
		ln --symbolic "${source}" "./${destination}"
	done <<< "$(find '.' -type 'f' -name 'lib*.so.*')"
	
	setup_gcc_source "${target}"
	
	cd "${gcc_directory}/build"
	
	rm --force --recursive ./*
	
	declare extra_configure_flags=''
	declare supports_lto='0'
	
	if [ "${target}" == 'hppa' ]; then
		extra_configure_flags+='--disable-libstdcxx '
	fi
	
	if [ "${target}" == 'hppa' ] || [ "${target}" == 'alpha' ] || [ "${target}" == 'amd64' ] || [ "${target}" == 'i386' ]; then
		supports_lto='1'
	fi
	
	if (( supports_lto )); then
		extra_configure_flags+='--enable-lto '
	else
		extra_configure_flags+='--disable-lto '
	fi
	
	if [ "${target}" = 'armv7' ]; then
		extra_configure_flags+='--disable-libatomic '
	fi
	
	# The compiler for powerpc64 breaks if compiled with -Os
	if [ "${target}" == 'powerpc64' ]; then
		optflags='-O2'
	else
		optflags='-Os'
	fi
	
	../configure \
		--target="${triplet}" \
		--prefix="${toolchain_directory}" \
		--with-linker-hash-style='gnu' \
		--with-gmp="${toolchain_directory}" \
		--with-mpc="${toolchain_directory}" \
		--with-mpfr="${toolchain_directory}" \
		--with-bugurl='https://github.com/AmanoTeam/Atar/issues' \
		--with-gcc-major-version-only \
		--with-pkgversion="Atar v0.4-${revision}" \
		--with-sysroot="${toolchain_directory}/${triplet}" \
		--with-native-system-header-dir='/include' \
		--enable-__cxa_atexit \
		--enable-cet='auto' \
		--enable-checking='release' \
		--enable-gnu-indirect-function \
		--enable-gnu-unique-object \
		--enable-libstdcxx-backtrace \
		--enable-plugin \
		--enable-shared \
		--enable-threads='posix' \
		--enable-languages='c,c++' \
		--without-headers \
		--disable-bootstrap \
		--disable-libgomp \
		--disable-libmudflap \
		--disable-libssp \
		--disable-libstdcxx-pch \
		--disable-multilib \
		--disable-nls \
		--disable-tls \
		--disable-werror \
		--enable-cpp \
		--enable-default-pie \
		--enable-standard-branch-protection \
		--enable-wchar_t \
		${cross_compile_flags} \
		${extra_configure_flags} \
		am_cv_func_iconv=no \
		ac_cv_header_magic_h=no \
		CFLAGS="${optflags}" \
		CXXFLAGS="${optflags}" \
		LDFLAGS="-Wl,-rpath-link,${OBGGCC_TOOLCHAIN}/${CROSS_COMPILE_TRIPLET}/lib ${linkflags}"
	
	declare CFLAGS_FOR_TARGET="${optflags} ${linkflags}"
	declare CXXFLAGS_FOR_TARGET="${optflags} ${linkflags} -nostdinc++ -fpermissive"
	
	LD_LIBRARY_PATH="${toolchain_directory}/lib" PATH="${PATH}:${toolchain_directory}/bin" make \
		CFLAGS_FOR_TARGET="${CFLAGS_FOR_TARGET}" \
		CXXFLAGS_FOR_TARGET="${CXXFLAGS_FOR_TARGET}" \
		all --jobs="${max_jobs}"
	make install
	
	cd "${toolchain_directory}/${triplet}/bin"
	
	for name in *; do
		rm "${name}"
		ln --symbolic "../../bin/${triplet}-${name}" "${name}"
	done
	
	ln --symbolic '../../bin/ld.lld' 'ld.lld'
	
	if (( require_lld )); then
		ln --symbolic '../../bin/ld.lld' 'ld'
	fi
	
	rm --recursive "${toolchain_directory}/share"
	rm --recursive "${toolchain_directory}/lib/gcc/${triplet}/"*"/include-fixed"
	
	patchelf --add-rpath '$ORIGIN/../../../../lib' "${toolchain_directory}/libexec/gcc/${triplet}/"*"/cc1"
	patchelf --add-rpath '$ORIGIN/../../../../lib' "${toolchain_directory}/libexec/gcc/${triplet}/"*"/cc1plus"
	
	if (( supports_lto )); then
		patchelf --add-rpath '$ORIGIN/../../../../lib' "${toolchain_directory}/libexec/gcc/${triplet}/"*"/lto1"
	fi
done
