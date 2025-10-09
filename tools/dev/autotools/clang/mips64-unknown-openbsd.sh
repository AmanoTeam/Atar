#/bin/bash

kopt="${-}"

set +u
set -e

if [ -z "${ATAR_HOME}" ]; then
	ATAR_HOME="$(realpath "$(( [ -n "${BASH_SOURCE}" ] && dirname "$(realpath "${BASH_SOURCE[0]}")" ) || dirname "$(realpath "${0}")")""/../../../../..")"
fi

set -u

CROSS_COMPILE_SYSTEM='openbsd'
CROSS_COMPILE_ARCHITECTURE='mips64'
CROSS_COMPILE_TRIPLET="${CROSS_COMPILE_ARCHITECTURE}-unknown-${CROSS_COMPILE_SYSTEM}"
CROSS_COMPILE_SYSROOT="${ATAR_HOME}/${CROSS_COMPILE_TRIPLET}"

CC="${ATAR_HOME}/bin/${CROSS_COMPILE_TRIPLET}-clang"
CXX="${ATAR_HOME}/bin/${CROSS_COMPILE_TRIPLET}-clang++"
AR="${ATAR_HOME}/bin/${CROSS_COMPILE_TRIPLET}-ar"
AS="${ATAR_HOME}/bin/${CROSS_COMPILE_TRIPLET}-as"
LD="${ATAR_HOME}/bin/${CROSS_COMPILE_TRIPLET}-ld"
NM="${ATAR_HOME}/bin/${CROSS_COMPILE_TRIPLET}-nm"
RANLIB="${ATAR_HOME}/bin/${CROSS_COMPILE_TRIPLET}-ranlib"
STRIP="${ATAR_HOME}/bin/${CROSS_COMPILE_TRIPLET}-strip"
OBJCOPY="${ATAR_HOME}/bin/${CROSS_COMPILE_TRIPLET}-objcopy"
READELF="${ATAR_HOME}/bin/${CROSS_COMPILE_TRIPLET}-readelf"

export \
	CROSS_COMPILE_TRIPLET \
	CROSS_COMPILE_SYSTEM \
	CROSS_COMPILE_ARCHITECTURE \
	CROSS_COMPILE_SYSROOT \
	CC \
	CXX \
	AR \
	AS \
	LD \
	NM \
	RANLIB \
	STRIP \
	OBJCOPY \
	READELF

[[ "${kopt}" = *e*  ]] || set +e
[[ "${kopt}" = *u*  ]] || set +u
