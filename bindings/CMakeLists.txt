cmake_minimum_required(VERSION 3.15)
include(CMakePrintHelpers)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Debug CACHE STRING "Build type" FORCE)
endif()
# Set C++ standard
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED YES)
project(bb)

include_directories(BEFORE ./include)

find_package(LLVM REQUIRED CONFIG)
find_package(LLD REQUIRED CONFIG)

add_library(lld_bindings STATIC ./src/lld.cpp)

find_library(LLD_COMMON NAMES liblldCommon.dylib lldCommon.lib lldCommon.a liblldCommon.dll.a liblldCommon.a PATHS ${LLVM_LIBRARY_DIRS} NO_DEFAULT_PATH)
find_library(LLD_COFF NAMES liblldCOFF.dylib lldCOFF.lib lldCOFF.a liblldCOFF.dll.a liblldCOFF.a PATHS ${LLVM_LIBRARY_DIRS} NO_DEFAULT_PATH)
find_library(LLD_ELF NAMES liblldELF.dylib lldELF.lib lldELF.a liblldELF.dll.a liblldELF.a PATHS ${LLVM_LIBRARY_DIRS} NO_DEFAULT_PATH)
find_library(LLD_MACHO NAMES liblldMachO.dylib lldMachO.lib lldMachO.a liblldMachO.dll.a liblldMachO.a PATHS ${LLVM_LIBRARY_DIRS} NO_DEFAULT_PATH)
find_library(LLD_MINGW NAMES liblldMinGW.dylib lldMinGW.lib lldMinGW.a liblldMinGW.dll.a liblldMinGW.a PATHS ${LLVM_LIBRARY_DIRS} NO_DEFAULT_PATH)
find_library(LLD_WASM NAMES liblldWasm.dylib lldWasm.lib lldWasm.a liblldWasm.dll.a liblldWasm.a PATHS ${LLVM_LIBRARY_DIRS} NO_DEFAULT_PATH)

target_link_libraries(lld_bindings PUBLIC
    ${LLVM_AVAILABLE_LIBS}
    ${LLD_COMMON}
    ${LLD_COFF}
    ${LLD_ELF}
    ${LLD_MACHO}
    ${LLD_MINGW}
    ${LLD_WASM}
)

# add_compile_options(-Wall -Wextra -pedantic -Wpedantic -Werror -Wno-c99-extensions -Wno-unused-function -Wno-missing-designated-field-initializers -fno-signed-char -fwrapv -fno-strict-aliasing)
# add_compile_definitions(CMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH}")
# add_compile_definitions(BB_CI=${BB_CI})

# add_compile_options(-fsanitize=address)
# add_link_options(-fsanitize=address)
