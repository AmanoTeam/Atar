#!/bin/bash

set -eu

declare -r workdir="${PWD}"

declare -r revision="$(git rev-parse --short HEAD)"

declare -r toolchain_directory='/tmp/atar'
declare -r share_directory="${toolchain_directory}/usr/local/share/atar"

declare -r gmp_tarball='/tmp/gmp.tar.xz'
declare -r gmp_directory='/tmp/gmp-6.3.0'

declare -r mpfr_tarball='/tmp/mpfr.tar.xz'
declare -r mpfr_directory='/tmp/mpfr-4.2.2'

declare -r mpc_tarball='/tmp/mpc.tar.gz'
declare -r mpc_directory='/tmp/mpc-1.3.1'

declare -r isl_tarball='/tmp/isl.tar.xz'
declare -r isl_directory='/tmp/isl-0.27'

declare -r binutils_tarball='/tmp/binutils.tar.xz'
declare -r binutils_directory='/tmp/binutils-with-gold-2.44'

declare -r zstd_tarball='/tmp/zstd.tar.gz'
declare -r zstd_directory='/tmp/zstd-dev'

declare -r lld_tarball='/tmp/lld.tar.xz'

declare gcc_directory=''

function setup_gcc_source() {
	
	local gcc_version=''
	local gcc_url=''
	local gcc_tarball=''
	local tgt="${1}"
	
	declare -r tgt
	
	if [ "${tgt}" = 'hppa-unknown-openbsd' ] || [ "${tgt}" = 'alpha-unknown-openbsd' ] || [ "${tgt}" = 'x86_64-unknown-openbsd' ] || [ "${tgt}" = 'i386-unknown-openbsd' ]; then
		gcc_version='15'
		gcc_directory='/tmp/gcc-releases-gcc-15'
		gcc_url='https://github.com/gcc-mirror/gcc/archive/refs/heads/releases/gcc-15.tar.gz'
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
		curl \
			--url "${gcc_url}" \
			--retry '30' \
			--retry-all-errors \
			--retry-delay '0' \
			--retry-max-time '0' \
			--location \
			--silent \
			--output "${gcc_tarball}"
		
		tar \
			--directory="$(dirname "${gcc_directory}")" \
			--extract \
			--file="${gcc_tarball}"
	fi
	
	[ -d "${gcc_directory}/build" ] || mkdir "${gcc_directory}/build"
	
	if ! [ -f "${gcc_directory}/patched" ]; then
		if [ "${gcc_version}" = '11' ]; then
			for name in "${workdir}/submodules/openbsd-ports/lang/gcc/11/patches/patch-"*; do
				patch --directory="${gcc_directory}" --strip='0' --input="${name}"
			done
			
			sed --in-place 's/HAVE_IFUNC/(HAVE_IFUNC \&\& !defined(__arm__))/g' "${gcc_directory}/libatomic/libatomic_i.h"
			
			patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/patches/0001-Thats-not-openbsd.patch"
			patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/patches/0001-Add-libversions.patch"
		elif (( gcc_version >= 15 )); then
			patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/patches/0001-Fix-libatomic-build-with-newer-GCC-versions.patch"
			patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/patches/0001-Disable-libfunc-support-for-hppa-unknown-openbsd.patch"
			patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Fix-libgcc-build-on-arm.patch"
			patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Change-the-default-language-version-for-C-compilatio.patch"
			patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Turn-Wimplicit-int-back-into-an-warning.patch"
			patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Turn-Wint-conversion-back-into-an-warning.patch"
			patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Revert-GCC-change-about-turning-Wimplicit-function-d.patch"
		fi
		
		touch "${gcc_directory}/patched"
	fi
	
}

declare -r max_jobs='30'

declare -r pieflags='-fPIE'
declare -r optflags='-w -O2 -Xlinker --allow-multiple-definition'
declare -r linkflags='-Xlinker -s'

declare -ra targets=(
	'x86_64-unknown-openbsd'
	'i386-unknown-openbsd'
	'alpha-unknown-openbsd'
	'arm-unknown-openbsd'
	'hppa-unknown-openbsd'
	'aarch64-unknown-openbsd'
	'powerpc-unknown-openbsd'
	'powerpc64-unknown-openbsd'
	'sparc64-unknown-openbsd'
	'mips64-unknown-openbsd'
	'mips64el-unknown-openbsd'
	'riscv64-unknown-openbsd'
)

declare build_type="${1}"

if [ -z "${build_type}" ]; then
	build_type='native'
fi

declare is_native='0'

if [ "${build_type}" == 'native' ]; then
	is_native='1'
fi

declare CROSS_COMPILE_TRIPLET=''

