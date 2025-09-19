#!/usr/bin/env bash

set -eux

BASENAME_ASSERTION=""

source basename.sh

gh release download v$LLVM_VERSION --pattern "*${BIRTH_ARCH}-${BIRTH_OS}-*"

7z x $LLVM_BASENAME.7z
7z x $LLVM_BASENAME-assertions.7z

rm $LLVM_BASENAME.7z
rm $LLVM_BASENAME-assertions.7z

cp $LLVM_BASENAME/bin/clang.exe $LLVM_BASENAME/bin/clang++.exe $LLVM_BASENAME/bin/clang-tblgen.exe $LLVM_BASENAME-assertions/bin
cp -r $LLVM_BASENAME/lib/clang $LLVM_BASENAME-assertions/lib
cp -r $LLVM_BASENAME/lib/cmake/clang $LLVM_BASENAME-assertions/lib/cmake

7z a -t7z -m0=lzma2 -mx=9 -mfb=64 -md=64m -ms=on $LLVM_BASENAME-assertions.7z $LLVM_BASENAME-assertions

echo "LLVM_BASENAME=$LLVM_BASENAME-assertions" >> $GITHUB_ENV
