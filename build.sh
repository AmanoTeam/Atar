#!/bin/bash

set -eu

declare -r workdir="${PWD}"

declare -r revision="$(git rev-parse --short HEAD)"

declare -r toolchain_directory='/tmp/atar'
declare -r share_directory="${toolchain_directory}/usr/local/share/atar"

declare -r environment="LD_LIBRARY_PATH=${toolchain_directory}/lib PATH=${PATH}:${toolchain_directory}/bin"

declare -r gmp_tarball='/tmp/gmp.tar.xz'
declare -r gmp_directory='/tmp/gmp-6.3.0'

declare -r mpfr_tarball='/tmp/mpfr.tar.xz'
declare -r mpfr_directory='/tmp/mpfr-4.2.2'

declare -r mpc_tarball='/tmp/mpc.tar.gz'
declare -r mpc_directory='/tmp/mpc-1.3.1'

declare -r isl_tarball='/tmp/isl.tar.xz'
declare -r isl_directory='/tmp/isl-0.27'

declare -r binutils_tarball='/tmp/binutils.tar.xz'
declare -r binutils_directory='/tmp/binutils'

declare -r gcc_major='16'

declare -r gcc_tarball='/tmp/gcc.tar.xz'
declare -r gcc_directory='/tmp/gcc-master'

declare -r zlib_tarball='/tmp/zlib.tar.gz'
declare -r zlib_directory='/tmp/zlib-develop'

declare -r zstd_tarball='/tmp/zstd.tar.gz'
declare -r zstd_directory='/tmp/zstd-dev'

declare -r lld_tarball='/tmp/lld.tar.xz'

declare -r max_jobs='30'

declare -r pieflags='-fPIE'
declare -r ccflags='-w -O2'
declare -r linkflags='-Xlinker -s'

declare -ra targets=(
	# 'hppa-unknown-openbsd'
	# 'x86_64-unknown-openbsd'
	# 'mips64-unknown-openbsd'
	# 'mips64el-unknown-openbsd'
	# 'riscv64-unknown-openbsd'
	# 'aarch64-unknown-openbsd'
	'arm-unknown-openbsd'
	# 'i386-unknown-openbsd'
	# 'alpha-unknown-openbsd'
	# 'powerpc-unknown-openbsd'
	# 'powerpc64-unknown-openbsd'
	# 'sparc64-unknown-openbsd'
)

declare -r PKG_CONFIG_PATH="${toolchain_directory}/lib/pkgconfig"
declare -r PKG_CONFIG_LIBDIR="${PKG_CONFIG_PATH}"
declare -r PKG_CONFIG_SYSROOT_DIR="${toolchain_directory}"

declare -r pkg_cv_ZSTD_CFLAGS="-I${toolchain_directory}/include"
declare -r pkg_cv_ZSTD_LIBS="-L${toolchain_directory}/lib -lzstd"
declare -r ZSTD_CFLAGS="-I${toolchain_directory}/include"
declare -r ZSTD_LIBS="-L${toolchain_directory}/lib -lzstd"

export \
	PKG_CONFIG_PATH \
	PKG_CONFIG_LIBDIR \
	PKG_CONFIG_SYSROOT_DIR \
	pkg_cv_ZSTD_CFLAGS \
	pkg_cv_ZSTD_LIBS \
	ZSTD_CFLAGS \
	ZSTD_LIBS

declare build_type="${1}"

if [ -z "${build_type}" ]; then
	build_type='native'
fi

declare is_native='0'

if [ "${build_type}" = 'native' ]; then
	is_native='1'
fi

set +u

if [ -z "${CROSS_COMPILE_TRIPLET}" ]; then
	declare CROSS_COMPILE_TRIPLET=''
fi

set -u

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
	
	patch --directory="${gmp_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Remove-hardcoded-RPATH-and-versioned-SONAME-from-libgmp.patch"
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
	
	patch --directory="${mpfr_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Remove-hardcoded-RPATH-and-versioned-SONAME-from-libmpfr.patch"
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
	
	patch --directory="${mpc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Remove-hardcoded-RPATH-and-versioned-SONAME-from-libmpc.patch"
fi

if ! [ -f "${isl_tarball}" ]; then
	curl \
		--url 'https://sourceforge.net/projects/libisl/files/isl-0.27.tar.xz' \
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
	
	patch --directory="${isl_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Remove-hardcoded-RPATH-and-versioned-SONAME-from-libisl.patch"
