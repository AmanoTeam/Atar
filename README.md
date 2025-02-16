# Atar

A GCC cross-compiler targeting OpenBSD 7.7.

## Differences from the `lang/gcc/11` port

This version uses the patchset from OpenBSD ports (which is currently based on [GCC 11.2](https://github.com/openbsd/ports/tree/master/lang/gcc/11/patches)), plus some extra patches, and is also rebased on top of the latest GCC 15.

I also removed BSD-specific code from the host tools to allow it to be compiled on Linux and other non-BSD platforms.

## Target architectures

All architectures that the `lang/gcc/11` port supports are also supported here, but note that I mostly only tested the `x86_64` architecture.

* `alpha-unknown-openbsd`
* `hppa-unknown-openbsd`
* `i386-unknown-openbsd`
* `x86_64-unknown-openbsd`
* `arm-unknown-openbsd`
* `aarch64-unknown-openbsd`
* `powerpc-unknown-openbsd`
* `powerpc64-unknown-openbsd`
* `sparc64-unknown-openbsd`
* `mips64-unknown-openbsd`
* `mips64el-unknown-openbsd`
* `riscv64-unknown-openbsd`

## Releases

You can obtain releases from the [releases](https://github.com/AmanoTeam/Atar/releases) page.
