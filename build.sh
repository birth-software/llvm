#!/usr/bin/env bash

set -eux

ROOT_DIR=$(pwd)
LLVM_SOURCE_BASENAME=llvm_$LLVM_VERSION
LLVM_BASENAME="${LLVM_SOURCE_BASENAME}_$BIRTH_ARCH-$BIRTH_OS-$CMAKE_BUILD_TYPE"
INSTALL_DIRECTORY_PATH=$ROOT_DIR/install/$LLVM_BASENAME
CMAKE_STATIC_LIBRARY_PREFIX=lib
CMAKE_STATIC_LIBRARY_SUFFIX=.a

ZSTD_BUILD_DIR=$ROOT_DIR/build/zstd
mkdir -p $ZSTD_BUILD_DIR
cd $ZSTD_BUILD_DIR
cmake $ROOT_DIR/zstd \
    -G Ninja \
    -DCMAKE_STATIC_LIBRARY_PREFIX=$CMAKE_STATIC_LIBRARY_PREFIX \
    -DCMAKE_STATIC_LIBRARY_SUFFIX=$CMAKE_STATIC_LIBRARY_SUFFIX \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_ASM_COMPILER=clang \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_DIRECTORY_PATH" \
    -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE
cmake --build . --target install
cd $ROOT_DIR

ZLIB_BUILD_DIR=$ROOT_DIR/build/zlib
mkdir -p $ZLIB_BUILD_DIR
cd $ZLIB_BUILD_DIR
cmake $ROOT_DIR/zlib \
    -G Ninja \
    -DCMAKE_STATIC_LIBRARY_PREFIX=$CMAKE_STATIC_LIBRARY_PREFIX \
    -DCMAKE_STATIC_LIBRARY_SUFFIX=$CMAKE_STATIC_LIBRARY_SUFFIX \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_ASM_COMPILER=clang \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_DIRECTORY_PATH" \
    -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE
cmake --build . --target install
cd $ROOT_DIR

case $BIRTH_OS in
    windows) BIRTH_OPTIONAL_TRIPLE_ARG="-DLLVM_HOST_TRIPLE=$BIRTH_ARCH-pc-windows-msvc";;
    *) BIRTH_OPTIONAL_TRIPLE_ARG="";;
esac

if [[ "$BIRTH_ENABLE_CLANG" == "true" ]]; then
    BIRTH_CMAKE_CLANG_ARGS="-DCLANG_BUILD_TOOLS=OFF -DCLANG_BUILD_EXAMPLES=OFF -DCLANG_INCLUDE_DOCS=OFF -DCLANG_INCLUDE_TESTS=OFF -DCLANG_TOOL_CLANG_IMPORT_TEST_BUILD=OFF -DCLANG_TOOL_CLANG_LINKER_WRAPPER_BUILD=OFF -DCLANG_TOOL_C_INDEX_TEST_BUILD=OFF -DCLANG_TOOL_ARCMT_TEST_BUILD=OFF -DCLANG_TOOL_C_ARCMT_TEST_BUILD=OFF -DCLANG_TOOL_LIBCLANG_BUILD=OFF"
    BIRTH_LLVM_ENABLE_PROJECTS_FLAG="-DLLVM_ENABLE_PROJECTS=lld;clang"
    BIRTH_CMAKE_TARGETS="llvm-config llvm-tblgen clang-tblgen clang"
else
    BIRTH_CMAKE_CLANG_ARGS=
    BIRTH_LLVM_ENABLE_PROJECTS_FLAG=-DLLVM_ENABLE_PROJECTS="lld"
    BIRTH_CMAKE_TARGETS="llvm-config llvm-tblgen"
fi

LLVM_BUILD_DIR=$ROOT_DIR/build/$LLVM_BASENAME
mkdir -p $LLVM_BUILD_DIR

LLVM_SOURCE_DIR="$ROOT_DIR/source/$LLVM_SOURCE_BASENAME"
if [ ! -d "$LLVM_SOURCE_DIR" ]; then
    git clone --depth 1 --single-branch --branch llvmorg-$LLVM_VERSION https://github.com/llvm/llvm-project.git $LLVM_SOURCE_DIR
fi