fi

if ! [ -f "${binutils_tarball}" ]; then
	curl \
		--url 'https://github.com/AmanoTeam/binutils-snapshots/releases/latest/download/binutils.tar.xz' \
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
	
	if [[ "${CROSS_COMPILE_TRIPLET}" = *'-darwin'* ]]; then
		sed \
			--in-place \
			's/$$ORIGIN/@loader_path/g' \
			"${workdir}/submodules/obggcc/patches/0001-Add-relative-RPATHs-to-binutils-host-tools.patch"
	fi
	
	patch --directory="${binutils_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Add-relative-RPATHs-to-binutils-host-tools.patch"
	patch --directory="${binutils_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Don-t-warn-about-local-symbols-within-the-globals.patch"
fi

if ! [ -f "${gcc_tarball}" ]; then
	curl \
		--url 'https://github.com/gcc-mirror/gcc/archive/master.tar.gz' \
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
	
	if [[ "${CROSS_COMPILE_TRIPLET}" = *'-darwin'* ]]; then
		sed \
			--in-place \
			's/$$ORIGIN/@loader_path/g' \
			"${workdir}/submodules/obggcc/patches/0007-Add-relative-RPATHs-to-GCC-host-tools.patch"
	fi
	
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/patches/0001-GCC-16.patch"
	
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Turn-Wimplicit-function-declaration-back-into-an-warning.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0003-Change-the-default-language-version-for-C-compilation-from-std-gnu23-to-std-gnu17.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0004-Turn-Wimplicit-int-back-into-an-warning.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0005-Turn-Wint-conversion-back-into-an-warning.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0006-Turn-Wincompatible-pointer-types-back-into-an-warning.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0007-Add-relative-RPATHs-to-GCC-host-tools.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0009-Fix-missing-stdint.h-include-when-compiling-host-tools-on-OpenBSD.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0011-Revert-configure-Always-add-pre-installed-header-directories-to-search-path.patch"
	
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/pino/patches/0001-Disable-SONAME-versioning-for-all-target-libraries.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/pino/patches/0001-Change-GCC-s-C-standard-library-name-to-libestdc.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/pino/patches/0001-Rename-GCC-s-libgcc-library-to-libegcc.patch"
fi

# Follow Debian's approach to remove hardcoded RPATHs from binaries
# https://wiki.debian.org/RpathIssue
sed \
	--in-place \
	--regexp-extended \
	's/(hardcode_into_libs)=.*$/\1=no/' \
	"${isl_directory}/configure" \
	"${mpc_directory}/configure" \
	"${mpfr_directory}/configure" \
	"${gmp_directory}/configure" \
	"${gcc_directory}/libsanitizer/configure"

# Avoid using absolute hardcoded install_name values on macOS
sed \
	--in-place \
	's|-install_name \\$rpath/\\$soname|-install_name @rpath/\\$soname|g' \
	"${isl_directory}/configure" \
	"${mpc_directory}/configure" \
	"${mpfr_directory}/configure" \
	"${gmp_directory}/configure"

# Fix Autotools mistakenly detecting shared libraries as not supported on OpenBSD
while read file; do
	sed \
		--in-place \
		--regexp-extended \
		's|test -f /usr/libexec/ld.so|true|g' \
		"${file}"
done <<< "$(find '/tmp' -type 'f' -name 'configure')"

# Force GCC and binutils to prefix host tools with the target triplet even in native builds
sed \
	--in-place \
	's/test "$host_noncanonical" = "$target_noncanonical"/false/' \
	"${gcc_directory}/configure" \
	"${binutils_directory}/configure"

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
		--file="${lld_tarball}" \
		'llvm-ld/bin/lld' \
		'llvm-ld/bin/ld.lld'
fi

if ! [ -f "${zlib_tarball}" ]; then
	curl \
		--url 'https://github.com/madler/zlib/archive/refs/heads/develop.tar.gz' \
		--retry '30' \
		--retry-all-errors \
		--retry-delay '0' \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${zlib_tarball}"
	
	tar \
		--directory="$(dirname "${zlib_directory}")" \
		--extract \
		--file="${zlib_tarball}"
	
	patch --directory="${zlib_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Remove-versioned-SONAME-from-libz.patch"
fi

