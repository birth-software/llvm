#!/usr/bin/env bash

set -eux

BASENAME_ASSERTION=""

source basename.sh

cp $GITHUB_WORKSPACE/$LLVM_BASENAME.7z.zip .
cp $GITHUB_WORKSPACE/$LLVM_BASENAME-assertions.7z.zip .

7z x $LLVM_BASENAME.7z.zip
7z x $LLVM_BASENAME-assertions.7z.zip

7z x $LLVM_BASENAME.7z
7z x $LLVM_BASENAME-assertions.7z

rm $LLVM_BASENAME.7z
rm $LLVM_BASENAME-assertions.7z

cp $LLVM_BASENAME/bin/clang.exe $LLVM_BASENAME/bin/clang-tblgen.exe $LLVM_BASENAME-assertions/bin
cp -r $LLVM_BASENAME/lib/clang $LLVM_BASENAME-assertions/lib
cp -r $LLVM_BASENAME/lib/cmake/clang $LLVM_BASENAME-assertions/lib/cmake

7z a -t7z -m0=lzma2 -mx=9 -mfb=64 -md=64m -ms=on $LLVM_BASENAME.7z $LLVM_BASENAME

echo "LLVM_BASENAME=$LLVM_BASENAME" >> $GITHUB_ENV