cd $LLVM_BUILD_DIR
cmake $LLVM_SOURCE_DIR/llvm \
    -G Ninja \
    -DCMAKE_STATIC_LIBRARY_PREFIX=$CMAKE_STATIC_LIBRARY_PREFIX \
    -DCMAKE_STATIC_LIBRARY_SUFFIX=$CMAKE_STATIC_LIBRARY_SUFFIX \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_DIRECTORY_PATH" \
    -DCMAKE_PREFIX_PATH="$INSTALL_DIRECTORY_PATH" \
    -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_ASM_COMPILER=clang \
    $BIRTH_OPTIONAL_TRIPLE_ARG \
    $BIRTH_LLVM_ENABLE_PROJECTS_FLAG \
    -DLLVM_TARGETS_TO_BUILD="X86" \
    -DLLVM_PARALLEL_LINK_JOBS=1 \
    -DLLVM_OPTIMIZED_TABLEGEN=ON \
    -DLLVM_ENABLE_BINDINGS=OFF \
    -DLLVM_ENABLE_LIBEDIT=OFF \
    -DLLVM_ENABLE_LIBPFM=OFF \
    -DLLVM_ENABLE_LIBXML2=OFF \
    -DLLVM_ENABLE_OCAMLDOC=OFF \
    -DLLVM_ENABLE_PLUGINS=OFF \
    -DLLVM_ENABLE_Z3_SOLVER=OFF \
    -DLLVM_ENABLE_ZSTD=OFF \
    -DLLVM_BUILD_UTILS=OFF \
    -DLLVM_BUILD_TOOLS=OFF \
    -DLLVM_BUILD_EXAMPLES=OFF \
    -DLLVM_INCLUDE_TOOLS=ON \
    -DLLVM_INCLUDE_UTILS=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_INCLUDE_DOCS=OFF \
    -DLLVM_TOOL_LLVM_LTO2_BUILD=OFF \
    -DLLVM_TOOL_LLVM_LTO_BUILD=OFF \
    -DLLVM_TOOL_LTO_BUILD=OFF \
    -DLLVM_TOOL_REMARKS_SHLIB_BUILD=OFF \
    -DLLD_BUILD_TOOLS=OFF \
    $BIRTH_CMAKE_CLANG_ARGS

cmake --build . --target $BIRTH_CMAKE_TARGETS install
cd $ROOT_DIR

case "$BIRTH_OS" in
    windows) EXE_EXTENSION=".exe";;
    *) EXE_EXTENSION="";;
esac

# Install manually just these couple exes
mkdir -p $INSTALL_DIRECTORY_PATH/bin
cp $LLVM_BUILD_DIR/bin/llvm-config$EXE_EXTENSION $INSTALL_DIRECTORY_PATH/bin
cp $LLVM_BUILD_DIR/bin/llvm-tblgen$EXE_EXTENSION $INSTALL_DIRECTORY_PATH/bin
if [[ "$BIRTH_ENABLE_CLANG" == "true" ]]; then
    cp $LLVM_BUILD_DIR/bin/clang$EXE_EXTENSION $INSTALL_DIRECTORY_PATH/bin
    cp $LLVM_BUILD_DIR/bin/clang-tblgen$EXE_EXTENSION $INSTALL_DIRECTORY_PATH/bin
fi

7z a -t7z -m0=lzma2 -mx=9 -mfb=64 -md=64m -ms=on $LLVM_BASENAME.7z $INSTALL_DIRECTORY_PATH
b2sum $LLVM_BASENAME.7z > "$LLVM_BASENAME.7z.b2sum"
cat "$LLVM_BASENAME.7z.b2sum"
LLVM_ASSET_BASE_PATH="$(pwd)/$LLVM_BASENAME"
case "$BIRTH_OS" in
    windows) LLVM_ASSET_BASE_PATH="$(cygpath -w ${LLVM_ASSET_BASE_PATH})" ;;
    *) ;;
esac

if [[ "$GITHUB_ACTIONS" == "true" ]]; then
    echo "LLVM_ASSET_BASE_PATH=$LLVM_ASSET_BASE_PATH" >> $GITHUB_ENV
    echo "LLVM_BASENAME=$LLVM_BASENAME" >> $GITHUB_ENV
fi