if ! (( is_native )); then
	source "./submodules/obggcc/toolchains/${build_type}.sh"
fi

declare -r \
	build_type \
	is_native

if ! [ -f "${gmp_tarball}" ]; then
	curl \
		--url 'https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz' \
		--retry '30' \
		--retry-all-errors \
		--retry-delay '0' \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${gmp_tarball}"
	
	tar \
		--directory="$(dirname "${gmp_directory}")" \
		--extract \
		--file="${gmp_tarball}"
fi

if ! [ -f "${mpfr_tarball}" ]; then
	curl \
		--url 'https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.2.tar.xz' \
		--retry '30' \
		--retry-all-errors \
		--retry-delay '0' \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${mpfr_tarball}"
	
	tar \
		--directory="$(dirname "${mpfr_directory}")" \
		--extract \
		--file="${mpfr_tarball}"
fi

if ! [ -f "${mpc_tarball}" ]; then
	curl \
		--url 'https://ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz' \
		--retry '30' \
		--retry-all-errors \
		--retry-delay '0' \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${mpc_tarball}"
	
	tar \
		--directory="$(dirname "${mpc_directory}")" \
		--extract \
		--file="${mpc_tarball}"
fi

if ! [ -f "${isl_tarball}" ]; then
	curl \
		--url 'https://libisl.sourceforge.io/isl-0.27.tar.xz' \
		--retry '30' \
		--retry-all-errors \
		--retry-delay '0' \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${isl_tarball}"
	
	tar \
		--directory="$(dirname "${isl_directory}")" \
		--extract \
		--file="${isl_tarball}"
fi

if ! [ -f "${binutils_tarball}" ]; then
	curl \
		--url 'https://ftp.gnu.org/gnu/binutils/binutils-with-gold-2.44.tar.xz' \
		--retry '30' \
		--retry-all-errors \
		--retry-delay '0' \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${binutils_tarball}"
	
	tar \
		--directory="$(dirname "${binutils_directory}")" \
		--extract \
		--file="${binutils_tarball}"
	
	patch --directory="${binutils_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Revert-gold-Use-char16_t-char32_t-instead-of-uint16_.patch"
	patch --directory="${binutils_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Disable-annoying-linker-warnings.patch"
fi

if ! [ -f "${lld_tarball}" ]; then
	[ -d "${toolchain_directory}" ] || mkdir "${toolchain_directory}"
	
	declare target="${build_type}"
	
	if [ "${target}" = 'native' ]; then
		target='x86_64-unknown-linux-gnu'
	fi
	
	curl \
		--url "https://github.com/AmanoTeam/LLVM-LLD-Builds/releases/latest/download/${target}.tar.xz" \
		--retry '30' \
		--retry-all-errors \
		--retry-delay '0' \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${lld_tarball}"
	
	tar \
		--directory="${toolchain_directory}" \
		--extract \
		--strip='1' \
		--file="${lld_tarball}"
fi

if ! [ -f "${zstd_tarball}" ]; then
	curl \
		--url 'https://github.com/facebook/zstd/archive/refs/heads/dev.tar.gz' \
		--retry '30' \
		--retry-all-errors \
		--retry-delay '0' \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${zstd_tarball}"
	
	tar \
		--directory="$(dirname "${zstd_directory}")" \
		--extract \
		--file="${zstd_tarball}"
fi

[ -d "${gmp_directory}/build" ] || mkdir "${gmp_directory}/build"

cd "${gmp_directory}/build"

../configure \
	--host="${CROSS_COMPILE_TRIPLET}" \
	--prefix="${toolchain_directory}" \
	--enable-shared \
	--enable-static \
	CFLAGS="${optflags}" \
	CXXFLAGS="${optflags}" \
	LDFLAGS="${linkflags}"

make all --silent --jobs
make install

[ -d "${mpfr_directory}/build" ] || mkdir "${mpfr_directory}/build"

cd "${mpfr_directory}/build"

../configure \
	--host="${CROSS_COMPILE_TRIPLET}" \
	--prefix="${toolchain_directory}" \
	--with-gmp="${toolchain_directory}" \
	--enable-shared \
	--enable-static \
	CFLAGS="${optflags}" \
	CXXFLAGS="${optflags}" \
	LDFLAGS="${linkflags}"

make all --silent --jobs
make install

[ -d "${mpc_directory}/build" ] || mkdir "${mpc_directory}/build"

cd "${mpc_directory}/build"

../configure \
	--host="${CROSS_COMPILE_TRIPLET}" \
	--prefix="${toolchain_directory}" \
	--with-gmp="${toolchain_directory}" \
	--enable-shared \
	--enable-static \
	CFLAGS="${optflags}" \
	CXXFLAGS="${optflags}" \
	LDFLAGS="${linkflags}"

