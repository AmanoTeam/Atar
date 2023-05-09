#!/bin/bash

set -eu

declare -r ATAR_HOME='/tmp/atar-toolchain'

if [ -d "${ATAR_HOME}" ]; then
	PATH+=":${ATAR_HOME}/bin"
	export ATAR_HOME \
		PATH
	return 0
fi

declare -r ATAR_CROSS_TAG="$(jq --raw-output '.tag_name' <<< "$(curl --retry 10 --retry-delay 3 --silent --url 'https://api.github.com/repos/AmanoTeam/Atar/releases/latest')")"
declare -r ATAR_CROSS_TARBALL='/tmp/daiki.tar.xz'
declare -r ATAR_CROSS_URL="https://github.com/AmanoTeam/Atar/releases/download/${ATAR_CROSS_TAG}/x86_64-linux-gnu.tar.xz"

curl --retry 10 --retry-delay 3 --silent --location --url "${ATAR_CROSS_URL}" --output "${ATAR_CROSS_TARBALL}"
tar --directory="$(dirname "${ATAR_CROSS_TARBALL}")" --extract --file="${ATAR_CROSS_TARBALL}"

rm "${ATAR_CROSS_TARBALL}"

mv '/tmp/unknown-unknown-openbsd' "${ATAR_HOME}"

PATH+=":${ATAR_HOME}/bin"

export ATAR_HOME \
	PATH