if ! [ -f "${zstd_tarball}" ]; then
	curl \
		--url 'https://github.com/facebook/zstd/archive/refs/heads/dev.tar.gz' \
		--retry '30' \
		--retry-delay '0' \
		--retry-all-errors \
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
	--disable-static \
	CFLAGS="${ccflags}" \
	CXXFLAGS="${ccflags}" \
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
	--disable-static \
	CFLAGS="${ccflags}" \
	CXXFLAGS="${ccflags}" \
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
	--disable-static \
	CFLAGS="${ccflags}" \
	CXXFLAGS="${ccflags}" \
	LDFLAGS="${linkflags}"

make all --silent --jobs
make install

[ -d "${isl_directory}/build" ] || mkdir "${isl_directory}/build"

cd "${isl_directory}/build"
rm --force --recursive ./*

declare isl_ldflags=''

if [[ "${CROSS_COMPILE_TRIPLET}" != *'-darwin'* ]]; then
	isl_ldflags+=" -Xlinker -rpath-link -Xlinker ${toolchain_directory}/lib"
fi

../configure \
	--host="${CROSS_COMPILE_TRIPLET}" \
	--prefix="${toolchain_directory}" \
	--with-gmp-prefix="${toolchain_directory}" \
	--enable-shared \
	--disable-static \
	CFLAGS="${pieflags} ${ccflags}" \
	CXXFLAGS="${pieflags} ${ccflags}" \
	LDFLAGS="${linkflags} ${isl_ldflags}"

make all --jobs
make install

[ -d "${zlib_directory}/build" ] || mkdir "${zlib_directory}/build"

cd "${zlib_directory}/build"
rm --force --recursive ./*

../configure \
	--host="${CROSS_COMPILE_TRIPLET}" \
	--prefix="${toolchain_directory}" \
	CFLAGS="${ccflags}" \
	CXXFLAGS="${ccflags}" \
	LDFLAGS="${linkflags}"

make all --jobs
make install

unlink "${toolchain_directory}/lib/libz.a"

[ -d "${zstd_directory}/.build" ] || mkdir "${zstd_directory}/.build"

cd "${zstd_directory}/.build"
rm --force --recursive ./*

declare cmake_flags=''

if [[ "${CROSS_COMPILE_TRIPLET}" = *'-darwin'* ]]; then
	cmake_flags+=' -DCMAKE_SYSTEM_NAME=Darwin'
fi

cmake \
	-S "${zstd_directory}/build/cmake" \
	-B "${PWD}" \
	${cmake_flags} \
	-DCMAKE_C_FLAGS="-DZDICT_QSORT=ZDICT_QSORT_MIN ${ccflags}" \
	-DCMAKE_INSTALL_PREFIX="${toolchain_directory}" \
	-DBUILD_SHARED_LIBS=ON \
	-DZSTD_BUILD_PROGRAMS=OFF \
	-DZSTD_BUILD_TESTS=OFF \
	-DZSTD_BUILD_STATIC=OFF \
	-DCMAKE_PLATFORM_NO_VERSIONED_SONAME=ON

cmake --build "${PWD}"
cmake --install "${PWD}" --strip

# We prefer symbolic links over hard links.
cp "${workdir}/submodules/obggcc/tools/ln.sh" '/tmp/ln'

export PATH="/tmp:${PATH}"

if [[ "${CROSS_COMPILE_TRIPLET}" == 'arm'*'-android'* ]] || [[ "${CROSS_COMPILE_TRIPLET}" == 'i686-'*'-android'* ]] || [[ "${CROSS_COMPILE_TRIPLET}" == 'mipsel-'*'-android'* ]]; then
	export \
		ac_cv_func_fseeko='no' \
		ac_cv_func_ftello='no'
fi

if [[ "${CROSS_COMPILE_TRIPLET}" == 'armv5'*'-android'* ]]; then
	export PINO_ARM_MODE='true'
fi

if [[ "${CROSS_COMPILE_TRIPLET}" == *'-haiku' ]]; then
	export ac_cv_c_bigendian='no'
fi

declare args=''

if (( is_native )); then
	args+="${environment}"
fi

for triplet in "${targets[@]}"; do
	declare extra_gcc_flags=''
	declare extra_binutils_flags=''
	declare require_lld='0'
	
	declare specs='%{!Qy:-Qn}'
	
	if [ "${triplet}" = 'x86_64-unknown-openbsd' ] || [ "${triplet}" = 'i386-unknown-openbsd' ]; then
		specs+=' %{!fno-plt:%{!fplt:-fno-plt}}'
	fi
	
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
		--disable-gold \
		--enable-ld \
		--enable-lto \
		--enable-separate-code \
		--enable-rosegment \
		--enable-relro \
		--enable-compressed-debug-sections='all' \
		--enable-default-compressed-debug-sections-algorithm='zstd' \
		--disable-gprofng \
		--disable-default-execstack \
		--without-static-standard-libraries \
		--with-sysroot="${toolchain_directory}/${triplet}" \
		--with-zstd="${toolchain_directory}" \
		--with-system-zlib \
		--without-static-standard-libraries \
		${extra_binutils_flags} \
		CFLAGS="-I${toolchain_directory}/include ${ccflags}" \
		CXXFLAGS="-I${toolchain_directory}/include ${ccflags}" \
		LDFLAGS="-L${toolchain_directory}/lib ${linkflags}"
	
	make all --jobs="${max_jobs}"
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
	rm --force "${toolchain_directory}/${triplet}/lib/"*'.a'
	
	env ${args} "${triplet}-strip" "${toolchain_directory}/${triplet}/lib/"*'.so' || true
	
	cd "${toolchain_directory}/bin"
	
	ln --symbolic './ld.lld' "./${triplet}-ld.lld"
	
	if (( require_lld )); then
		ln --symbolic './ld.lld' "./${triplet}-ld"
	fi
	
	if ! (( is_native )); then
		extra_gcc_flags+=" --with-cross-host=${CROSS_COMPILE_TRIPLET}"
		extra_gcc_flags+=" --with-toolexeclibdir=${toolchain_directory}/${triplet}/lib/"
	fi
	
	if [[ "${CROSS_COMPILE_TRIPLET}" != *'-darwin'* ]]; then
		extra_gcc_flags+=' --enable-host-bind-now'
	fi
	
	[ -d "${gcc_directory}/build" ] || mkdir "${gcc_directory}/build"
	
	cd "${gcc_directory}/build"
	
	rm --force --recursive ./*
	
	../configure \
		--host="${CROSS_COMPILE_TRIPLET}" \
		--target="${triplet}" \
		--prefix="${toolchain_directory}" \
		--with-linker-hash-style='both' \
		--with-gmp="${toolchain_directory}" \
		--with-mpc="${toolchain_directory}" \
		--with-mpfr="${toolchain_directory}" \
		--with-isl="${toolchain_directory}" \
		--with-zstd="${toolchain_directory}" \
		--with-system-zlib \
		--with-bugurl='https://github.com/AmanoTeam/Atar/issues' \
		--with-gcc-major-version-only \
		--with-pkgversion="Atar v1.2-${revision}" \
		--with-sysroot="${toolchain_directory}/${triplet}" \
		--with-native-system-header-dir='/include' \
		--with-default-libstdcxx-abi='new' \
		--enable-__cxa_atexit \
		--enable-cet='auto' \
		--enable-checking='release' \
		--enable-gnu-unique-object \
		--enable-libstdcxx-backtrace \
		--enable-libstdcxx-filesystem-ts \
		--enable-libstdcxx-static-eh-pool \
		--with-libstdcxx-zoneinfo='static' \
		--with-libstdcxx-lock-policy='auto' \
		--enable-shared \
		--enable-threads='posix' \
		--enable-languages='c,c++,jit' \
		--enable-default-pie \
		--enable-default-ssp \
		--enable-libssp \
		--enable-standard-branch-protection \
		--enable-plugin \
		--enable-lto \
		--enable-cxx-flags="${linkflags}" \
		--enable-host-pie \
		--enable-host-shared \
		--with-specs="${specs}" \
		--without-headers \
		--with-pic \
		--disable-gnu-indirect-function \
		--disable-c++-tools \
		--disable-libsanitizer \
		--disable-bootstrap \
		--disable-libgomp \
		--disable-libstdcxx-pch \
		--disable-multilib \
		--disable-nls \
		--disable-tls \
		--disable-werror \
		--disable-symvers \
		--without-static-standard-libraries \
		${extra_gcc_flags} \
		CFLAGS="${ccflags}" \
		CXXFLAGS="${ccflags}" \
		LDFLAGS="-L${toolchain_directory}/lib ${linkflags}"
	
	declare CFLAGS_FOR_TARGET="${ccflags} ${linkflags} -fPIC"
	declare CXXFLAGS_FOR_TARGET="${ccflags} ${linkflags} -fPIC"
	
	# https://gcc.gnu.org/bugzilla/show_bug.cgi?id=80196#c12
	if ! (( is_native )); then
		CXXFLAGS_FOR_TARGET+=' -nostdinc++'
	fi
	
	env ${args} make \
		CFLAGS_FOR_TARGET="${CFLAGS_FOR_TARGET}" \
		CXXFLAGS_FOR_TARGET="${CXXFLAGS_FOR_TARGET}" \
		gcc_cv_objdump="${CROSS_COMPILE_TRIPLET}-objdump" \
		all --jobs="${max_jobs}"
	make install
	
	rm "${toolchain_directory}/bin/${triplet}-${triplet}-"* || true
	
	cd "${toolchain_directory}/${triplet}/bin"
	
	ln --symbolic '../../bin/ld.lld' 'ld.lld'
	
	if (( require_lld )); then
		ln --symbolic '../../bin/ld.lld' 'ld'
	fi
	
	mkdir -p "${toolchain_directory}/lib/bfd-plugins" || true
	cd "${toolchain_directory}/lib/bfd-plugins"
	
	if ! [ -f './liblto_plugin.so' ]; then
		ln --symbolic "../../libexec/gcc/${triplet}/"*'/liblto_plugin.so' './'
	fi
	
	cd "${toolchain_directory}/${triplet}/lib64" 2>/dev/null || cd "${toolchain_directory}/${triplet}/lib"
	
	if [[ "$(basename "${PWD}")" = 'lib64' ]]; then
		mv ./* '../lib' || true
		rmdir "${PWD}"
		cd '../lib'
	fi
	
	[ -f './libiberty.a' ] && unlink './libiberty.a'
	
	unlink './libgcc_s.so' && echo 'GROUP ( libgcc_s.so.1 libgcc.a )' > './libgcc_s.so'
	
	if ! (( is_native )); then
		ln --symbolic './libestdc++.so' './libstdc++.so'
		ln --symbolic './libestdc++.a' './libstdc++.a'
		ln --symbolic './libegcc.so' './libgcc_s.so.1'
		ln --symbolic './libgcc_s.so' './libgcc.so'
	fi
	
	if [ "${CROSS_COMPILE_TRIPLET}" = "${triplet}" ]; then
		ln \
			--symbolic \
			--relative \
			"${toolchain_directory}/${triplet}/include/c++" \
			"${toolchain_directory}/include"
	fi
done

# Delete libtool files and other unnecessary files GCC installs
rm --force --recursive "${toolchain_directory}/share"

find \
	"${toolchain_directory}" \
	-name '*.la' -delete -o \
	-name '*.py' -delete -o \
	-name '*.json' -delete

declare cc='gcc'
declare readelf='readelf'

if ! (( is_native )); then
	cc="${CC}"
	readelf="${READELF}"
fi

# Bundle both libstdc++ and libgcc within host tools
if ! (( is_native )) && [[ "${CROSS_COMPILE_TRIPLET}" != *'-darwin'* ]]; then
	[ -d "${toolchain_directory}/lib" ] || mkdir "${toolchain_directory}/lib"
	
	# libstdc++
	declare name=$(realpath $("${cc}" --print-file-name='libstdc++.so'))
	
	# libestdc++
	if ! [ -f "${name}" ]; then
		declare name=$(realpath $("${cc}" --print-file-name='libestdc++.so'))
	fi
	
	declare soname=$("${readelf}" -d "${name}" | grep 'SONAME' | sed --regexp-extended 's/.+\[(.+)\]/\1/g')
	
	cp "${name}" "${toolchain_directory}/lib/${soname}"
	
	# libgcc_s
	declare name=$(realpath $("${cc}" --print-file-name='libgcc_s.so.1'))
	
	# libegcc
	if ! [ -f "${name}" ]; then
		declare name=$(realpath $("${cc}" --print-file-name='libegcc.so'))
	fi
	
	declare soname=$("${readelf}" -d "${name}" | grep 'SONAME' | sed --regexp-extended 's/.+\[(.+)\]/\1/g')
	
	cp "${name}" "${toolchain_directory}/lib/${soname}"
fi

mkdir --parent "${share_directory}"

cp --recursive "${workdir}/tools/dev/"* "${share_directory}"

[ -d "${toolchain_directory}/build" ] || mkdir "${toolchain_directory}/build"

ln \
	--symbolic \
	--relative \
	"${share_directory}/"* \
	"${toolchain_directory}/build"