make all --silent --jobs
make install

[ -d "${isl_directory}/build" ] || mkdir "${isl_directory}/build"

cd "${isl_directory}/build"
rm --force --recursive ./*

../configure \
	--host="${CROSS_COMPILE_TRIPLET}" \
	--prefix="${toolchain_directory}" \
	--with-gmp-prefix="${toolchain_directory}" \
	--enable-shared \
	--enable-static \
	CFLAGS="${pieflags} ${optflags}" \
	CXXFLAGS="${pieflags} ${optflags}" \
	LDFLAGS="-Xlinker -rpath-link -Xlinker ${toolchain_directory}/lib ${linkflags}"

make all --jobs
make install

[ -d "${zstd_directory}/.build" ] || mkdir "${zstd_directory}/.build"

cd "${zstd_directory}/.build"
rm --force --recursive ./*

cmake \
	-S "${zstd_directory}/build/cmake" \
	-B "${PWD}" \
	-DCMAKE_C_FLAGS="-DZDICT_QSORT=ZDICT_QSORT_MIN ${optflags}" \
	-DCMAKE_INSTALL_PREFIX="${toolchain_directory}" \
	-DBUILD_SHARED_LIBS=ON \
	-DZSTD_BUILD_PROGRAMS=OFF \
	-DZSTD_BUILD_TESTS=OFF \
	-DZSTD_BUILD_STATIC=OFF

cmake --build "${PWD}"
cmake --install "${PWD}" --strip

for triplet in "${targets[@]}"; do
	declare extra_binutils_flags=''
	declare require_lld='0'
	
	if [ "${triplet}" = 'arm-unknown-openbsd' ] || [ "${triplet}" = 'aarch64-unknown-openbsd' ]; then
		require_lld='1'
	fi
	
	if (( require_lld )); then
		extra_binutils_flags+='--disable-ld --disable-gold --disable-lto '
	else
		extra_binutils_flags+='--enable-ld --enable-gold --enable-lto '
	fi
	
	[ -d "${binutils_directory}/build" ] || mkdir "${binutils_directory}/build"
	
	cd "${binutils_directory}/build"
	rm --force --recursive ./*
	
	../configure \
		--host="${CROSS_COMPILE_TRIPLET}" \
		--target="${triplet}" \
		--prefix="${toolchain_directory}" \
		--enable-plugins \
		--disable-gprofng \
		--with-static-standard-libraries \
		--with-sysroot="${toolchain_directory}/${triplet}" \
		--with-zstd="${toolchain_directory}" \
		${extra_binutils_flags} \
		CFLAGS="${optflags} -I${toolchain_directory}/include" \
		CXXFLAGS="${optflags} -I${toolchain_directory}/include" \
		LDFLAGS="${linkflags}"
	
	make all --jobs > /dev/null
	make install
	
	cd "$(mktemp --directory)"
	
	declare sysroot_url="https://github.com/AmanoTeam/openbsd-sysroot/releases/latest/download/${triplet}.tar.xz"
	declare sysroot_file="${PWD}/${triplet}.tar.xz"
	declare sysroot_directory="${PWD}/${triplet}"
	
	curl \
		--url "${sysroot_url}" \
		--retry '30' \
		--retry-all-errors \
		--retry-delay '0' \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${sysroot_file}"
	
	tar \
		--extract \
		--file="${sysroot_file}"
	
	cp --recursive "${sysroot_directory}" "${toolchain_directory}"
	
	rm --force --recursive ./*
	
	cd "${toolchain_directory}/bin"
	
	ln --symbolic './ld.lld' "./${triplet}-ld.lld"
	
	if (( require_lld )); then
		ln --symbolic './ld.lld' "./${triplet}-ld"
	fi
	
	setup_gcc_source "${triplet}"
	
	cd "${gcc_directory}/build"
	
	rm --force --recursive ./*
	
	declare extra_configure_flags=''
	declare have_lto='0'
	declare have_disable_fixincludes='0'
	
	if [ "${triplet}" = 'hppa-unknown-openbsd' ]; then
		extra_configure_flags+='--disable-libstdcxx '
	fi
	
	if [ "${triplet}" = 'hppa-unknown-openbsd' ] || [ "${triplet}" = 'alpha-unknown-openbsd' ] || [ "${triplet}" = 'x86_64-unknown-openbsd' ] || [ "${triplet}" = 'i386-unknown-openbsd' ]; then
		have_disable_fixincludes='1'
	fi
	
	if [ "${triplet}" = 'hppa-unknown-openbsd' ] || [ "${triplet}" = 'alpha-unknown-openbsd' ] || [ "${triplet}" = 'x86_64-unknown-openbsd' ] || [ "${triplet}" = 'i386-unknown-openbsd' ]; then
		have_lto='1'
	fi
	
	if (( have_disable_fixincludes )); then
		extra_configure_flags+='--disable-fixincludes '
	fi
	
	if (( have_lto )); then
		extra_configure_flags+='--enable-lto '
	else
		extra_configure_flags+='--disable-lto '
	fi
	
	export \
		am_cv_func_iconv=no \
		ac_cv_header_magic_h=no \
	
	../configure \
		--host="${CROSS_COMPILE_TRIPLET}" \
		--target="${triplet}" \
		--prefix="${toolchain_directory}" \
		--with-linker-hash-style='gnu' \
		--with-gmp="${toolchain_directory}" \
		--with-mpc="${toolchain_directory}" \
		--with-mpfr="${toolchain_directory}" \
		--with-isl="${toolchain_directory}" \
		--with-zstd="${toolchain_directory}" \
		--with-bugurl='https://github.com/AmanoTeam/Atar/issues' \
		--with-gcc-major-version-only \
		--with-pkgversion="Atar v0.9-${revision}" \
		--with-sysroot="${toolchain_directory}/${triplet}" \
		--with-native-system-header-dir='/include' \
		--with-default-libstdcxx-abi='new' \
		--enable-__cxa_atexit \
		--enable-cet='auto' \
		--enable-checking='release' \
		--enable-gnu-indirect-function \
		--enable-gnu-unique-object \
		--enable-libstdcxx-backtrace \
		--enable-libstdcxx-filesystem-ts \
		--enable-libstdcxx-static-eh-pool \
		--with-libstdcxx-zoneinfo='static' \
		--with-libstdcxx-lock-policy='auto' \
		--enable-shared \
		--enable-threads='posix' \
		--enable-languages='c,c++' \
		--enable-cpp \
		--enable-default-pie \
		--enable-default-ssp \
		--enable-libssp \
		--enable-standard-branch-protection \
		--enable-wchar_t \
		--enable-plugin \
		--enable-libstdcxx-time='yes' \
		--enable-cxx-flags="${linkflags}" \
		--enable-host-pie \
		--enable-host-shared \
		--with-specs="%{!fno-plt:%{!fplt:-fno-plt}}" \
		--without-headers \
		--disable-libsanitizer \
		--disable-bootstrap \
		--disable-libgomp \
		--disable-libmudflap \
		--disable-libstdcxx-pch \
		--disable-multilib \
		--disable-nls \
		--disable-tls \
		--disable-werror \
		${extra_configure_flags} \
		CFLAGS="${optflags}" \
		CXXFLAGS="${optflags}" \
		LDFLAGS="${linkflags}"
	
	declare CFLAGS_FOR_TARGET="${optflags} ${linkflags}"
	declare CXXFLAGS_FOR_TARGET="${optflags} ${linkflags}"
	
	# https://gcc.gnu.org/bugzilla/show_bug.cgi?id=80196#c12
	if ! (( is_native )); then
		CXXFLAGS_FOR_TARGET+=' -nostdinc++'
	fi
	
	LD_LIBRARY_PATH="${toolchain_directory}/lib" PATH="${PATH}:${toolchain_directory}/bin" make \
		CFLAGS_FOR_TARGET="${CFLAGS_FOR_TARGET}" \
		CXXFLAGS_FOR_TARGET="${CXXFLAGS_FOR_TARGET}" \
		all --jobs="${max_jobs}"
	make install
	
	cd "${toolchain_directory}/lib/bfd-plugins"
	
	if ! [ -f './liblto_plugin.so' ]; then
		ln --symbolic "../../libexec/gcc/${triplet}/"*'/liblto_plugin.so' './'
	fi
	
	cd "${toolchain_directory}/${triplet}/bin"
	
	ln --symbolic '../../bin/ld.lld' 'ld.lld'
	
	if (( require_lld )); then
		ln --symbolic '../../bin/ld.lld' 'ld'
	fi
	
	if ! (( have_disable_fixincludes )); then
		rm --recursive "${toolchain_directory}/lib/gcc/${triplet}/"*"/include-fixed"
	fi
	
	patchelf --add-rpath '$ORIGIN/../../../../lib' "${toolchain_directory}/libexec/gcc/${triplet}/"*"/cc1"
	patchelf --add-rpath '$ORIGIN/../../../../lib' "${toolchain_directory}/libexec/gcc/${triplet}/"*"/cc1plus"
	
	if (( have_lto )); then
		patchelf --add-rpath '$ORIGIN/../../../../lib' "${toolchain_directory}/libexec/gcc/${triplet}/"*"/lto1"
	fi
done

mkdir --parent "${share_directory}"

cp --recursive "${workdir}/tools/dev/"* "${share_directory}"
